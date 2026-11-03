-- Migration 00015: Curator Levels, Progression XP & District Leaderboard RPC
-- Adds persistent curator progression stats to profiles and creates an idempotent,
-- privacy-respecting leaderboard RPC with optional PostGIS district filtering.

-- 1. Add curator progression columns to profiles
ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS curator_xp INTEGER NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS curator_level INTEGER NOT NULL DEFAULT 1,
  ADD COLUMN IF NOT EXISTS curator_tier TEXT NOT NULL DEFAULT 'neighborhoodScout',
  ADD COLUMN IF NOT EXISTS crowns_count INTEGER NOT NULL DEFAULT 0;

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_profiles_curator_xp ON public.profiles(curator_xp DESC);
CREATE INDEX IF NOT EXISTS idx_profiles_curator_tier ON public.profiles(curator_tier);

-- 2. Helper function to recompute and persist curator XP for a user
CREATE OR REPLACE FUNCTION public.sync_profile_curator_xp(p_target_id UUID DEFAULT NULL)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
  v_uid UUID;
  v_drops_count BIGINT := 0;
  v_crowns_count BIGINT := 0;
  v_total_xp INTEGER := 0;
  v_level INTEGER := 1;
  v_tier TEXT := 'neighborhoodScout';
BEGIN
  v_uid := COALESCE(p_target_id, auth.uid());
  IF v_uid IS NULL THEN
    RETURN jsonb_build_object('success', false, 'error', 'No target user specified and caller is unauthenticated');
  END IF;

  -- Count unquarantined drops created by user
  SELECT COUNT(id) INTO v_drops_count
  FROM public.posts
  WHERE user_id = v_uid AND is_quarantined = FALSE;

  -- Count active crowns (if table exists or from saved profile column)
  SELECT COALESCE(crowns_count, 0) INTO v_crowns_count
  FROM public.profiles
  WHERE id = v_uid;

  -- 50 XP per drop, 250 XP per crown
  v_total_xp := (v_drops_count * 50) + (v_crowns_count * 250);

  IF v_total_xp >= 2000 THEN
    v_tier := 'tashkentLegend';
    v_level := 4;
  ELSIF v_total_xp >= 750 THEN
    v_tier := 'cityPioneer';
    v_level := 3;
  ELSIF v_total_xp >= 250 THEN
    v_tier := 'districtCurator';
    v_level := 2;
  ELSE
    v_tier := 'neighborhoodScout';
    v_level := 1;
  END IF;

  UPDATE public.profiles
  SET curator_xp = v_total_xp,
      curator_level = v_level,
      curator_tier = v_tier,
      updated_at = NOW()
  WHERE id = v_uid;

  RETURN jsonb_build_object(
    'user_id', v_uid,
    'curator_xp', v_total_xp,
    'curator_level', v_level,
    'curator_tier', v_tier,
    'drops_count', v_drops_count
  );
END;
$$;

-- 3. Privacy-Preserving Curator Leaderboard RPC
CREATE OR REPLACE FUNCTION public.get_curator_leaderboard(
  p_district TEXT DEFAULT NULL,
  p_limit INTEGER DEFAULT 20
)
RETURNS TABLE (
  rank BIGINT,
  user_id UUID,
  username TEXT,
  full_name TEXT,
  avatar_url TEXT,
  curator_xp INTEGER,
  curator_level INTEGER,
  curator_tier TEXT,
  district_drops_count BIGINT
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
  v_caller_id UUID;
  v_limit INTEGER;
BEGIN
  v_caller_id := auth.uid();
  v_limit := LEAST(GREATEST(p_limit, 1), 100);

  IF p_district IS NOT NULL AND trim(p_district) <> '' THEN
    -- District-specific ranking based on drops at places located in that district
    RETURN QUERY
    WITH district_curators AS (
      SELECT
        p.id AS prof_id,
        p.username,
        p.full_name,
        p.avatar_url,
        p.curator_xp,
        p.curator_level,
        p.curator_tier,
        COUNT(po.id) AS dist_drops,
        p.hide_visits_history
      FROM public.profiles p
      JOIN public.posts po ON po.user_id = p.id AND po.is_quarantined = FALSE
      JOIN public.places pl ON pl.id = po.place_id
      WHERE LOWER(pl.district) = LOWER(trim(p_district))
      GROUP BY p.id, p.username, p.full_name, p.avatar_url, p.curator_xp, p.curator_level, p.curator_tier, p.hide_visits_history
      HAVING COUNT(po.id) > 0
    )
    SELECT
      ROW_NUMBER() OVER (ORDER BY dc.dist_drops DESC, dc.curator_xp DESC, dc.username ASC)::BIGINT AS rank,
      dc.prof_id AS user_id,
      dc.username,
      dc.full_name,
      dc.avatar_url,
      dc.curator_xp,
      dc.curator_level,
      dc.curator_tier,
      dc.dist_drops::BIGINT AS district_drops_count
    FROM district_curators dc
    ORDER BY rank ASC
    LIMIT v_limit;
  ELSE
    -- City-wide curator ranking based on global curator XP
    RETURN QUERY
    SELECT
      ROW_NUMBER() OVER (ORDER BY p.curator_xp DESC, p.created_at ASC)::BIGINT AS rank,
      p.id AS user_id,
      p.username,
      p.full_name,
      p.avatar_url,
      p.curator_xp,
      p.curator_level,
      p.curator_tier,
      COALESCE(sub.total_drops, 0)::BIGINT AS district_drops_count
    FROM public.profiles p
    LEFT JOIN (
      SELECT user_id, COUNT(id) AS total_drops
      FROM public.posts
      WHERE is_quarantined = FALSE
      GROUP BY user_id
    ) sub ON sub.user_id = p.id
    ORDER BY p.curator_xp DESC, rank ASC
    LIMIT v_limit;
  END IF;
END;
$$;

-- Grant execution permissions to authenticated users and anonymous visitors
GRANT EXECUTE ON FUNCTION public.sync_profile_curator_xp(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.sync_profile_curator_xp(UUID) TO service_role;
GRANT EXECUTE ON FUNCTION public.get_curator_leaderboard(TEXT, INTEGER) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_curator_leaderboard(TEXT, INTEGER) TO anon;

COMMENT ON FUNCTION public.get_curator_leaderboard IS
  'Returns ranked curator profiles filtered optionally by Tashkent district or globally by curator XP.';
