-- ═══════════════════════════════════════════════════════════════
-- Swaply — Marketplace Migration from BookSwap
-- Run this AFTER the base schema (complete_schema.sql / schema.sql)
-- ═══════════════════════════════════════════════════════════════

-- ─────────────────────────────────────────────────────────────
-- 0. GUARD: ensure helper function exists
-- ─────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION is_admin()
RETURNS BOOLEAN AS $$
  SELECT EXISTS (
    SELECT 1 FROM profiles
    WHERE id = auth.uid() AND role = 'admin'
  );
$$ LANGUAGE sql SECURITY DEFINER STABLE;

-- ─────────────────────────────────────────────────────────────
-- 1. RENAME OLD TABLES (preserve data, replaced by new marketplace versions)
-- ─────────────────────────────────────────────────────────────
-- Preserve categories if they exist; just add migration columns
-- DROP TABLE IF EXISTS categories;  -- commented out — causes data loss
ALTER TABLE IF EXISTS reports RENAME TO reports_legacy;

-- ─────────────────────────────────────────────────────────────
-- 2. NEW TABLES
-- ─────────────────────────────────────────────────────────────

-- 2a. CATEGORIES (marketplace)
CREATE TABLE IF NOT EXISTS categories (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name          TEXT NOT NULL,
  slug          TEXT NOT NULL UNIQUE,
  icon          TEXT NOT NULL DEFAULT 'inventory_2',
  description   TEXT,
  is_featured   BOOLEAN NOT NULL DEFAULT FALSE,
  display_order INT NOT NULL DEFAULT 0,
  is_active     BOOLEAN NOT NULL DEFAULT TRUE,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 2b. LISTINGS
CREATE TABLE IF NOT EXISTS listings (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id       UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  category_id   UUID REFERENCES categories(id) ON DELETE SET NULL,
  title         TEXT NOT NULL,
  description   TEXT,
  condition     TEXT DEFAULT 'good',
  listing_type  TEXT NOT NULL CHECK (listing_type IN ('sell', 'exchange', 'donate', 'sell_exchange')),
  price         DECIMAL(10,2),
  is_negotiable BOOLEAN NOT NULL DEFAULT TRUE,
  location      TEXT,
  latitude      DOUBLE PRECISION,
  longitude     DOUBLE PRECISION,
  is_featured   BOOLEAN NOT NULL DEFAULT FALSE,
  is_approved   BOOLEAN NOT NULL DEFAULT TRUE,
  status        TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'inactive', 'sold', 'deleted')),
  view_count    INT NOT NULL DEFAULT 0,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 2c. LISTING IMAGES
CREATE TABLE IF NOT EXISTS listing_images (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  listing_id UUID NOT NULL REFERENCES listings(id) ON DELETE CASCADE,
  url        TEXT NOT NULL,
  sort_order INT NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 2d. FAVORITES
CREATE TABLE IF NOT EXISTS favorites (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id    UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  listing_id UUID NOT NULL REFERENCES listings(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(user_id, listing_id)
);

-- 2e. REPORTS (marketplace version)
CREATE TABLE IF NOT EXISTS reports (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  reporter_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  listing_id  UUID REFERENCES listings(id) ON DELETE CASCADE,
  user_id     UUID REFERENCES profiles(id) ON DELETE CASCADE,
  reason      TEXT NOT NULL,
  description TEXT,
  status      TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'resolved', 'dismissed')),
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT at_least_one_target CHECK (
    listing_id IS NOT NULL OR user_id IS NOT NULL
  )
);

