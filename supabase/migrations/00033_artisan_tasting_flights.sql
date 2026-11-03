-- Migration 00033: Artisan Tasting Flights & Cupping Certificates Schema & RPC
-- Enables explorers to sample curated sensory flights (third-wave coffee, Silk Road tea, bazaar spices) and log cupping scores across Tashkent.

-- 1. Tasting Flights Definition Table
CREATE TABLE IF NOT EXISTS public.tasting_flights (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  slug TEXT UNIQUE NOT NULL CHECK (char_length(trim(slug)) BETWEEN 3 AND 80),
  title TEXT NOT NULL CHECK (char_length(trim(title)) BETWEEN 3 AND 120),
  curator_title TEXT NOT NULL CHECK (char_length(trim(curator_title)) BETWEEN 3 AND 100),
  description TEXT NOT NULL CHECK (char_length(trim(description)) BETWEEN 10 AND 500),
  category TEXT NOT NULL DEFAULT 'Coffee' CHECK (category IN ('Coffee', 'Tea', 'Spice', 'Craft')),
  flight_icon TEXT NOT NULL DEFAULT 'cup.and.saucer',
  accent_color_hex TEXT NOT NULL DEFAULT '#A259FF',
  required_stops_count INTEGER NOT NULL DEFAULT 3 CHECK (required_stops_count > 0),
  xp_reward INTEGER NOT NULL DEFAULT 50 CHECK (xp_reward >= 0),
  is_published BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 2. Tasting Flight Stops Table
CREATE TABLE IF NOT EXISTS public.tasting_flight_stops (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  flight_id UUID NOT NULL REFERENCES public.tasting_flights(id) ON DELETE CASCADE,
  stop_key TEXT NOT NULL CHECK (char_length(trim(stop_key)) BETWEEN 2 AND 80),
  place_id UUID REFERENCES public.places(id) ON DELETE SET NULL,
  venue_name TEXT NOT NULL CHECK (char_length(trim(venue_name)) BETWEEN 2 AND 120),
  district TEXT NOT NULL CHECK (char_length(trim(district)) BETWEEN 2 AND 80),
  item_title TEXT NOT NULL CHECK (char_length(trim(item_title)) BETWEEN 2 AND 120),
  flavor_notes TEXT[] NOT NULL DEFAULT '{}',
  origin_story TEXT NOT NULL CHECK (char_length(trim(origin_story)) BETWEEN 5 AND 600),
  suggested_serving_temp TEXT,
  latitude DOUBLE PRECISION NOT NULL,
  longitude DOUBLE PRECISION NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT unique_flight_stop UNIQUE (flight_id, stop_key)
);

-- 3. User Tasting Logs Table
CREATE TABLE IF NOT EXISTS public.user_tasting_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  flight_id UUID NOT NULL REFERENCES public.tasting_flights(id) ON DELETE CASCADE,
  stop_key TEXT NOT NULL CHECK (char_length(trim(stop_key)) BETWEEN 2 AND 80),
  place_id UUID REFERENCES public.places(id) ON DELETE SET NULL,
  rating NUMERIC(3, 1) NOT NULL CHECK (rating >= 1.0 AND rating <= 10.0),
  flavor_notes TEXT[] NOT NULL DEFAULT '{}',
  tasting_notes TEXT,
  logged_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT unique_user_tasting_stop UNIQUE (user_id, flight_id, stop_key)
);

-- 4. User Cupping Certificates Table
CREATE TABLE IF NOT EXISTS public.user_tasting_certificates (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  flight_id UUID NOT NULL REFERENCES public.tasting_flights(id) ON DELETE CASCADE,
  curator_title TEXT NOT NULL,
  average_score NUMERIC(3, 1) NOT NULL,
  xp_awarded INTEGER NOT NULL DEFAULT 50 CHECK (xp_awarded >= 0),
  awarded_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT unique_user_flight_cert UNIQUE (user_id, flight_id)
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_tasting_flights_slug ON public.tasting_flights(slug);
CREATE INDEX IF NOT EXISTS idx_tasting_stops_flight ON public.tasting_flight_stops(flight_id);
CREATE INDEX IF NOT EXISTS idx_user_tasting_logs_user ON public.user_tasting_logs(user_id, flight_id);
CREATE INDEX IF NOT EXISTS idx_user_tasting_certs_user ON public.user_tasting_certificates(user_id, awarded_at DESC);

-- Enable Row-Level Security
ALTER TABLE public.tasting_flights ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tasting_flight_stops ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_tasting_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_tasting_certificates ENABLE ROW LEVEL SECURITY;

-- Read policies for public flights
CREATE POLICY "Published tasting flights readable by all"
  ON public.tasting_flights
  FOR SELECT
  USING (is_published = true);

CREATE POLICY "Tasting stops readable by all"
  ON public.tasting_flight_stops
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.tasting_flights f
      WHERE f.id = tasting_flight_stops.flight_id
        AND f.is_published = true
    )
  );

