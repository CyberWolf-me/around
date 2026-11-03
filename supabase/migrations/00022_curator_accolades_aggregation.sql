-- Migration 00022: Curator Accolades Aggregation RPC
-- Aggregates crowns, seasonal trophies, and district laurels in a single performant payload.

CREATE OR REPLACE FUNCTION public.get_curator_accolades(p_user_id UUID DEFAULT NULL)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
  v_target_user UUID;
  v_username TEXT;
  v_full_name TEXT;
  v_avatar_url TEXT;
  v_crowns INTEGER := 0;
  v_trophies JSONB := '[]'::jsonb;
  v_laurels JSONB := '[]'::jsonb;
BEGIN
  -- Derive target user: caller identity or requested user
  v_target_user := COALESCE(p_user_id, auth.uid());

  IF v_target_user IS NULL THEN
    RETURN jsonb_build_object(
      'success', false,
      'error', 'Authentication required or target user ID must be provided.'
    );
  END IF;

  -- 1. Fetch profile metadata and crowns count
  SELECT
    username,
    full_name,
    avatar_url,
    COALESCE(crowns_count, 0)
  INTO
    v_username,
    v_full_name,
    v_avatar_url,
    v_crowns
  FROM public.profiles
  WHERE id = v_target_user;

  IF NOT FOUND THEN
    RETURN jsonb_build_object(
      'success', false,
      'error', 'Profile not found.'
    );
  END IF;

  -- 2. Fetch earned seasonal trophies
  SELECT COALESCE(
    jsonb_agg(
      jsonb_build_object(
        'id', id,
        'season_id', season_id,
        'season_title', season_title,
        'tier', trophy_tier,
        'completed_challenges_count', completed_challenges_count,
        'xp_bonus', xp_awarded,
        'earned_at', created_at
      ) ORDER BY created_at DESC
    ),
    '[]'::jsonb
  )
  INTO v_trophies
  FROM public.seasonal_trophies
  WHERE user_id = v_target_user;

  -- 3. Fetch archived Hall of Fame laurels
  SELECT COALESCE(
    jsonb_agg(
      jsonb_build_object(
        'id', id,
        'season_id', season_id,
        'district', district,
        'rank', rank,
        'laurel', laurel,
        'season_xp', season_xp,
        'places_count', places_count,
        'archived_at', archived_at
      ) ORDER BY archived_at DESC
    ),
    '[]'::jsonb
  )
  INTO v_laurels
  FROM public.season_hall_of_fame
  WHERE user_id = v_target_user;

  RETURN jsonb_build_object(
    'success', true,
    'user_id', v_target_user,
    'username', v_username,
    'full_name', v_full_name,
    'avatar_url', v_avatar_url,
    'crowns_count', v_crowns,
    'trophies', v_trophies,
    'laurels', v_laurels
  );
END;
$$;

-- Grant execution permissions
GRANT EXECUTE ON FUNCTION public.get_curator_accolades(UUID) TO anon, authenticated;
