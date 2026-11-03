-- Migration 00025: District Activity Ticker RPC
-- Aggregates sanitized, privacy-safe community events across Tashkent districts.

CREATE OR REPLACE FUNCTION public.get_district_activity_ticker(
  p_district TEXT DEFAULT NULL,
  p_limit INTEGER DEFAULT 20
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
  v_district TEXT := TRIM(p_district);
  v_limit INTEGER := LEAST(GREATEST(COALESCE(p_limit, 20), 1), 50);
  v_events JSONB := '[]'::jsonb;
  v_count INTEGER := 0;
BEGIN
  -- Aggregate public drops and check-ins, honoring privacy invariants
  WITH recent_drops AS (
    SELECT
      po.id AS id,
      'dropCreated' AS type,
      p.id AS user_id,
      p.username,
      COALESCE(p.full_name, p.username) AS user_full_name,
      p.avatar_url AS user_avatar_url,
      COALESCE(pl.district, p.district, 'Mirabad') AS district,
      pl.name AS place_name,
      pl.id::text AS place_id,
      NULL::text AS route_name,
      NULL::text AS route_id,
      NULL::text AS badge_name,
      NULL::integer AS xp_awarded,
      po.created_at AS timestamp
    FROM public.posts po
    JOIN public.profiles p ON p.id = po.user_id
    LEFT JOIN public.places pl ON pl.id = po.place_id
    WHERE
      po.privacy = 'public'
      AND COALESCE(p.hide_visits_history, false) = false
      AND (
        v_district IS NULL 
        OR v_district = '' 
        OR LOWER(v_district) = 'all'
        OR LOWER(COALESCE(pl.district, p.district, '')) = LOWER(v_district)
      )
    ORDER BY po.created_at DESC
    LIMIT v_limit
  )
  SELECT
    COALESCE(
      jsonb_agg(
        jsonb_build_object(
          'id', d.id,
          'type', d.type,
          'user_id', d.user_id,
          'username', d.username,
          'user_full_name', d.user_full_name,
          'user_avatar_url', d.user_avatar_url,
          'district', d.district,
          'place_name', d.place_name,
          'place_id', d.place_id,
          'route_name', d.route_name,
          'route_id', d.route_id,
          'badge_name', d.badge_name,
          'xp_awarded', d.xp_awarded,
          'timestamp', d.timestamp
        ) ORDER BY d.timestamp DESC
      ),
      '[]'::jsonb
    ),
    COUNT(*)
  INTO
    v_events,
    v_count
  FROM recent_drops d;

  RETURN jsonb_build_object(
    'success', true,
    'district', COALESCE(v_district, 'all'),
    'events', v_events,
    'count', v_count
  );
END;
$$;

-- Grant execution to authenticated users and anonymous visitors
GRANT EXECUTE ON FUNCTION public.get_district_activity_ticker(TEXT, INTEGER) TO authenticated, anon;
