-- Migration 00028: Neighborhood Drop Clusters RPC
-- Computes privacy-safe spatial grid clusters of community activity across Tashkent districts.

CREATE OR REPLACE FUNCTION public.get_neighborhood_drop_clusters(
  p_district TEXT DEFAULT NULL,
  p_grid_step NUMERIC DEFAULT 0.0035
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
  v_district TEXT := TRIM(p_district);
  v_step NUMERIC := GREATEST(COALESCE(p_grid_step, 0.0035), 0.001);
  v_clusters JSONB := '[]'::jsonb;
  v_count INTEGER := 0;
BEGIN
  -- Aggregate public drops within ~350m spatial grid bins
  WITH public_drops AS (
    SELECT
      po.id AS drop_id,
      COALESCE(pl.district, p.district, 'Mirabad') AS district,
      pl.name AS place_name,
      ROUND((ST_Y(pl.location::geometry) / v_step)) * v_step AS cell_lat,
      ROUND((ST_X(pl.location::geometry) / (v_step * 1.33))) * (v_step * 1.33) AS cell_lng,
      ST_Y(pl.location::geometry) AS raw_lat,
      ST_X(pl.location::geometry) AS raw_lng
    FROM public.posts po
    JOIN public.profiles p ON p.id = po.user_id
    JOIN public.places pl ON pl.id = po.place_id
    WHERE
      po.privacy = 'public'
      AND COALESCE(p.hide_visits_history, false) = false
      AND (
        v_district IS NULL
        OR v_district = ''
        OR LOWER(v_district) = 'all'
        OR LOWER(COALESCE(pl.district, p.district, '')) = LOWER(v_district)
      )
  ),
  aggregated_clusters AS (
    SELECT
      district,
      ROUND(AVG(raw_lat)::numeric, 4) AS centroid_lat,
      ROUND(AVG(raw_lng)::numeric, 4) AS centroid_lng,
      COUNT(*)::int AS drops_count,
      ARRAY_AGG(DISTINCT place_name) FILTER (WHERE place_name IS NOT NULL AND place_name <> '') AS venue_names
    FROM public_drops
    GROUP BY district, cell_lat, cell_lng
  )
  SELECT
    COALESCE(
      jsonb_agg(
        jsonb_build_object(
          'id', 'cluster_' || LOWER(c.district) || '_' || REPLACE(c.centroid_lat::text, '.', '_') || '_' || REPLACE(c.centroid_lng::text, '.', '_'),
          'centroid_lat', c.centroid_lat,
          'centroid_lng', c.centroid_lng,
          'district', c.district,
          'intensity', CASE
            WHEN c.drops_count >= 11 THEN 'peak'
            WHEN c.drops_count >= 6 THEN 'buzzing'
            WHEN c.drops_count >= 3 THEN 'lively'
            ELSE 'serene'
          END,
          'drops_count', c.drops_count,
          'venue_names', to_jsonb(c.venue_names),
          'primary_venue_name', COALESCE(c.venue_names[1], 'Local Spot'),
          'radius_meters', 350.0
        ) ORDER BY c.drops_count DESC
      ),
      '[]'::jsonb
    ),
    COUNT(*)
  INTO
    v_clusters,
    v_count
  FROM aggregated_clusters c;

  RETURN jsonb_build_object(
    'success', true,
    'district', COALESCE(v_district, 'all'),
    'count', v_count,
    'clusters', v_clusters
  );
END;
$$;

-- Grant execution to authenticated users and anonymous visitors
GRANT EXECUTE ON FUNCTION public.get_neighborhood_drop_clusters(TEXT, NUMERIC) TO authenticated, anon;