-- ─────────────────────────────────────────────────────────────
-- 3. INDEXES
-- ─────────────────────────────────────────────────────────────
CREATE INDEX IF NOT EXISTS idx_listings_category_id  ON listings(category_id);
CREATE INDEX IF NOT EXISTS idx_listings_user_id      ON listings(user_id);
CREATE INDEX IF NOT EXISTS idx_listings_status       ON listings(status);
CREATE INDEX IF NOT EXISTS idx_listings_listing_type ON listings(listing_type);
CREATE INDEX IF NOT EXISTS idx_listings_created_at   ON listings(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_listing_images_listing ON listing_images(listing_id);
CREATE INDEX IF NOT EXISTS idx_favorites_user_id     ON favorites(user_id);
CREATE INDEX IF NOT EXISTS idx_reports_status        ON reports(status);

-- ─────────────────────────────────────────────────────────────
-- 4. RLS POLICIES
-- ─────────────────────────────────────────────────────────────

-- 4a. CATEGORIES RLS
ALTER TABLE categories ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Everyone can view categories" ON categories;
DROP POLICY IF EXISTS "Only admins can manage categories" ON categories;

CREATE POLICY "Everyone can view categories"
  ON categories FOR SELECT
  USING (TRUE);

CREATE POLICY "Only admins can manage categories"
  ON categories FOR ALL
  USING (is_admin());

-- 4b. LISTINGS RLS
ALTER TABLE listings ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Anyone can view approved active listings" ON listings;
DROP POLICY IF EXISTS "Owners can insert listings" ON listings;
DROP POLICY IF EXISTS "Owners can update own listings" ON listings;
DROP POLICY IF EXISTS "Owners can delete own listings" ON listings;
DROP POLICY IF EXISTS "Admins can do all on listings" ON listings;

CREATE POLICY "Anyone can view approved active listings"
  ON listings FOR SELECT
  USING (
    (status = 'active' AND is_approved = TRUE)
    OR user_id = auth.uid()
    OR is_admin()
  );

CREATE POLICY "Owners can insert listings"
  ON listings FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Owners can update own listings"
  ON listings FOR UPDATE
  USING (auth.uid() = user_id OR is_admin());

CREATE POLICY "Owners can delete own listings"
  ON listings FOR DELETE
  USING (auth.uid() = user_id OR is_admin());

CREATE POLICY "Admins can do all on listings"
  ON listings FOR ALL
  USING (is_admin());

-- 4c. LISTING IMAGES RLS
ALTER TABLE listing_images ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Anyone can view listing images" ON listing_images;
DROP POLICY IF EXISTS "Listing owners can insert images" ON listing_images;
DROP POLICY IF EXISTS "Listing owners can update images" ON listing_images;
DROP POLICY IF EXISTS "Listing owners can delete images" ON listing_images;

CREATE POLICY "Anyone can view listing images"
  ON listing_images FOR SELECT
  USING (TRUE);

CREATE POLICY "Listing owners can insert images"
  ON listing_images FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM listings
      WHERE id = listing_id AND user_id = auth.uid()
    ) OR is_admin()
  );

CREATE POLICY "Listing owners can update images"
  ON listing_images FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM listings
      WHERE id = listing_id AND user_id = auth.uid()
    ) OR is_admin()
  );

CREATE POLICY "Listing owners can delete images"
  ON listing_images FOR DELETE
  USING (
    EXISTS (
      SELECT 1 FROM listings
      WHERE id = listing_id AND user_id = auth.uid()
    ) OR is_admin()
  );

-- 4d. FAVORITES RLS
ALTER TABLE favorites ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view own favorites" ON favorites;
DROP POLICY IF EXISTS "Users can add own favorites" ON favorites;
DROP POLICY IF EXISTS "Users can delete own favorites" ON favorites;

CREATE POLICY "Users can view own favorites"
  ON favorites FOR SELECT
  USING (auth.uid() = user_id OR is_admin());

CREATE POLICY "Users can add own favorites"
  ON favorites FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete own favorites"
  ON favorites FOR DELETE
  USING (auth.uid() = user_id OR is_admin());