-- Dual-layer privacy read policy for user logs
CREATE POLICY "Tasting logs readable if user privacy permits"
  ON public.user_tasting_logs
  FOR SELECT
  USING (
    auth.uid() = user_id
    OR EXISTS (
      SELECT 1 FROM public.profiles p
      WHERE p.id = user_tasting_logs.user_id
        AND COALESCE(p.hide_visits_history, false) = false
    )
  );

CREATE POLICY "Users can insert their own tasting logs"
  ON public.user_tasting_logs
  FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete their own tasting logs"
  ON public.user_tasting_logs
  FOR DELETE
  USING (auth.uid() = user_id);

-- Dual-layer privacy read policy for certificates
CREATE POLICY "Tasting certificates readable if user privacy permits"
  ON public.user_tasting_certificates
  FOR SELECT
  USING (
    auth.uid() = user_id
    OR EXISTS (
      SELECT 1 FROM public.profiles p
      WHERE p.id = user_tasting_certificates.user_id
        AND COALESCE(p.hide_visits_history, false) = false
    )
  );

CREATE POLICY "Users can only insert certificates for themselves"
  ON public.user_tasting_certificates
  FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Seed Initial Curated Tasting Flights
INSERT INTO public.tasting_flights (
  id, slug, title, curator_title, description, category, flight_icon, accent_color_hex, required_stops_count, xp_reward
) VALUES
(
  'f1000000-0000-0000-0000-000000000001',
  'tashkent-specialty-coffee-flight',
  'Tashkent Third-Wave Roastery Flight',
  'Specialty Coffee Cupping Certificate',
  'Taste through single-origin Ethiopian naturals, anaerobic fermentations, and silky flat whites crafted by Tashkent micro-roasters.',
  'Coffee',
  'cup.and.saucer',
  '#A259FF',
  3,
  50
),
(
  'f1000000-0000-0000-0000-000000000002',
  'tashkent-tea-master-trail',
  'Silk Road Chaykhana & Saffron Tea Trail',
  'Chaykhana Sommelier Laurels',
  'Experience timeless Uzbek tea hospitality in hand-painted Rishtan ceramic pialahs across Old City mahallas.',
  'Tea',
  'leaf',
  '#00D2FC',
  2,
  50
)
ON CONFLICT (slug) DO NOTHING;

-- Seed Stops for Coffee Flight
INSERT INTO public.tasting_flight_stops (
  flight_id, stop_key, venue_name, district, item_title, flavor_notes, origin_story, suggested_serving_temp, latitude, longitude
) VALUES
(
  'f1000000-0000-0000-0000-000000000001',
  'breadly-cupping',
  'Breadly Bakery & Roastery',
  'Mirabad',
  'Ethiopia Sidama Natural Pour-Over',
  ARRAY['Bergamot', 'Dried Peach', 'Wild Jasmine'],
  'Slow-drip V60 extracted at 92°C highlighting high-altitude floral aromatics.',
  '92°C V60',
  41.3005,
  69.2731
),
(
  'f1000000-0000-0000-0000-000000000001',
  'bb-anaerobic',
  'B&B Coffee House',
  'Yakkasaray',
  'Colombia Anaerobic Filter & Flat White',
  ARRAY['Red Currant', 'Dark Cacao', 'Brown Sugar'],
  '72-hour extended maceration yielding deep winey sweetness and velvety crema.',
  'Aeropress / 65°C Microfoam',
  41.2912,
  69.2554
),
(
  'f1000000-0000-0000-0000-000000000001',
  'paul-bistro',
  'Paul Bakery & Bistro',
  'Mirabad',
  'Guatemala Huehuetenango Cortado',
  ARRAY['Roasted Hazelnut', 'Toffee', 'Orange Zest'],
  'Classic medium roast balanced with steamed alpine whole milk.',
  'Double Shot Cortado',
  41.3112,
  69.2810
)
ON CONFLICT (flight_id, stop_key) DO NOTHING;

