-- Migration 00013: Privacy-Preserving District Activity Density Engine
-- Aggregates public and friends drops by Tashkent district to compute relative
-- social heatmaps without exposing sensitive individual GPS coordinates or user identities.

CREATE OR REPLACE FUNCTION public.get_district_activity_density(
  p_window_days integer DEFAULT 7
)
RETURNS TABLE (
  district text,
  drop_count bigint,
  active_venues_count bigint,
  centroid_lat double precision,
  centroid_lng double precision,
  relative_density double precision
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
  v_max_drops bigint;
BEGIN
  -- Determine highest drop count across districts in the time window for normalization
  SELECT COALESCE(MAX(d_count), 1)
  INTO v_max_drops
  FROM (
    SELECT COUNT(p.id) AS d_count
    FROM public.places pl
    LEFT JOIN public.posts p ON p.place_id = pl.id
      AND p.is_quarantined = FALSE
      AND p.created_at >= (NOW() - (p_window_days || ' days')::interval)
    GROUP BY pl.district
  ) sub;

  RETURN QUERY
  SELECT
    pl.district::text,
    COUNT(p.id)::bigint AS drop_count,
    COUNT(DISTINCT pl.id)::bigint AS active_venues_count,
    AVG(ST_Y(pl.location::geometry))::double precision AS centroid_lat,
    AVG(ST_X(pl.location::geometry))::double precision AS centroid_lng,
    ROUND((COUNT(p.id)::double precision / GREATEST(v_max_drops, 1)::double precision)::numeric, 3)::double precision AS relative_density
  FROM public.places pl
  LEFT JOIN public.posts p ON p.place_id = pl.id
    AND p.is_quarantined = FALSE
    AND p.created_at >= (NOW() - (p_window_days || ' days')::interval)
  WHERE pl.district IS NOT NULL
  GROUP BY pl.district
  HAVING COUNT(pl.id) > 0
  ORDER BY drop_count DESC, pl.district ASC;
END;
$$;

-- Grant execution to authenticated users and anonymous visitors
GRANT EXECUTE ON FUNCTION public.get_district_activity_density(integer) TO anon;
GRANT EXECUTE ON FUNCTION public.get_district_activity_density(integer) TO authenticated;

COMMENT ON FUNCTION public.get_district_activity_density IS
  'Computes privacy-preserving district density heat scores for Tashkent neighborhoods over a rolling time window.';
