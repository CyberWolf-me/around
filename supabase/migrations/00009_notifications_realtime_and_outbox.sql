-- ==============================================================================
-- Around Platform: Database Migration 00009 - Device Tokens & Realtime Engagement
-- Sprint 2: Push Notifications & Realtime Infrastructure
-- ==============================================================================

SET search_path TO public, extensions;

-- 1. Device Tokens for Native Push Notifications (FCM / APNs)
CREATE TABLE IF NOT EXISTS public.user_device_tokens (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  fcm_token TEXT NOT NULL,
  platform TEXT NOT NULL CHECK (platform IN ('android', 'ios', 'web')),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT unique_user_device_token UNIQUE (user_id, fcm_token)
);

CREATE INDEX IF NOT EXISTS idx_device_tokens_user ON public.user_device_tokens(user_id);

ALTER TABLE public.user_device_tokens ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "device_tokens_select_own" ON public.user_device_tokens;
CREATE POLICY "device_tokens_select_own"
  ON public.user_device_tokens FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "device_tokens_insert_own" ON public.user_device_tokens;
CREATE POLICY "device_tokens_insert_own"
  ON public.user_device_tokens FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "device_tokens_update_own" ON public.user_device_tokens;
CREATE POLICY "device_tokens_update_own"
  ON public.user_device_tokens FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "device_tokens_delete_own" ON public.user_device_tokens;
CREATE POLICY "device_tokens_delete_own"
  ON public.user_device_tokens FOR DELETE
  TO authenticated
  USING (auth.uid() = user_id);

-- 2. Enable Supabase Realtime on Notifications
DO $$
BEGIN
  ALTER PUBLICATION supabase_realtime ADD TABLE public.notifications;
EXCEPTION WHEN OTHERS THEN
  NULL;
END;
$$;
