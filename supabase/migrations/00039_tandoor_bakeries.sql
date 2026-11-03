-- Migration 00039: Tashkent Traditional Bread (Non) Guild & Tandoor Bakeries Schema & RPC
-- Enables discovery of clay tandoor bakeries, chekich center pin stamp patterns, and fresh bread batch reservations (+30 XP).

-- 1. Tandoor Bakeries Definition Table
CREATE TABLE IF NOT EXISTS public.tandoor_bakeries (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  slug TEXT UNIQUE NOT NULL CHECK (char_length(trim(slug)) BETWEEN 3 AND 80),
  name TEXT NOT NULL CHECK (char_length(trim(name)) BETWEEN 3 AND 120),
  district TEXT NOT NULL CHECK (char_length(trim(district)) BETWEEN 2 AND 80),
  head_baker TEXT NOT NULL CHECK (char_length(trim(head_baker)) BETWEEN 2 AND 100),
  tandoor_clay_origin TEXT NOT NULL,
  daily_batches_count INTEGER NOT NULL DEFAULT 12 CHECK (daily_batches_count > 0),
  current_batch_hot_loaves INTEGER NOT NULL DEFAULT 24 CHECK (current_batch_hot_loaves >= 0),
  next_batch_minutes INTEGER NOT NULL DEFAULT 8 CHECK (next_batch_minutes >= 0),
  signature_breads TEXT[] NOT NULL DEFAULT '{}',
  favorite_chekich TEXT NOT NULL DEFAULT 'sunburst' CHECK (favorite_chekich IN ('sunburst', 'rosette', 'octagon')),
  latitude DOUBLE PRECISION NOT NULL,
  longitude DOUBLE PRECISION NOT NULL,
  is_published BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 2. User Bread Batch Reservations Table
CREATE TABLE IF NOT EXISTS public.user_bread_reservations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  bakery_id UUID NOT NULL REFERENCES public.tandoor_bakeries(id) ON DELETE CASCADE,
  variety_id TEXT NOT NULL CHECK (variety_id IN ('obi_non', 'patir', 'shirmoy', 'jizzali')),
  loaves_count INTEGER NOT NULL DEFAULT 2 CHECK (loaves_count BETWEEN 1 AND 20),
  xp_awarded INTEGER NOT NULL DEFAULT 30 CHECK (xp_awarded >= 0),
  status TEXT NOT NULL DEFAULT 'confirmed' CHECK (status IN ('confirmed', 'picked_up', 'cancelled')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Performance Indexes
CREATE INDEX IF NOT EXISTS idx_tandoor_bakeries_slug ON public.tandoor_bakeries(slug);
CREATE INDEX IF NOT EXISTS idx_tandoor_bakeries_district ON public.tandoor_bakeries(district);
CREATE INDEX IF NOT EXISTS idx_user_bread_reservations_user ON public.user_bread_reservations(user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_user_bread_reservations_bakery ON public.user_bread_reservations(bakery_id);

-- Enable Row-Level Security
ALTER TABLE public.tandoor_bakeries ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_bread_reservations ENABLE ROW LEVEL SECURITY;

-- Read policy for published bakeries
CREATE POLICY "Published tandoor bakeries readable by all"
  ON public.tandoor_bakeries
  FOR SELECT
  USING (is_published = true);

-- Dual-layer privacy read policy for user bread reservations
CREATE POLICY "Bread reservations readable if user privacy permits"
  ON public.user_bread_reservations
  FOR SELECT
  USING (
    auth.uid() = user_id
    OR EXISTS (
      SELECT 1 FROM public.profiles p
      WHERE p.id = user_bread_reservations.user_id
        AND COALESCE(p.hide_visits_history, false) = false
    )
  );

CREATE POLICY "Users can insert their own bread reservations"
  ON public.user_bread_reservations
  FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own bread reservations"
  ON public.user_bread_reservations
  FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete their own bread reservations"
  ON public.user_bread_reservations
  FOR DELETE
  USING (auth.uid() = user_id);

-- Seed Curated Tashkent Tandoor Bakeries
INSERT INTO public.tandoor_bakeries (
  id, slug, name, district, head_baker, tandoor_clay_origin, daily_batches_count,
  current_batch_hot_loaves, next_batch_minutes, signature_breads, favorite_chekich, latitude, longitude
) VALUES
(
  'e1000000-0000-0000-0000-000000000001',
  'bakery-chorsu-kattabog',
  'Chorsu Kattabog Tandoor Bakery',
  'Old City Shaykhontohur',
  'Novvoyboshi Usto Shuhrat',
  'Rishtan Ochre Refractory Clay',
  16,
  32,
  12,
  ARRAY['obi_non', 'patir', 'jizzali'],
  'sunburst',
  41.3283,
  69.2394
),
(
  'e1000000-0000-0000-0000-000000000002',
  'bakery-chigatoy-shirmoy',
  'Chigatoy Shirmoy Tandoor Guild',
  'Chigatoy Olmazor',
  'Novvoyboshi Usto Alisher',
  'Samarkand Loess Silt Clay',
  14,
  18,
  5,
  ARRAY['shirmoy', 'patir'],
  'rosette',
  41.3412,
  69.2198
),
(
  'e1000000-0000-0000-0000-000000000003',
  'bakery-keles-jizzali',
  'Keles Traditional Winter Tandoor',
  'Olmazor North',
  'Usto Bahrom Novvoy',
  'Gazgan Red Fireclay Tandoor',
  14,
  28,
  4,
  ARRAY['obi_non', 'jizzali', 'patir'],
  'octagon',
  41.3521,
  69.2132
)
ON CONFLICT (slug) DO UPDATE SET
  name = EXCLUDED.name,
  district = EXCLUDED.district,
  head_baker = EXCLUDED.head_baker,
  tandoor_clay_origin = EXCLUDED.tandoor_clay_origin,
  daily_batches_count = EXCLUDED.daily_batches_count,
  current_batch_hot_loaves = EXCLUDED.current_batch_hot_loaves,
  next_batch_minutes = EXCLUDED.next_batch_minutes,
  signature_breads = EXCLUDED.signature_breads,
  favorite_chekich = EXCLUDED.favorite_chekich,
  latitude = EXCLUDED.latitude,
  longitude = EXCLUDED.longitude;

-- Security Definer RPC for Reserving Fresh Bread Batch (+30 XP)
CREATE OR REPLACE FUNCTION public.reserve_fresh_bread_batch(
  p_bakery_slug TEXT,
  p_variety_id TEXT,
  p_loaves_count INTEGER DEFAULT 2
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
  v_user_id UUID := auth.uid();
  v_bakery RECORD;
  v_loaves INTEGER := COALESCE(p_loaves_count, 2);
BEGIN
  IF v_user_id IS NULL THEN
    RETURN jsonb_build_object(
      'success', false,
      'error', 'Authentication required to reserve hot bread batches.'
    );
  END IF;

  -- Validate variety id
  IF p_variety_id NOT IN ('obi_non', 'patir', 'shirmoy', 'jizzali') THEN
    RETURN jsonb_build_object(
      'success', false,
      'error', 'Invalid bread variety selected.'
    );
  END IF;

  -- Validate loaves count
  IF v_loaves < 1 OR v_loaves > 20 THEN
    RETURN jsonb_build_object(
      'success', false,
      'error', 'Loaves count must be between 1 and 20.'
    );
  END IF;

  -- Locate active bakery
  SELECT * INTO v_bakery
  FROM public.tandoor_bakeries
  WHERE slug = LOWER(TRIM(p_bakery_slug)) AND is_published = true;

  IF NOT FOUND THEN
    RETURN jsonb_build_object(
      'success', false,
      'error', 'Tandoor bakery not found or unpublished.'
    );
  END IF;

  -- Insert reservation and decrement current batch hot loaves
  INSERT INTO public.user_bread_reservations (
    user_id, bakery_id, variety_id, loaves_count, xp_awarded, status
  ) VALUES (
    v_user_id, v_bakery.id, p_variety_id, v_loaves, 30, 'confirmed'
  );

  UPDATE public.tandoor_bakeries
  SET current_batch_hot_loaves = GREATEST(0, current_batch_hot_loaves - v_loaves)
  WHERE id = v_bakery.id;

  RETURN jsonb_build_object(
    'success', true,
    'bakery_slug', v_bakery.slug,
    'variety_id', p_variety_id,
    'loaves_count', v_loaves,
    'xp_awarded', 30,
    'remaining_hot_loaves', GREATEST(0, v_bakery.current_batch_hot_loaves - v_loaves)
  );
END;
$$;
