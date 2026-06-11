-- ═══════════════════════════════════════════════════════════════
-- Swaply — Complete Notification System
-- Run this AFTER marketplace_migration.sql & fix_admin_and_rls.sql
-- ═══════════════════════════════════════════════════════════════

-- ─────────────────────────────────────────────────────────────
-- 1. NOTIFICATIONS TABLE
-- ─────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS notifications (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id    UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  type       TEXT NOT NULL CHECK (type IN (
    'new_message','new_listing','favorite_update','price_drop',
    'exchange_request','donation_request','listing_approved',
    'listing_removed','admin_announcement','account_action'
  )),
  title      TEXT NOT NULL,
  message    TEXT NOT NULL,
  data       JSONB DEFAULT '{}'::jsonb,
  is_read    BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_notifications_user_id ON notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_unread ON notifications(user_id, is_read);
CREATE INDEX IF NOT EXISTS idx_notifications_created ON notifications(user_id, created_at DESC);

-- ─────────────────────────────────────────────────────────────
-- 2. DEVICE TOKENS TABLE (FCM)
-- ─────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS device_tokens (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id    UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  token      TEXT NOT NULL,
  platform   TEXT NOT NULL DEFAULT 'unknown',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_device_tokens_user ON device_tokens(user_id);
CREATE UNIQUE INDEX IF NOT EXISTS idx_device_tokens_token ON device_tokens(token);

-- ─────────────────────────────────────────────────────────────
-- 3. RLS POLICIES — notifications
-- ─────────────────────────────────────────────────────────────
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users read own notifications" ON notifications;
CREATE POLICY "Users read own notifications"
  ON notifications FOR SELECT
  USING (auth.uid() = user_id OR is_admin());

DROP POLICY IF EXISTS "Users update own notifications" ON notifications;
CREATE POLICY "Users update own notifications"
  ON notifications FOR UPDATE
  USING (auth.uid() = user_id OR is_admin());

DROP POLICY IF EXISTS "Users delete own notifications" ON notifications;
CREATE POLICY "Users delete own notifications"
  ON notifications FOR DELETE
  USING (auth.uid() = user_id OR is_admin());

-- Service role / triggers insert notifications (bypass RLS via SECURITY DEFINER)
DROP POLICY IF EXISTS "System insert notifications" ON notifications;
CREATE POLICY "System insert notifications"
  ON notifications FOR INSERT
  WITH CHECK (TRUE);

-- ─────────────────────────────────────────────────────────────
-- 4. RLS POLICIES — device_tokens
-- ─────────────────────────────────────────────────────────────
ALTER TABLE device_tokens ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users manage own device tokens" ON device_tokens;
CREATE POLICY "Users manage own device tokens"
  ON device_tokens FOR ALL
  USING (auth.uid() = user_id);

-- ─────────────────────────────────────────────────────────────
-- 5. FUNCTION: Create notification + send push
-- ─────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.create_notification(
  p_user_id UUID,
  p_type TEXT,
  p_title TEXT,
  p_message TEXT,
  p_data JSONB DEFAULT '{}'::jsonb
) RETURNS UUID AS $$
DECLARE
  v_notification_id UUID;
BEGIN
  INSERT INTO notifications (user_id, type, title, message, data)
  VALUES (p_user_id, p_type, p_title, p_message, p_data)
  RETURNING id INTO v_notification_id;
  RETURN v_notification_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ─────────────────────────────────────────────────────────────
-- 6. TRIGGER: New message notification
-- ─────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.notify_new_message()
RETURNS TRIGGER AS $$
DECLARE
  v_recipient_id UUID;
  v_sender_name TEXT;
BEGIN
  SELECT
    CASE WHEN c.user1_id = NEW.sender_id THEN c.user2_id ELSE c.user1_id END,
    COALESCE(p.full_name, 'Someone')
  INTO v_recipient_id, v_sender_name
  FROM chats c
  JOIN profiles p ON p.id = NEW.sender_id
  WHERE c.id = NEW.chat_id;

  PERFORM public.create_notification(
    v_recipient_id,
    'new_message',
    'New Message',
    v_sender_name || ' sent you a message.',
    jsonb_build_object('chat_id', NEW.chat_id, 'message_id', NEW.id, 'sender_id', NEW.sender_id)
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_message_inserted_notification ON messages;
CREATE TRIGGER on_message_inserted_notification
  AFTER INSERT ON messages
  FOR EACH ROW EXECUTE FUNCTION public.notify_new_message();

-- ─────────────────────────────────────────────────────────────
-- 7. TRIGGER: Listing approved notification
-- ─────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.notify_listing_approved()
RETURNS TRIGGER AS $$
BEGIN
  IF OLD.is_approved = FALSE AND NEW.is_approved = TRUE THEN
    PERFORM public.create_notification(
      NEW.user_id,
      'listing_approved',
      'Listing Approved',
      'Your listing "' || COALESCE(NEW.title, 'item') || '" has been approved.',
      jsonb_build_object('listing_id', NEW.id)
    );
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_listing_approved ON listings;
CREATE TRIGGER on_listing_approved
  AFTER UPDATE OF is_approved ON listings
  FOR EACH ROW EXECUTE FUNCTION public.notify_listing_approved();

-- ─────────────────────────────────────────────────────────────
-- 8. TRIGGER: Listing removed by admin
-- ─────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.notify_listing_removed()
RETURNS TRIGGER AS $$
BEGIN
  IF OLD.is_approved = TRUE AND NEW.is_approved = FALSE THEN
    PERFORM public.create_notification(
      NEW.user_id,
      'listing_removed',
      'Listing Removed',
      'Your listing "' || COALESCE(NEW.title, 'item') || '" has been removed by admin.',
      jsonb_build_object('listing_id', NEW.id)
    );
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_listing_removed ON listings;
CREATE TRIGGER on_listing_removed
  AFTER UPDATE OF is_approved ON listings
  FOR EACH ROW EXECUTE FUNCTION public.notify_listing_removed();

-- ─────────────────────────────────────────────────────────────
-- 9. TRIGGER: Price drop notification
-- ─────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.notify_price_drop()
RETURNS TRIGGER AS $$
BEGIN
  IF OLD.price IS NOT NULL AND NEW.price IS NOT NULL AND NEW.price < OLD.price THEN
    INSERT INTO notifications (user_id, type, title, message, data)
    SELECT
      f.user_id,
      'price_drop',
      'Price Drop',
      'Price reduced for "' || COALESCE(NEW.title, 'item') || '" — now Rs.' || NEW.price::text,
      jsonb_build_object('listing_id', NEW.id, 'old_price', OLD.price, 'new_price', NEW.price)
    FROM favorites f
    WHERE f.listing_id = NEW.id;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_price_drop ON listings;
CREATE TRIGGER on_price_drop
  AFTER UPDATE OF price ON listings
  FOR EACH ROW EXECUTE FUNCTION public.notify_price_drop();

-- ─────────────────────────────────────────────────────────────
-- 10. TRIGGER: Listing update notification (favorited items)
-- ─────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.notify_listing_update()
RETURNS TRIGGER AS $$
BEGIN
  IF OLD.title IS DISTINCT FROM NEW.title OR OLD.description IS DISTINCT FROM NEW.description THEN
    INSERT INTO notifications (user_id, type, title, message, data)
    SELECT
      f.user_id,
      'favorite_update',
      'Listing Updated',
      'The item "' || COALESCE(NEW.title, 'item') || '" you saved has been updated.',
      jsonb_build_object('listing_id', NEW.id)
    FROM favorites f
    WHERE f.listing_id = NEW.id;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_listing_update ON listings;
CREATE TRIGGER on_listing_update
  AFTER UPDATE OF title, description ON listings
  FOR EACH ROW EXECUTE FUNCTION public.notify_listing_update();

-- ─────────────────────────────────────────────────────────────
-- 11. ENABLE REALTIME
-- ─────────────────────────────────────────────────────────────
ALTER PUBLICATION supabase_realtime ADD TABLE notifications;
