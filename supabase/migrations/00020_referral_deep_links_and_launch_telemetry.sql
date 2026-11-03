-- Migration 00020: Telegram Referral Deep Links & Launch Telemetry
-- Records Mini App launch attribution and awards curator referral XP with mutual-friend RLS privacy.

-- 1. Referral Launches Table
CREATE TABLE IF NOT EXISTS public.referral_launches (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  visitor_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  referrer_handle TEXT NOT NULL CHECK (char_length(trim(referrer_handle)) BETWEEN 2 AND 60),
  target_type TEXT NOT NULL CHECK (target_type IN ('route', 'postcard', 'season', 'crawl', 'referral', 'home')),
  resource_id TEXT CHECK (resource_id IS NULL OR char_length(trim(resource_id)) <= 100),
  xp_awarded INTEGER NOT NULL DEFAULT 0,
  launched_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_referral_launches_visitor ON public.referral_launches(visitor_id);
CREATE INDEX IF NOT EXISTS idx_referral_launches_referrer ON public.referral_launches(referrer_handle);
CREATE INDEX IF NOT EXISTS idx_referral_launches_launched_at ON public.referral_launches(launched_at DESC);

-- 2. Row-Level Security
ALTER TABLE public.referral_launches ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'referral_launches' AND policyname = 'referral_launches_read'
  ) THEN
    CREATE POLICY referral_launches_read ON public.referral_launches
      FOR SELECT USING (
        auth.uid() = visitor_id
        OR EXISTS (
          SELECT 1 FROM public.friendships
          WHERE status = 'accepted'
            AND (
              (user_id = auth.uid() AND friend_id = public.referral_launches.visitor_id)
              OR (user_id = public.referral_launches.visitor_id AND friend_id = auth.uid())
            )
        )
      );
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'referral_launches' AND policyname = 'referral_launches_insert'
  ) THEN
    CREATE POLICY referral_launches_insert ON public.referral_launches
      FOR INSERT WITH CHECK (auth.uid() = visitor_id);
  END IF;
END $$;

-- 3. Idempotent Record Telegram Launch RPC
CREATE OR REPLACE FUNCTION public.record_telegram_launch(
  p_referrer_handle TEXT,
  p_target_type TEXT,
  p_resource_id TEXT DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
  v_uid UUID;
  v_launch_id UUID;
  v_referrer_id UUID;
  v_clean_ref TEXT;
  v_clean_type TEXT;
  v_xp_awarded INTEGER := 0;
BEGIN
  -- Strict caller identity binding (Rule C)
  v_uid := auth.uid();
  IF v_uid IS NULL THEN
    RETURN jsonb_build_object('success', false, 'error', 'Authentication required to record Telegram launch.');
  END IF;

  v_clean_ref := LOWER(trim(COALESCE(p_referrer_handle, '')));
  IF char_length(v_clean_ref) < 2 THEN
    v_clean_ref := 'direct';
  END IF;

  v_clean_type := LOWER(trim(COALESCE(p_target_type, 'home')));
  IF v_clean_type NOT IN ('route', 'postcard', 'season', 'crawl', 'referral', 'home') THEN
    v_clean_type := 'home';
  END IF;

  -- Look up referrer profile to award attribution XP (excluding self-referral)
  IF v_clean_ref <> 'direct' THEN
    SELECT id INTO v_referrer_id
    FROM public.profiles
    WHERE LOWER(username) = v_clean_ref OR LOWER(id::text) = v_clean_ref
    LIMIT 1;

    IF v_referrer_id IS NOT NULL AND v_referrer_id <> v_uid THEN
      v_xp_awarded := 10;
      UPDATE public.profiles
      SET curator_xp = COALESCE(curator_xp, 0) + v_xp_awarded
      WHERE id = v_referrer_id;
    END IF;
  END IF;

  -- Insert launch telemetry record
  INSERT INTO public.referral_launches (
    visitor_id,
    referrer_handle,
    target_type,
    resource_id,
    xp_awarded
  ) VALUES (
    v_uid,
    v_clean_ref,
    v_clean_type,
    NULLIF(trim(p_resource_id), ''),
    v_xp_awarded
  )
  RETURNING id INTO v_launch_id;

  RETURN jsonb_build_object(
    'success', true,
    'launch_id', v_launch_id,
    'visitor_id', v_uid,
    'referrer_handle', v_clean_ref,
    'target_type', v_clean_type,
    'resource_id', p_resource_id,
    'xp_awarded', v_xp_awarded
  );
END;
$$;

-- 4. Permissions
GRANT SELECT, INSERT ON TABLE public.referral_launches TO authenticated;
GRANT EXECUTE ON FUNCTION public.record_telegram_launch(TEXT, TEXT, TEXT) TO authenticated;
