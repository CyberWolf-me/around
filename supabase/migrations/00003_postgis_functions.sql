-- ==============================================================================
-- Around Platform: Database Migration 00003 - PostGIS Geospatial Queries
-- ==============================================================================

-- 1. Function: Nearby Places by GPS Coordinates (Optimized with PostGIS GiST index)
CREATE OR REPLACE FUNCTION get_nearby_places(
  user_lat DOUBLE PRECISION,
  user_lng DOUBLE PRECISION,
  radius_meters DOUBLE PRECISION DEFAULT 2500,
  filter_category TEXT DEFAULT 'All',
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
  hero_image_url TEXT,
  rating_avg NUMERIC,
  rating_count INTEGER,
  tags TEXT[]
)
LANGUAGE sql
STABLE
SECURITY DEFINER
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
    ROUND(ST_Distance(p.location, ST_SetSRID(ST_MakePoint(user_lng, user_lat), 4326)::geography) / 80)::INTEGER AS walk_time_minutes,
    p.price_tier,
    p.hours,
    p.hero_image_url,
    p.rating_avg,
    p.rating_count,
    p.tags
  FROM places p
  WHERE
    ST_DWithin(p.location, ST_SetSRID(ST_MakePoint(user_lng, user_lat), 4326)::geography, radius_meters)
    AND (
      filter_category = 'All'
      OR p.category ILIKE '%' || filter_category || '%'
      OR filter_category = ANY(p.tags)
    )
  ORDER BY distance_meters ASC
  LIMIT limit_count;
$$;

-- 2. Function: Friends Social Feed (Finite, chronological, friends-only drops)
CREATE OR REPLACE FUNCTION get_friends_feed(
  requesting_user_id UUID,
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
  place_name TEXT,
  place_category TEXT,
  place_address TEXT,
  note TEXT,
  rating SMALLINT,
  audience audience_type,
  tags TEXT[],
  media_url TEXT,
  saves_count INTEGER,
  created_at TIMESTAMPTZ,
  is_saved BOOLEAN
)
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
  SELECT
    po.id AS post_id,
    pr.id AS author_id,
    pr.full_name AS author_name,
    pr.username AS author_username,
    pr.avatar_url AS author_avatar,
    pl.id AS place_id,
    pl.name AS place_name,
    pl.category AS place_category,
    pl.street_address AS place_address,
    po.note,
    po.rating,
    po.audience,
    po.tags,
    pm.media_url,
    po.saves_count,
    po.created_at,
    EXISTS(
      SELECT 1 FROM saved_places sp
      WHERE sp.user_id = requesting_user_id AND sp.place_id = pl.id
    ) AS is_saved
  FROM posts po
  JOIN profiles pr ON pr.id = po.author_id
  JOIN places pl ON pl.id = po.place_id
  LEFT JOIN post_media pm ON pm.post_id = po.id AND pm.is_primary = TRUE
  WHERE
    -- Author is requesting user OR accepted friend
    (
      po.author_id = requesting_user_id
      OR EXISTS (
        SELECT 1 FROM friendships f
        WHERE f.status = 'accepted'
          AND (
            (f.user_id = requesting_user_id AND f.friend_id = po.author_id)
            OR (f.user_id = po.author_id AND f.friend_id = requesting_user_id)
          )
      )
    )
    -- Exclude blocked users
    AND NOT is_blocked(requesting_user_id, po.author_id)
  ORDER BY po.created_at DESC
  LIMIT page_limit OFFSET page_offset;
$$;
