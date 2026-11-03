-- Migration 00019: Curator Seasons & Archived Trophy Wall
-- Stores seasonal milestone achievements and awards seasonal XP bonuses with mutual-friend RLS privacy.

-- 1. Seasonal Trophies Table
CREATE TABLE IF NOT EXISTS public.seasonal_trophies (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  season_id TEXT NOT NULL CHECK (char_length(trim(season_id)) BETWEEN 7 AND 10),
  season_title TEXT NOT NULL CHECK (char_length(trim(season_title)) BETWEEN 2 AND 120),
  trophy_tier TEXT NOT NULL CHECK (trophy_tier IN ('bronze', 'silver', 'gold')),
  completed_challenges_count INTEGER NOT NULL DEFAULT 1 CHECK (completed_challenges_count >= 1),
  xp_awarded INTEGER NOT NULL DEFAULT 0,
  claimed_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT unique_user_season_trophy UNIQUE(user_id, season_id)
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_seasonal_trophies_user ON public.seasonal_trophies(user_id);
CREATE INDEX IF NOT EXISTS idx_seasonal_trophies_season ON public.seasonal_trophies(season_id);

-- 2. Row-Level Security
ALTER TABLE public.seasonal_trophies ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'seasonal_trophies' AND policyname = 'seasonal_trophies_read'
  ) THEN
    CREATE POLICY seasonal_trophies_read ON public.seasonal_trophies
      FOR SELECT USING (
        auth.uid() = user_id
        OR EXISTS (
          SELECT 1 FROM public.friendships
          WHERE status = 'accepted'
            AND (
              (user_id = auth.uid() AND friend_id = public.seasonal_trophies.user_id)
              OR (user_id = public.seasonal_trophies.user_id AND friend_id = auth.uid())
            )
        )
      );
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'seasonal_trophies' AND policyname = 'seasonal_trophies_insert'
  ) THEN
    CREATE POLICY seasonal_trophies_insert ON public.seasonal_trophies
      FOR INSERT WITH CHECK (auth.uid() = user_id);
  END IF;
END $$;

-- 3. Idempotent Claim Seasonal Trophy RPC
CREATE OR REPLACE FUNCTION public.claim_seasonal_trophy(
  p_season_id TEXT,
  p_season_title TEXT,
  p_trophy_tier TEXT,
  p_completed_challenges_count INTEGER,
  p_xp_bonus INTEGER DEFAULT 0
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
  v_uid UUID;
  v_existing public.seasonal_trophies%ROWTYPE;
  v_trophy_id UUID;
  v_new_xp INTEGER;
  v_new_level INTEGER := 1;
  v_new_tier TEXT := 'neighborhoodScout';
  v_xp_bonus INTEGER := GREATEST(0, COALESCE(p_xp_bonus, 0));
BEGIN
  -- Strict caller identity binding (Rule C)
  v_uid := auth.uid();
  IF v_uid IS NULL THEN
    RETURN jsonb_build_object('success', false, 'error', 'Authentication required to claim seasonal trophy.');
  END IF;

  -- Verify season ID parameter
  IF char_length(trim(COALESCE(p_season_id, ''))) = 0 THEN
    RETURN jsonb_build_object('success', false, 'error', 'Season ID must not be empty.');
  END IF;

  -- Check if already claimed for this user & season
  SELECT * INTO v_existing
  FROM public.seasonal_trophies
  WHERE user_id = v_uid AND season_id = trim(p_season_id);

  IF FOUND THEN
    SELECT curator_xp, curator_level, curator_tier INTO v_new_xp, v_new_level, v_new_tier
    FROM public.profiles
    WHERE id = v_uid;

    RETURN jsonb_build_object(
      'success', true,
      'already_claimed', true,
      'trophy_id', v_existing.id,
      'season_id', v_existing.season_id,
      'trophy_tier', v_existing.trophy_tier,
      'xp_awarded', 0,
      'total_xp', v_new_xp,
      'curator_level', v_new_level,
      'curator_tier', v_new_tier
    );
  END IF;

  -- Insert seasonal trophy record
  INSERT INTO public.seasonal_trophies (
    user_id,
    season_id,
    season_title,
    trophy_tier,
    completed_challenges_count,
    xp_awarded
  ) VALUES (
    v_uid,
    trim(p_season_id),
    COALESCE(NULLIF(trim(p_season_title), ''), 'Tashkent Season'),
    LOWER(trim(p_trophy_tier)),
    GREATEST(1, p_completed_challenges_count),
    v_xp_bonus
  )
  RETURNING id INTO v_trophy_id;

  -- Award bonus XP to curator profile
  UPDATE public.profiles
  SET curator_xp = COALESCE(curator_xp, 0) + v_xp_bonus
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
    'already_claimed', false,
    'trophy_id', v_trophy_id,
    'season_id', trim(p_season_id),
    'trophy_tier', LOWER(trim(p_trophy_tier)),
    'xp_awarded', v_xp_bonus,
    'total_xp', v_new_xp,
    'curator_level', v_new_level,
    'curator_tier', v_new_tier
  );
END;
$$;

-- 4. Permissions
GRANT SELECT, INSERT ON TABLE public.seasonal_trophies TO authenticated;
GRANT EXECUTE ON FUNCTION public.claim_seasonal_trophy(TEXT, TEXT, TEXT, INTEGER, INTEGER) TO authenticated;
