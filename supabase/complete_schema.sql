-- ═══════════════════════════════════════════════════════════════
-- BookSwap — Complete Supabase Schema + RLS Policies
-- Run this in Supabase SQL Editor (Dashboard → SQL Editor)
-- Admin UID: 154ed9ca-c593-4d91-a700-fbea88b14672 → role = 'admin'
-- Other users → role = 'user'
-- ═══════════════════════════════════════════════════════════════

-- ─────────────────────────────────────────────────────────────
-- 1. ENUM TYPES
-- ─────────────────────────────────────────────────────────────
DO $$ BEGIN
  CREATE TYPE user_role AS ENUM ('admin', 'user');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE TYPE listing_type AS ENUM ('swap', 'sell', 'both', 'donate');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE TYPE book_condition AS ENUM ('brandNew', 'likeNew', 'good', 'fair', 'poor');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE TYPE report_status AS ENUM ('pending', 'resolved', 'dismissed');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE TYPE report_type AS ENUM ('post', 'user');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- ─────────────────────────────────────────────────────────────
-- 2. PROFILES TABLE (extends auth.users)
-- ─────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS profiles (
  id            UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email         TEXT NOT NULL DEFAULT '',
  full_name     TEXT NOT NULL DEFAULT '',
  avatar_url    TEXT,
  bio           TEXT,
  location      TEXT,
  swap_count    INT NOT NULL DEFAULT 0,
  role          user_role NOT NULL DEFAULT 'user',
  is_banned     BOOLEAN NOT NULL DEFAULT FALSE,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ─────────────────────────────────────────────────────────────
-- TRIGGER: Auto-create profile on signup
-- Admin (UID below) gets role = 'admin', everyone else gets 'user'
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

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- ─────────────────────────────────────────────────────────────
-- 3. CATEGORIES TABLE
-- ─────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS categories (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name       TEXT NOT NULL,
  icon       TEXT,
  color      TEXT,
  is_active  BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Seed default categories
INSERT INTO categories (name, icon, color) VALUES
  ('Fiction',     'auto_awesome',    '#6366F1'),
  ('Non-Fiction', 'psychology_alt',  '#0EA5E9'),
  ('Academic',    'school',          '#059669'),
  ('Sci-Fi',      'rocket_launch',   '#7C3AED'),
  ('Biography',   'person',          '#F59E0B'),
  ('Children',    'child_care',      '#EC4899'),
  ('Mystery',     'search',          '#EF4444'),
  ('History',     'history_edu',     '#78716C'),
  ('Self-Help',   'self_improvement','#10B981'),
  ('Other',       'more_horiz',      '#6B7280')
ON CONFLICT DO NOTHING;

-- ─────────────────────────────────────────────────────────────
-- 4. POSTS TABLE (books)
-- ─────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS posts (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id      UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  title        TEXT NOT NULL,
  author       TEXT NOT NULL,
  description  TEXT,
  image_url    TEXT,
  image_urls   TEXT[] DEFAULT '{}'::TEXT[],
  condition    book_condition NOT NULL DEFAULT 'good',
  listing_type listing_type NOT NULL DEFAULT 'swap',
  price        NUMERIC(10,2),
  category     TEXT,
  location     TEXT,
  is_available BOOLEAN NOT NULL DEFAULT TRUE,
  is_featured  BOOLEAN NOT NULL DEFAULT FALSE,
  is_approved  BOOLEAN NOT NULL DEFAULT TRUE,
  created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ─────────────────────────────────────────────────────────────
-- 5. CHATS & MESSAGES
-- ─────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS chats (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user1_id     UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  user2_id     UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  last_message TEXT,
  last_message_at TIMESTAMPTZ,
  unread_count_1 INTEGER NOT NULL DEFAULT 0,
  unread_count_2 INTEGER NOT NULL DEFAULT 0,
  created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS messages (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  chat_id    UUID NOT NULL REFERENCES chats(id) ON DELETE CASCADE,
  sender_id  UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  text       TEXT NOT NULL,
  is_read    BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Auto-update chat's last_message + unread count when a message is inserted
CREATE OR REPLACE FUNCTION public.update_chat_last_message()
RETURNS TRIGGER
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_user1_id UUID;
  v_user2_id UUID;
BEGIN
  SELECT user1_id, user2_id INTO v_user1_id, v_user2_id
  FROM chats WHERE id = NEW.chat_id;

  UPDATE chats
  SET last_message = NEW.text,
      last_message_at = NEW.created_at,
      unread_count_1 = CASE
        WHEN NEW.sender_id = v_user2_id THEN unread_count_1 + 1
        ELSE unread_count_1
      END,
      unread_count_2 = CASE
        WHEN NEW.sender_id = v_user1_id THEN unread_count_2 + 1
        ELSE unread_count_2
      END
  WHERE id = NEW.chat_id;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_message_inserted ON messages;
CREATE TRIGGER on_message_inserted
  AFTER INSERT ON messages
  FOR EACH ROW EXECUTE FUNCTION public.update_chat_last_message();

-- ─────────────────────────────────────────────────────────────
-- 6. REPORTS TABLE
-- ─────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS reports (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  reporter_id  UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  target_id    UUID NOT NULL,
  target_type  report_type NOT NULL,
  reason       TEXT NOT NULL,
  status       report_status NOT NULL DEFAULT 'pending',
  resolved_by  UUID REFERENCES profiles(id),
  created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  resolved_at  TIMESTAMPTZ
);

-- ─────────────────────────────────────────────────────────────
-- 7. ANNOUNCEMENTS TABLE
-- ─────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS announcements (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title      TEXT NOT NULL,
  body       TEXT NOT NULL,
  is_active  BOOLEAN NOT NULL DEFAULT TRUE,
  priority   INT NOT NULL DEFAULT 0,
  created_by UUID REFERENCES profiles(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ─────────────────────────────────────────────────────────────
-- 8. APP SETTINGS TABLE (key-value store)
-- ─────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS app_settings (
  key        TEXT PRIMARY KEY,
  value      TEXT,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

INSERT INTO app_settings (key, value) VALUES
  ('app_name',            'BookSwap'),
  ('contact_email',       ''),
  ('privacy_policy',      ''),
  ('terms_and_conditions','')
ON CONFLICT (key) DO NOTHING;

-- ═══════════════════════════════════════════════════════════════
-- 9. ROW LEVEL SECURITY (RLS) POLICIES
-- ═══════════════════════════════════════════════════════════════

-- Helper function: checks if current user is admin
CREATE OR REPLACE FUNCTION is_admin()
RETURNS BOOLEAN AS $$
  SELECT EXISTS (
    SELECT 1 FROM profiles
    WHERE id = auth.uid() AND role = 'admin'
  );
$$ LANGUAGE sql SECURITY DEFINER STABLE;

-- ── PROFILES RLS ──────────────────────────────────────────────
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Public read profiles"       ON profiles;
DROP POLICY IF EXISTS "Own insert profile"         ON profiles;
DROP POLICY IF EXISTS "Own update profile"         ON profiles;
DROP POLICY IF EXISTS "Admin all profiles"         ON profiles;

CREATE POLICY "Public read profiles"
  ON profiles FOR SELECT USING (TRUE);

CREATE POLICY "Own insert profile"
  ON profiles FOR INSERT WITH CHECK (auth.uid() = id);

CREATE POLICY "Own update profile"
  ON profiles FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Admin all profiles"
  ON profiles FOR ALL USING (is_admin());

-- ── CATEGORIES RLS ────────────────────────────────────────────
ALTER TABLE categories ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Public read active categories" ON categories;
DROP POLICY IF EXISTS "Admin manage categories"       ON categories;

CREATE POLICY "Public read active categories"
  ON categories FOR SELECT USING (is_active = TRUE OR is_admin());

CREATE POLICY "Admin manage categories"
  ON categories FOR ALL USING (is_admin());

-- ── POSTS RLS ─────────────────────────────────────────────────
ALTER TABLE posts ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Public read posts"   ON posts;
DROP POLICY IF EXISTS "Own insert post"     ON posts;
DROP POLICY IF EXISTS "Own update post"     ON posts;
DROP POLICY IF EXISTS "Own delete post"     ON posts;

CREATE POLICY "Public read posts"
  ON posts FOR SELECT USING (is_available = TRUE OR user_id = auth.uid() OR is_admin());

CREATE POLICY "Own insert post"
  ON posts FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Own update post"
  ON posts FOR UPDATE USING (auth.uid() = user_id OR is_admin());

CREATE POLICY "Own delete post"
  ON posts FOR DELETE USING (auth.uid() = user_id OR is_admin());

-- ── CHATS RLS ─────────────────────────────────────────────────
ALTER TABLE chats ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Participants read chats"   ON chats;
DROP POLICY IF EXISTS "Participants insert chats" ON chats;
DROP POLICY IF EXISTS "Admin all chats"           ON chats;

CREATE POLICY "Participants read chats"
  ON chats FOR SELECT USING (
    auth.uid() = user1_id OR auth.uid() = user2_id OR is_admin()
  );

CREATE POLICY "Participants insert chats"
  ON chats FOR INSERT WITH CHECK (
    auth.uid() = user1_id OR auth.uid() = user2_id
  );

CREATE POLICY "Admin all chats"
  ON chats FOR ALL USING (is_admin());

-- ── MESSAGES RLS ──────────────────────────────────────────────
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Chat members read messages" ON messages;
DROP POLICY IF EXISTS "Own insert messages"        ON messages;
DROP POLICY IF EXISTS "Admin all messages"         ON messages;

CREATE POLICY "Chat members read messages"
  ON messages FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM chats
      WHERE id = chat_id
        AND (user1_id = auth.uid() OR user2_id = auth.uid())
    ) OR is_admin()
  );

CREATE POLICY "Own insert messages"
  ON messages FOR INSERT WITH CHECK (auth.uid() = sender_id);

CREATE POLICY "Admin all messages"
  ON messages FOR ALL USING (is_admin());

-- ── REPORTS RLS ───────────────────────────────────────────────
ALTER TABLE reports ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Own insert report"  ON reports;
DROP POLICY IF EXISTS "Own read reports"   ON reports;
DROP POLICY IF EXISTS "Admin all reports"  ON reports;

CREATE POLICY "Own insert report"
  ON reports FOR INSERT WITH CHECK (auth.uid() = reporter_id);

CREATE POLICY "Own read reports"
  ON reports FOR SELECT USING (auth.uid() = reporter_id OR is_admin());

CREATE POLICY "Admin all reports"
  ON reports FOR ALL USING (is_admin());

-- ── ANNOUNCEMENTS RLS ─────────────────────────────────────────
ALTER TABLE announcements ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Public read announcements"    ON announcements;
DROP POLICY IF EXISTS "Admin manage announcements"   ON announcements;

CREATE POLICY "Public read announcements"
  ON announcements FOR SELECT USING (is_active = TRUE OR is_admin());

CREATE POLICY "Admin manage announcements"
  ON announcements FOR ALL USING (is_admin());

-- ── APP SETTINGS RLS ──────────────────────────────────────────
ALTER TABLE app_settings ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Public read settings"   ON app_settings;
DROP POLICY IF EXISTS "Admin manage settings"  ON app_settings;

CREATE POLICY "Public read settings"
  ON app_settings FOR SELECT USING (TRUE);

CREATE POLICY "Admin manage settings"
  ON app_settings FOR ALL USING (is_admin());

-- ═══════════════════════════════════════════════════════════════
-- 10. STORAGE BUCKETS (for images)
-- ═══════════════════════════════════════════════════════════════

-- Book covers bucket
INSERT INTO storage.buckets (id, name, public)
VALUES ('book_covers', 'book_covers', true)
ON CONFLICT (id) DO NOTHING;

-- Avatars bucket
INSERT INTO storage.buckets (id, name, public)
VALUES ('avatars', 'avatars', true)
ON CONFLICT (id) DO NOTHING;

-- Book covers: public read
DROP POLICY IF EXISTS "Book covers are publicly accessible" ON storage.objects;
CREATE POLICY "Book covers are publicly accessible"
  ON storage.objects FOR SELECT
  USING (bucket_id = 'book_covers');

-- Book covers: authenticated users can upload to their own folder
DROP POLICY IF EXISTS "Users can upload book covers" ON storage.objects;
CREATE POLICY "Users can upload book covers"
  ON storage.objects FOR INSERT
  WITH CHECK (
    bucket_id = 'book_covers'
    AND auth.role() = 'authenticated'
  );

-- Book covers: users can update their own files
DROP POLICY IF EXISTS "Users can update own book covers" ON storage.objects;
CREATE POLICY "Users can update own book covers"
  ON storage.objects FOR UPDATE
  USING (
    bucket_id = 'book_covers'
    AND auth.uid()::text = (storage.foldername(name))[1]
  );

-- Book covers: users can delete their own files
DROP POLICY IF EXISTS "Users can delete own book covers" ON storage.objects;
CREATE POLICY "Users can delete own book covers"
  ON storage.objects FOR DELETE
  USING (
    bucket_id = 'book_covers'
    AND auth.uid()::text = (storage.foldername(name))[1]
  );

-- Avatars: public read
DROP POLICY IF EXISTS "Avatar images are publicly accessible" ON storage.objects;
CREATE POLICY "Avatar images are publicly accessible"
  ON storage.objects FOR SELECT
  USING (bucket_id = 'avatars');

-- Avatars: users can upload own avatar
DROP POLICY IF EXISTS "Users can upload own avatar" ON storage.objects;
CREATE POLICY "Users can upload own avatar"
  ON storage.objects FOR INSERT
  WITH CHECK (
    bucket_id = 'avatars'
    AND auth.uid()::text = (storage.foldername(name))[1]
  );

-- Avatars: users can update own avatar
DROP POLICY IF EXISTS "Users can update own avatar" ON storage.objects;
CREATE POLICY "Users can update own avatar"
  ON storage.objects FOR UPDATE
  USING (
    bucket_id = 'avatars'
    AND auth.uid()::text = (storage.foldername(name))[1]
  );

-- Avatars: users can delete own avatar
DROP POLICY IF EXISTS "Users can delete own avatar" ON storage.objects;
CREATE POLICY "Users can delete own avatar"
  ON storage.objects FOR DELETE
  USING (
    bucket_id = 'avatars'
    AND auth.uid()::text = (storage.foldername(name))[1]
  );

-- ═══════════════════════════════════════════════════════════════
-- 11. REALTIME SUBSCRIPTIONS
-- ═══════════════════════════════════════════════════════════════
ALTER PUBLICATION supabase_realtime ADD TABLE categories;
ALTER PUBLICATION supabase_realtime ADD TABLE announcements;
ALTER PUBLICATION supabase_realtime ADD TABLE app_settings;
ALTER PUBLICATION supabase_realtime ADD TABLE chats;
ALTER PUBLICATION supabase_realtime ADD TABLE messages;
ALTER PUBLICATION supabase_realtime ADD TABLE posts;

-- ═══════════════════════════════════════════════════════════════
-- 12. INDEXES (for performance)
-- ═══════════════════════════════════════════════════════════════
CREATE INDEX IF NOT EXISTS idx_posts_user_id      ON posts(user_id);
CREATE INDEX IF NOT EXISTS idx_posts_category     ON posts(category);
CREATE INDEX IF NOT EXISTS idx_posts_created_at   ON posts(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_messages_chat_id   ON messages(chat_id);
CREATE INDEX IF NOT EXISTS idx_reports_status     ON reports(status);
CREATE INDEX IF NOT EXISTS idx_announcements_active ON announcements(is_active, priority DESC);
