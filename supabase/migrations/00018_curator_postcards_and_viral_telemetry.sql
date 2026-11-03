-- Migration 00018: Curator Visit Postcards & Cultural Receipt Viral Telemetry
-- Records user-generated postcard receipts and awards curator XP with mutual-friend RLS privacy.

-- 1. Postcard Shares Telemetry Table
CREATE TABLE IF NOT EXISTS public.postcard_shares (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  place_id TEXT NOT NULL CHECK (char_length(trim(place_id)) <= 100),
  route_id TEXT CHECK (route_id IS NULL OR char_length(trim(route_id)) <= 100),
  share_channel TEXT NOT NULL DEFAULT 'telegram' CHECK (share_channel IN ('telegram', 'instagram', 'system_sheet', 'copy_link')),
  receipt_number TEXT CHECK (receipt_number IS NULL OR char_length(trim(receipt_number)) <= 50),
  theme TEXT NOT NULL DEFAULT 'paper' CHECK (theme IN ('paper', 'carbon', 'mint')),
  aspect_ratio TEXT NOT NULL DEFAULT '9:16' CHECK (aspect_ratio IN ('1:1', '9:16')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_postcard_shares_user ON public.postcard_shares(user_id);
CREATE INDEX IF NOT EXISTS idx_postcard_shares_place ON public.postcard_shares(place_id);
CREATE INDEX IF NOT EXISTS idx_postcard_shares_created_at ON public.postcard_shares(created_at DESC);

-- 2. Row-Level Security
ALTER TABLE public.postcard_shares ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'postcard_shares' AND policyname = 'postcard_shares_read'
  ) THEN
    CREATE POLICY postcard_shares_read ON public.postcard_shares
      FOR SELECT USING (
        auth.uid() = user_id
        OR EXISTS (
          SELECT 1 FROM public.friendships
          WHERE status = 'accepted'
            AND (
              (user_id = auth.uid() AND friend_id = public.postcard_shares.user_id)
              OR (user_id = public.postcard_shares.user_id AND friend_id = auth.uid())
            )
        )
      );
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'postcard_shares' AND policyname = 'postcard_shares_insert'
  ) THEN
    CREATE POLICY postcard_shares_insert ON public.postcard_shares
      FOR INSERT WITH CHECK (auth.uid() = user_id);
  END IF;
END $$;

-- 3. Idempotent Postcard Share & Curator XP Reward RPC
CREATE OR REPLACE FUNCTION public.record_postcard_share(
  p_place_id TEXT,
  p_route_id TEXT DEFAULT NULL,
  p_share_channel TEXT DEFAULT 'telegram',
  p_receipt_number TEXT DEFAULT NULL,
  p_theme TEXT DEFAULT 'paper',
  p_aspect_ratio TEXT DEFAULT '9:16'
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
  v_uid UUID;
  v_share_id UUID;
  v_clean_place TEXT;
  v_new_xp INTEGER;
  v_new_level INTEGER := 1;
  v_new_tier TEXT := 'neighborhoodScout';
  v_xp_awarded INTEGER := 25;
BEGIN
  -- Strict caller identity binding (Rule C)
  v_uid := auth.uid();
  IF v_uid IS NULL THEN
    RETURN jsonb_build_object('success', false, 'error', 'Authentication required to record postcard share.');
  END IF;

  v_clean_place := trim(COALESCE(p_place_id, ''));
  IF char_length(v_clean_place) = 0 THEN
    RETURN jsonb_build_object('success', false, 'error', 'Place ID must not be empty.');
  END IF;

  -- Insert telemetry record
  INSERT INTO public.postcard_shares (
    user_id,
    place_id,
    route_id,
    share_channel,
    receipt_number,
    theme,
    aspect_ratio
  ) VALUES (
    v_uid,
    v_clean_place,
    NULLIF(trim(p_route_id), ''),
    COALESCE(NULLIF(trim(p_share_channel), ''), 'telegram'),
    NULLIF(trim(p_receipt_number), ''),
    COALESCE(NULLIF(trim(p_theme), ''), 'paper'),
    COALESCE(NULLIF(trim(p_aspect_ratio), ''), '9:16')
  )
  RETURNING id INTO v_share_id;

  -- Award +25 XP to the curator profile
  UPDATE public.profiles
  SET curator_xp = COALESCE(curator_xp, 0) + v_xp_awarded
  WHERE id = v_uid
  RETURNING curator_xp INTO v_new_xp;

  -- Recompute curator tier and level
  IF v_new_xp >= 2000 THEN
    v_new_tier := 'tashkentLegend';
    v_new_level := 4;
  ELSIF v_new_xp >= 750 THEN
    v_new_tier := 'cityPioneer';
    v_new_level := 3;
  ELSIF v_new_xp >= 250 THEN
    v_new_tier := 'districtCurator';
    v_new_level := 2;
  ELSE
    v_new_tier := 'neighborhoodScout';
    v_new_level := 1;
  END IF;

  UPDATE public.profiles
  SET curator_level = v_new_level,
      curator_tier = v_new_tier
  WHERE id = v_uid;

  RETURN jsonb_build_object(
    'success', true,
    'share_id', v_share_id,
    'place_id', v_clean_place,
    'route_id', p_route_id,
    'share_channel', p_share_channel,
    'receipt_number', p_receipt_number,
    'xp_awarded', v_xp_awarded,
    'curator_xp', v_new_xp,
    'curator_level', v_new_level,
    'curator_tier', v_new_tier
  );
END;
$$;

-- 4. Permissions
GRANT SELECT, INSERT ON TABLE public.postcard_shares TO authenticated;
GRANT EXECUTE ON FUNCTION public.record_postcard_share(TEXT, TEXT, TEXT, TEXT, TEXT, TEXT) TO authenticated;
