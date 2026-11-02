-- ============================================================================
-- AROUND — MIGRATION 00010: CURSOR-BASED KEYSET PAGINATION & GEOSPATIAL TIE-BREAKING
-- Task: P8-01 (Discovery Domain & Scalable Keyset Feed Architecture)
-- Purpose:
--   1. Upgrades `public.get_friends_feed` with optional `p_cursor_created_at`
--      and `p_cursor_id` parameters for O(1) deterministic keyset pagination.
--   2. Upgrades `public.get_nearby_places` with optional `p_cursor_distance`
--      and `p_cursor_id` parameters for stable distance-ordered keyset paging.
--   3. Enforces deterministic tie-breaking on unique UUID `id` to eliminate
--      duplicate or skipped records across page boundaries.
--   4. Preserves backward-compatible default parameters and strict RLS permissions.
-- ============================================================================

-- 1. Upgraded Friends Social Feed with Keyset Cursor Pagination
CREATE OR REPLACE FUNCTION public.get_friends_feed(
  page_limit INTEGER DEFAULT 20,
  page_offset INTEGER DEFAULT 0,
  p_cursor_created_at TIMESTAMPTZ DEFAULT NULL,
  p_cursor_id UUID DEFAULT NULL
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
  place_district TEXT,
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
LANGUAGE plpgsql
STABLE
SECURITY INVOKER
SET search_path = public
AS $$
DECLARE
  caller_uid UUID := auth.uid();
BEGIN
  IF caller_uid IS NULL THEN
    RAISE EXCEPTION 'Authentication required to fetch friends feed' USING ERRCODE = '42501';
  END IF;

  RETURN QUERY
  SELECT
    po.id AS post_id,
    po.author_id,
    pr.full_name AS author_name,
    pr.username AS author_username,
    pr.avatar_url AS author_avatar,
    pl.id AS place_id,
    pl.slug AS place_slug,
    pl.name AS place_name,
    pl.category AS place_category,
    pl.street_address AS place_address,
    pl.district AS place_district,
    po.note,
    po.rating,
    po.audience,
    po.size,
    po.tags,
    (
      SELECT pm.media_url
      FROM public.post_media pm
      WHERE pm.post_id = po.id
      ORDER BY pm.is_primary DESC, pm.created_at ASC
      LIMIT 1
    ) AS media_url,
    po.saves_count,
    po.created_at,
    EXISTS(
      SELECT 1 FROM public.saved_places sp
      WHERE sp.user_id = caller_uid AND sp.place_id = pl.id
    ) AS is_saved
  FROM public.posts po
  INNER JOIN public.profiles pr ON pr.id = po.author_id
  INNER JOIN public.places pl ON pl.id = po.place_id
  WHERE
    po.is_quarantined = FALSE
    AND (
      po.author_id = caller_uid
      OR public.are_friends(caller_uid, po.author_id)
    )
    AND NOT public.is_blocked(caller_uid, po.author_id)
    AND (
      p_cursor_created_at IS NULL
      OR po.created_at < p_cursor_created_at
      OR (po.created_at = p_cursor_created_at AND (p_cursor_id IS NULL OR po.id < p_cursor_id))
    )
  ORDER BY po.created_at DESC, po.id DESC
  LIMIT LEAST(GREATEST(page_limit, 1), 50)
  OFFSET (CASE WHEN p_cursor_created_at IS NULL THEN GREATEST(page_offset, 0) ELSE 0 END);
END;
$$;

-- Revoke from anonymous callers and grant strictly to authenticated callers
REVOKE ALL ON FUNCTION public.get_friends_feed(INTEGER, INTEGER, TIMESTAMPTZ, UUID) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.get_friends_feed(INTEGER, INTEGER, TIMESTAMPTZ, UUID) TO authenticated;


-- 2. Upgraded Spatial Discovery with Keyset Distance Pagination
CREATE OR REPLACE FUNCTION public.get_nearby_places(
  user_lat DOUBLE PRECISION DEFAULT 41.3111,
  user_lng DOUBLE PRECISION DEFAULT 69.2797,
  radius_meters DOUBLE PRECISION DEFAULT 5000,
  filter_category TEXT DEFAULT 'All',
  search_query TEXT DEFAULT '',
  limit_count INTEGER DEFAULT 20,
  p_cursor_distance DOUBLE PRECISION DEFAULT NULL,
  p_cursor_id UUID DEFAULT NULL
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
  FROM public.places p
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
    AND (
      p_cursor_distance IS NULL
      OR ST_Distance(p.location, ST_SetSRID(ST_MakePoint(user_lng, user_lat), 4326)::geography) > p_cursor_distance
      OR (
        ST_Distance(p.location, ST_SetSRID(ST_MakePoint(user_lng, user_lat), 4326)::geography) = p_cursor_distance
        AND (p_cursor_id IS NULL OR p.id > p_cursor_id)
      )
    )
  ORDER BY distance_meters ASC, p.id ASC
  LIMIT LEAST(GREATEST(limit_count, 1), 100);
$$;

-- Grants for public place discovery (MIG-08 aligned)
GRANT EXECUTE ON FUNCTION public.get_nearby_places(DOUBLE PRECISION, DOUBLE PRECISION, DOUBLE PRECISION, TEXT, TEXT, INTEGER, DOUBLE PRECISION, UUID) TO anon, authenticated, PUBLIC;
