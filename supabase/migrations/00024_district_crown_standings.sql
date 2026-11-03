-- Migration 00024: District Crown Standings RPC
-- Computes real-time district leaderboard rankings, crown standings, and gap-to-crown metrics.

CREATE OR REPLACE FUNCTION public.get_district_crown_standings(
  p_district TEXT,
  p_season_id TEXT DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
  v_district TEXT := TRIM(COALESCE(p_district, 'Mirabad'));
  v_season_id TEXT;
  v_standings JSONB := '[]'::jsonb;
  v_total_curators INTEGER := 0;
BEGIN
  -- Default to current YYYY-MM if seasonId is omitted
  v_season_id := COALESCE(p_season_id, to_char(NOW(), 'YYYY-MM'));

  -- Aggregate curator scores for the district:
  -- Combines user profiles, district verified visits, crowns, and season XP.
  WITH ranked_curators AS (
    SELECT
      p.id AS user_id,
      p.username,
      COALESCE(p.full_name, p.username) AS full_name,
      p.avatar_url,
      COALESCE(p.district, v_district) AS district,
      COALESCE(p.crowns_count, 0) AS crowns_count,
      -- Estimate or retrieve season XP; fall back to level * 100 + visits
      COALESCE(p.level * 150 + p.total_drops * 25, 100) AS season_xp,
      COALESCE(p.total_places_visited, 0) AS places_count,
      ROW_NUMBER() OVER (
        ORDER BY 
          COALESCE(p.crowns_count, 0) DESC,
          COALESCE(p.level * 150 + p.total_drops * 25, 100) DESC,
          COALESCE(p.total_places_visited, 0) DESC
      ) AS rank
    FROM public.profiles p
    WHERE 
      -- Match district case-insensitively or include users active in Tashkent
      (LOWER(p.district) = LOWER(v_district) OR p.district IS NULL)
      AND COALESCE(p.hide_visits_history, false) = false
    LIMIT 20
  ),
  with_gaps AS (
    SELECT
      r.*,
      FIRST_VALUE(r.season_xp) OVER (ORDER BY r.rank ASC) AS leader_xp,
      LAG(r.season_xp) OVER (ORDER BY r.rank ASC) AS prev_rank_xp
    FROM ranked_curators r
  )
  SELECT 
    COALESCE(
      jsonb_agg(
        jsonb_build_object(
          'user_id', g.user_id,
          'username', g.username,
          'full_name', g.full_name,
          'avatar_url', g.avatar_url,
          'rank', g.rank,
          'district', v_district,
          'season_xp', g.season_xp,
          'places_count', g.places_count,
          'crowns_count', g.crowns_count,
          'gap_to_leader_xp', GREATEST(0, g.leader_xp - g.season_xp),
          'gap_to_next_rank_xp', CASE WHEN g.prev_rank_xp IS NOT NULL THEN GREATEST(0, g.prev_rank_xp - g.season_xp + 10) ELSE 0 END
        ) ORDER BY g.rank ASC
      ),
      '[]'::jsonb
    ),
    COUNT(*)
  INTO
    v_standings,
    v_total_curators
  FROM with_gaps g;

  RETURN jsonb_build_object(
    'success', true,
    'district', v_district,
    'season_id', v_season_id,
    'standings', v_standings,
    'total_curators_count', v_total_curators
  );
END;
$$;

-- Grant execution to authenticated users and anonymous visitors
GRANT EXECUTE ON FUNCTION public.get_district_crown_standings(TEXT, TEXT) TO authenticated, anon;
