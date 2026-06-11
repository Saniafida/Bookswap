-- ═══════════════════════════════════════════════════════════════
-- Swaply — Admin RLS & Data Fixes
-- Run this in Supabase SQL Editor AFTER marketplace_migration.sql
-- ═══════════════════════════════════════════════════════════════

-- ─────────────────────────────────────────────────────────────
-- 1. FIX: Set admin role for the actual admin UID
--    The handle_new_user() trigger hardcodes the correct admin UID 154ed9ca-...
-- ─────────────────────────────────────────────────────────────
UPDATE profiles
SET role = 'admin'
WHERE id = '154ed9ca-c593-4d91-a700-fbea88b14672';

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
      WHEN NEW.id = '154ed9ca-c593-4d91-a700-fbea88b14672' THEN 'admin'::user_role
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
  ) OR auth.uid() = '154ed9ca-c593-4d91-a700-fbea88b14672'::uuid;
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

-- ─────────────────────────────────────────────────────────────
-- 6. FIX: Add missing UPDATE policies for chats & messages
--    Without these, markAsRead() silently fails (RLS blocks UPDATE)
-- ─────────────────────────────────────────────────────────────
DROP POLICY IF EXISTS "Participants update own chats" ON chats;
CREATE POLICY "Participants update own chats"
  ON chats FOR UPDATE
  USING (auth.uid() = user1_id OR auth.uid() = user2_id OR is_admin());

DROP POLICY IF EXISTS "Participants update messages in own chats" ON messages;
CREATE POLICY "Participants update messages in own chats"
  ON messages FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM chats
      WHERE id = chat_id
        AND (user1_id = auth.uid() OR user2_id = auth.uid())
    ) OR is_admin()
  );