-- 4e. REPORTS RLS
ALTER TABLE reports ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Authenticated users can report" ON reports;
DROP POLICY IF EXISTS "Only admins can view reports" ON reports;
DROP POLICY IF EXISTS "Only admins can manage reports" ON reports;

CREATE POLICY "Authenticated users can report"
  ON reports FOR INSERT
  WITH CHECK (auth.uid() = reporter_id AND auth.role() = 'authenticated');

CREATE POLICY "Only admins can view reports"
  ON reports FOR SELECT
  USING (is_admin());

CREATE POLICY "Only admins can manage reports"
  ON reports FOR ALL
  USING (is_admin());

-- ─────────────────────────────────────────────────────────────
-- 5. SEED CATEGORIES (20 marketplace categories)
-- ─────────────────────────────────────────────────────────────
INSERT INTO categories (name, slug, icon, description, is_featured, display_order) VALUES
  ('Books',                'books',                'menu_book',         'Books of all genres and formats',                        TRUE,  1),
  ('Electronics',          'electronics',          'devices',           'Gadgets and electronic devices',                         TRUE,  2),
  ('Mobile Phones',        'mobile-phones',        'phone_android',     'Smartphones, accessories, and parts',                    TRUE,  3),
  ('Laptops',              'laptops',              'laptop',            'Laptops, notebooks, and accessories',                    TRUE,  4),
  ('Clothes',              'clothes',              'checkroom',         'Fashion and apparel for all',                            TRUE,  5),
  ('Shoes',                'shoes',                'shoe',              'Footwear for men, women, and children',                  TRUE,  6),
  ('Bags',                 'bags',                 'backpack',          'Handbags, backpacks, luggage',                           FALSE, 7),
  ('Jewelry',              'jewelry',              'diamond',           'Necklaces, rings, bracelets, and more',                  FALSE, 8),
  ('Furniture',            'furniture',            'chair',             'Tables, chairs, sofas, and home furniture',              FALSE, 9),
  ('Home Decor',           'home-decor',           'deck',              'Decor items, wall art, and accents',                     FALSE, 10),
  ('Kitchen Items',        'kitchen-items',        'countertops',       'Cookware, utensils, and kitchen appliances',             FALSE, 11),
  ('Beauty Products',      'beauty-products',      'face',              'Skincare, makeup, and personal care',                    FALSE, 12),
  ('Gaming',               'gaming',               'sports_esports',    'Video games, consoles, and accessories',                 FALSE, 13),
  ('Sports',               'sports',               'sports_basketball', 'Sports equipment and gear',                              FALSE, 14),
  ('Toys',                 'toys',                 'toys',              'Toys, games, and fun for kids',                          FALSE, 15),
  ('Vehicles Accessories', 'vehicles-accessories', 'directions_car',    'Car accessories, parts, and vehicle gear',               FALSE, 16),
  ('Pets',                 'pets',                 'pets',              'Pet supplies, food, and accessories',                    FALSE, 17),
  ('Stationery',           'stationery',           'edit_note',         'Office supplies, notebooks, and paper goods',            FALSE, 18),
  ('Art Supplies',         'art-supplies',         'palette',           'Paints, brushes, canvas, and creative materials',        FALSE, 19),
  ('Musical Instruments',  'musical-instruments',  'piano',             'Guitars, keyboards, drums, and accessories',             FALSE, 20)
ON CONFLICT (slug) DO NOTHING;

-- ─────────────────────────────────────────────────────────────
-- 6. DATA MIGRATION
-- ─────────────────────────────────────────────────────────────