-- RPC: Record a tasting cupping score and award certificate upon completion
CREATE OR REPLACE FUNCTION public.record_tasting_flight_cupping(
  p_flight_slug TEXT,
  p_stop_key TEXT,
  p_rating NUMERIC,
  p_flavor_notes TEXT[] DEFAULT '{}',
  p_tasting_notes TEXT DEFAULT NULL,
  p_place_id UUID DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
  v_user_id UUID := auth.uid();
  v_flight RECORD;
  v_stop RECORD;
  v_completed_count INTEGER;
  v_avg_rating NUMERIC(3, 1);
  v_cert_already_awarded BOOLEAN;
  v_cert_awarded_now BOOLEAN := false;
BEGIN
  IF v_user_id IS NULL THEN
    RETURN jsonb_build_object(
      'success', false,
      'error', 'Authentication required to log tasting cupping scores.'
    );
  END IF;

  -- Locate flight
  SELECT * INTO v_flight
  FROM public.tasting_flights
  WHERE slug = LOWER(TRIM(p_flight_slug)) AND is_published = true;

  IF NOT FOUND THEN
    RETURN jsonb_build_object(
      'success', false,
      'error', 'Tasting flight not found or unpublished.'
    );
  END IF;

  -- Locate stop
  SELECT * INTO v_stop
  FROM public.tasting_flight_stops
  WHERE flight_id = v_flight.id AND stop_key = LOWER(TRIM(p_stop_key));

  IF NOT FOUND THEN
    RETURN jsonb_build_object(
      'success', false,
      'error', 'Tasting flight stop not found.'
    );
  END IF;

  -- Upsert tasting log
  INSERT INTO public.user_tasting_logs (
    user_id, flight_id, stop_key, place_id, rating, flavor_notes, tasting_notes
  ) VALUES (
    v_user_id, v_flight.id, v_stop.stop_key, COALESCE(p_place_id, v_stop.place_id), p_rating, p_flavor_notes, p_tasting_notes
  )
  ON CONFLICT (user_id, flight_id, stop_key) DO UPDATE SET
    rating = EXCLUDED.rating,
    flavor_notes = EXCLUDED.flavor_notes,
    tasting_notes = EXCLUDED.tasting_notes,
    logged_at = NOW();

  -- Calculate flight completion and average score
  SELECT COUNT(*), ROUND(AVG(rating), 1)
  INTO v_completed_count, v_avg_rating
  FROM public.user_tasting_logs
  WHERE user_id = v_user_id AND flight_id = v_flight.id;

  -- Check if certificate already exists
  SELECT EXISTS (
    SELECT 1 FROM public.user_tasting_certificates
    WHERE user_id = v_user_id AND flight_id = v_flight.id
  ) INTO v_cert_already_awarded;

  -- If required stops count reached, award certificate
  IF v_completed_count >= v_flight.required_stops_count AND NOT v_cert_already_awarded THEN
    INSERT INTO public.user_tasting_certificates (
      user_id, flight_id, curator_title, average_score, xp_awarded
    ) VALUES (
      v_user_id, v_flight.id, v_flight.curator_title, COALESCE(v_avg_rating, p_rating), v_flight.xp_reward
    );

    v_cert_awarded_now := true;
  END IF;

  RETURN jsonb_build_object(
    'success', true,
    'flight_slug', v_flight.slug,
    'stop_key', v_stop.stop_key,
    'completed_count', v_completed_count,
    'required_stops', v_flight.required_stops_count,
    'average_score', v_avg_rating,
    'is_completed', (v_completed_count >= v_flight.required_stops_count),
    'certificate_awarded_now', v_cert_awarded_now,
    'curator_title', v_flight.curator_title,
    'xp_awarded', CASE WHEN v_cert_awarded_now THEN v_flight.xp_reward ELSE 0 END
  );
END;
$$;
