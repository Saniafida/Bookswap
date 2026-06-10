-- ═══════════════════════════════════════════════════════════════
-- Swaply — Admin RLS & Data Fixes
-- Run this in Supabase SQL Editor AFTER marketplace_migration.sql
-- ═══════════════════════════════════════════════════════════════

-- ─────────────────────────────────────────────────────────────
-- 1. FIX: Set admin role for the actual admin UID
--    The handle_new_user() trigger hardcodes 154ed9ca-... but
--    the actual admin UID is 23e1e885-...
-- ─────────────────────────────────────────────────────────────
UPDATE profiles
SET role = 'admin'
WHERE id = '23e1e885-ce66-4740-9c75-404b1a1f6b23';

-- ─────────────────────────────────────────────────────────────
-- 2. FIX: Update trigger so NEW admin users get the right role
-- ─────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, email, full_name, role)
  VALUES (
    NEW.id,
    COALESCE(NEW.email, ''),
    COALESCE(NEW.raw_user_meta_data->>'full_name', ''),
    CASE
      WHEN NEW.id = '23e1e885-ce66-4740-9c75-404b1a1f6b23' THEN 'admin'::user_role
      ELSE 'user'::user_role
    END
  )
  ON CONFLICT (id) DO NOTHING;
  RETURN NEW;
EXCEPTION WHEN OTHERS THEN
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ─────────────────────────────────────────────────────────────
-- 3. FIX: Ensure is_admin() function exists
-- ─────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION is_admin()
RETURNS BOOLEAN AS $$
  SELECT EXISTS (
    SELECT 1 FROM profiles
    WHERE id = auth.uid() AND role = 'admin'
  );
$$ LANGUAGE sql SECURITY DEFINER STABLE;

-- ─────────────────────────────────────────────────────────────
-- 4. FIX: listing_images RLS policies (INSERT, SELECT, UPDATE, DELETE)
-- ─────────────────────────────────────────────────────────────
ALTER TABLE listing_images ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Anyone can view listing images" ON listing_images;
CREATE POLICY "Anyone can view listing images"
  ON listing_images FOR SELECT
  USING (TRUE);

DROP POLICY IF EXISTS "Listing owners can insert images" ON listing_images;
CREATE POLICY "Listing owners can insert images"
  ON listing_images FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM listings
      WHERE id = listing_id AND user_id = auth.uid()
    ) OR is_admin()
  );

DROP POLICY IF EXISTS "Listing owners can update images" ON listing_images;
CREATE POLICY "Listing owners can update images"
  ON listing_images FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM listings
      WHERE id = listing_id AND user_id = auth.uid()
    ) OR is_admin()
  );

DROP POLICY IF EXISTS "Listing owners can delete images" ON listing_images;
CREATE POLICY "Listing owners can delete images"
  ON listing_images FOR DELETE
  USING (
    EXISTS (
      SELECT 1 FROM listings
      WHERE id = listing_id AND user_id = auth.uid()
    ) OR is_admin()
  );

-- ─────────────────────────────────────────────────────────────
-- 5. FIX: Update listings CHECK constraint to accept both
--    'sellExchange' (Flutter legacy) and 'sell_exchange' (DB convention)
-- ─────────────────────────────────────────────────────────────
ALTER TABLE listings DROP CONSTRAINT IF EXISTS listings_listing_type_check;
ALTER TABLE listings ADD CONSTRAINT listings_listing_type_check
  CHECK (listing_type IN ('sell', 'exchange', 'donate', 'sell_exchange', 'sellExchange'));