-- 6a. Migrate posts → listings
INSERT INTO listings (
  id, user_id, category_id, title, description, condition, listing_type,
  price, is_negotiable, location, latitude, longitude,
  is_featured, is_approved, status, view_count, created_at, updated_at
)
SELECT
  p.id,
  p.user_id,
  NULL,    -- category_id: old book categories don't map to marketplace categories
  p.title,
  p.description,
  p.condition::TEXT,
  CASE p.listing_type::TEXT
    WHEN 'swap'   THEN 'exchange'
    WHEN 'sell'   THEN 'sell'
    WHEN 'both'   THEN 'sell_exchange'
    WHEN 'donate' THEN 'donate'
  END,
  p.price,
  TRUE,          -- is_negotiable
  p.location,
  NULL,          -- latitude
  NULL,          -- longitude
  p.is_featured,
  p.is_approved,
  CASE WHEN p.is_available THEN 'active' ELSE 'inactive' END,
  0,             -- view_count
  p.created_at,
  NOW()
FROM posts p
ON CONFLICT (id) DO NOTHING;

-- 6b. Migrate image_urls (single TEXT) → listing_images
INSERT INTO listing_images (listing_id, url, sort_order)
SELECT p.id, p.image_url, 0
FROM posts p
WHERE p.image_url IS NOT NULL
  AND EXISTS (SELECT 1 FROM listings l WHERE l.id = p.id)
ON CONFLICT DO NOTHING;

-- 6c. Migrate image_urls (TEXT[] array) → listing_images
INSERT INTO listing_images (listing_id, url, sort_order)
SELECT DISTINCT ON (p.id, u.url)
  p.id,
  u.url,
  (row_number() OVER (PARTITION BY p.id ORDER BY u.ord))::INT
FROM posts p
CROSS JOIN LATERAL unnest(p.image_urls) WITH ORDINALITY AS u(url, ord)
WHERE p.image_urls IS NOT NULL
  AND array_length(p.image_urls, 1) > 0
  AND EXISTS (SELECT 1 FROM listings l WHERE l.id = p.id)
ON CONFLICT DO NOTHING;

-- 6d. Migrate old reports → new reports (where target_type = 'post')
INSERT INTO reports (reporter_id, listing_id, reason, status, created_at)
SELECT r.reporter_id, r.target_id, r.reason, r.status::TEXT, r.created_at
FROM reports_legacy r
WHERE r.target_type = 'post'
  AND EXISTS (SELECT 1 FROM listings l WHERE l.id = r.target_id)
ON CONFLICT DO NOTHING;

-- 6e. Migrate old reports → new reports (where target_type = 'user')
INSERT INTO reports (reporter_id, user_id, reason, status, created_at)
SELECT r.reporter_id, r.target_id, r.reason, r.status::TEXT, r.created_at
FROM reports_legacy r
WHERE r.target_type = 'user'
ON CONFLICT DO NOTHING;

-- 6f. Clean up legacy reports table
DROP TABLE IF EXISTS reports_legacy;

-- ─────────────────────────────────────────────────────────────
-- 7. TRIGGER: auto-update updated_at on listings
-- ─────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION update_listings_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trigger_listings_updated_at ON listings;
CREATE TRIGGER trigger_listings_updated_at
  BEFORE UPDATE ON listings
  FOR EACH ROW
  EXECUTE FUNCTION update_listings_updated_at();

-- ─────────────────────────────────────────────────────────────
-- 8. REALTIME PUBLICATION
-- ─────────────────────────────────────────────────────────────
ALTER PUBLICATION supabase_realtime ADD TABLE listings;
ALTER PUBLICATION supabase_realtime ADD TABLE listing_images;
ALTER PUBLICATION supabase_realtime ADD TABLE favorites;

-- Remove old categories from realtime (table is being replaced)
-- New categories will be added below if not already present
ALTER PUBLICATION supabase_realtime ADD TABLE categories;

-- ─────────────────────────────────────────────────────────────
-- 9. UPDATE APP SETTINGS FOR SWAPLY
-- ─────────────────────────────────────────────────────────────
INSERT INTO app_settings (key, value) VALUES
  ('app_name', 'Swaply'),
  ('app_version', '2.0.0-marketplace')
ON CONFLICT (key) DO UPDATE SET value = EXCLUDED.value, updated_at = NOW();
