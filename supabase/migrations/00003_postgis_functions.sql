-- ==============================================================================
-- Around Platform: Database Migration 00003 - PostGIS Geospatial & Feed Queries
-- ==============================================================================

SET search_path TO public, extensions;

-- 1. Function: Nearby Places by GPS Coordinates & Search Query
CREATE OR REPLACE FUNCTION get_nearby_places(
  user_lat DOUBLE PRECISION DEFAULT 41.3111,
  user_lng DOUBLE PRECISION DEFAULT 69.2797,
  radius_meters DOUBLE PRECISION DEFAULT 5000,
  filter_category TEXT DEFAULT 'All',
  search_query TEXT DEFAULT '',
  limit_count INTEGER DEFAULT 20
)
RETURNS TABLE (
  id UUID,
  slug TEXT,
  name TEXT,
  category TEXT,
  street_address TEXT,
  district TEXT,
  city TEXT,
  latitude DOUBLE PRECISION,
  longitude DOUBLE PRECISION,
  distance_meters DOUBLE PRECISION,
  walk_time_minutes INTEGER,
  price_tier TEXT,
  hours TEXT,
  status_line TEXT,
  description TEXT,
  hero_image_url TEXT,
  rating_avg NUMERIC,
  rating_count INTEGER,
  tags TEXT[],
  photos TEXT[]
)
LANGUAGE sql
STABLE
SECURITY INVOKER
SET search_path = public, extensions
AS $$
  SELECT
    p.id,
    p.slug,
    p.name,
    p.category,
    p.street_address,
    p.district,
    p.city,
    ST_Y(p.location::geometry) AS latitude,
    ST_X(p.location::geometry) AS longitude,
    ST_Distance(p.location, ST_SetSRID(ST_MakePoint(user_lng, user_lat), 4326)::geography) AS distance_meters,
    -- Estimated walking time based on standard 80 meters/minute pace
    GREATEST(1, ROUND(ST_Distance(p.location, ST_SetSRID(ST_MakePoint(user_lng, user_lat), 4326)::geography) / 80)::INTEGER) AS walk_time_minutes,
    p.price_tier,
    p.hours,
    p.status_line,
    p.description,
    p.hero_image_url,
    p.rating_avg,
    p.rating_count,
    p.tags,
    p.photos
  FROM places p
  WHERE
    ST_DWithin(p.location, ST_SetSRID(ST_MakePoint(user_lng, user_lat), 4326)::geography, LEAST(GREATEST(radius_meters, 100), 50000))
    AND (
      filter_category = 'All'
      OR p.category ILIKE '%' || filter_category || '%'
      OR EXISTS (
        SELECT 1 FROM unnest(p.tags) AS t WHERE t ILIKE '%' || filter_category || '%'
      )
    )
    AND (
      COALESCE(TRIM(search_query), '') = ''
      OR p.name ILIKE '%' || TRIM(search_query) || '%'
      OR p.street_address ILIKE '%' || TRIM(search_query) || '%'
      OR p.district ILIKE '%' || TRIM(search_query) || '%'
      OR EXISTS (
        SELECT 1 FROM unnest(p.tags) AS t WHERE t ILIKE '%' || TRIM(search_query) || '%'
      )
    )
  ORDER BY distance_meters ASC
  LIMIT LEAST(GREATEST(limit_count, 1), 100);
$$;

REVOKE ALL ON FUNCTION get_nearby_places(DOUBLE PRECISION, DOUBLE PRECISION, DOUBLE PRECISION, TEXT, TEXT, INTEGER) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION get_nearby_places(DOUBLE PRECISION, DOUBLE PRECISION, DOUBLE PRECISION, TEXT, TEXT, INTEGER) TO authenticated;

-- 2. Function: Friends Social Feed (Enforces auth.uid(), SECURITY INVOKER, mutual friendship, block & quarantine isolation)
CREATE OR REPLACE FUNCTION get_friends_feed(
  page_limit INTEGER DEFAULT 20,
  page_offset INTEGER DEFAULT 0
)
RETURNS TABLE (
  post_id UUID,
  author_id UUID,
  author_name TEXT,
  author_username TEXT,
  author_avatar TEXT,
  place_id UUID,
  place_slug TEXT,
  place_name TEXT,
  place_category TEXT,
  place_address TEXT,
  note TEXT,
  rating SMALLINT,
  audience audience_type,
  size TEXT,
  tags TEXT[],
  media_url TEXT,
  saves_count INTEGER,
  created_at TIMESTAMPTZ,
  is_saved BOOLEAN
)
LANGUAGE sql
STABLE
SECURITY INVOKER
SET search_path = public, extensions
AS $$
  SELECT
    po.id AS post_id,
    pr.id AS author_id,
    pr.full_name AS author_name,
    pr.username AS author_username,
    pr.avatar_url AS author_avatar,
    pl.id AS place_id,
    pl.slug AS place_slug,
    pl.name AS place_name,
    pl.category AS place_category,
    pl.street_address AS place_address,
    po.note,
    po.rating,
    po.audience,
    po.size,
    po.tags,
    pm.media_url,
    po.saves_count,
    po.created_at,
    EXISTS(
      SELECT 1 FROM saved_places sp
      WHERE sp.user_id = auth.uid() AND sp.place_id = pl.id
    ) AS is_saved
  FROM posts po
  JOIN profiles pr ON pr.id = po.author_id
  JOIN places pl ON pl.id = po.place_id
  LEFT JOIN post_media pm ON pm.post_id = po.id AND pm.is_primary = TRUE
  WHERE
    auth.uid() IS NOT NULL
    AND po.is_quarantined = FALSE
    AND (
      po.author_id = auth.uid()
      OR are_friends(auth.uid(), po.author_id)
    )
    AND NOT is_blocked(auth.uid(), po.author_id)
  ORDER BY po.created_at DESC
  LIMIT LEAST(GREATEST(page_limit, 1), 50) OFFSET GREATEST(page_offset, 0);
$$;

REVOKE ALL ON FUNCTION get_friends_feed(INTEGER, INTEGER) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION get_friends_feed(INTEGER, INTEGER) TO authenticated;

-- 3. Function: Safe User Visit / Drop History (Enforces hide_visits_history privacy setting)
CREATE OR REPLACE FUNCTION get_user_visible_drops(
  target_user_id UUID,
  page_limit INTEGER DEFAULT 20
)
RETURNS SETOF posts
LANGUAGE sql
STABLE
SECURITY INVOKER
SET search_path = public, extensions
AS $$
  SELECT po.*
  FROM posts po
  JOIN profiles pr ON pr.id = po.author_id
  WHERE
    po.author_id = target_user_id
    AND po.is_quarantined = FALSE
    AND NOT is_blocked(auth.uid(), target_user_id)
    AND (
      -- User can always view their own drops
      target_user_id = auth.uid()
      OR (
        -- If target user has hide_visits_history = FALSE, mutual friends can view their timeline
        pr.hide_visits_history = FALSE
        AND are_friends(auth.uid(), target_user_id)
      )
    )
  ORDER BY po.created_at DESC
  LIMIT LEAST(GREATEST(page_limit, 1), 50);
$$;

REVOKE ALL ON FUNCTION get_user_visible_drops(UUID, INTEGER) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION get_user_visible_drops(UUID, INTEGER) TO authenticated;
