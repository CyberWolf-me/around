-- Migration 00040: Tashkent State Puppet Theater & Marionette Heritage Schema & RPC
-- Enables discovery of Chodir Jamol glove puppetry, Chodir Xayol string marionettes, and ticket reservations (+35 XP).

-- 1. Puppet Theaters & Ateliers Definition Table
CREATE TABLE IF NOT EXISTS public.puppet_theaters (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  slug TEXT UNIQUE NOT NULL CHECK (char_length(trim(slug)) BETWEEN 3 AND 80),
  name TEXT NOT NULL CHECK (char_length(trim(name)) BETWEEN 3 AND 120),
  district TEXT NOT NULL CHECK (char_length(trim(district)) BETWEEN 2 AND 80),
  chief_master TEXT NOT NULL CHECK (char_length(trim(chief_master)) BETWEEN 2 AND 100),
  founded_year INTEGER NOT NULL CHECK (founded_year >= 1800),
  available_seats INTEGER NOT NULL DEFAULT 32 CHECK (available_seats >= 0),
  max_seats INTEGER NOT NULL DEFAULT 64 CHECK (max_seats > 0),
  supported_formats TEXT[] NOT NULL DEFAULT '{}',
  latitude DOUBLE PRECISION NOT NULL,
  longitude DOUBLE PRECISION NOT NULL,
  is_published BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 2. User Puppet Theater Tickets Table
CREATE TABLE IF NOT EXISTS public.user_puppet_tickets (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  theater_id UUID NOT NULL REFERENCES public.puppet_theaters(id) ON DELETE CASCADE,
  performance_id TEXT NOT NULL,
  seats_count INTEGER NOT NULL DEFAULT 1 CHECK (seats_count BETWEEN 1 AND 10),
  xp_awarded INTEGER NOT NULL DEFAULT 35 CHECK (xp_awarded >= 0),
  status TEXT NOT NULL DEFAULT 'confirmed' CHECK (status IN ('confirmed', 'attended', 'cancelled')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Performance Indexes
CREATE INDEX IF NOT EXISTS idx_puppet_theaters_slug ON public.puppet_theaters(slug);
CREATE INDEX IF NOT EXISTS idx_puppet_theaters_district ON public.puppet_theaters(district);
CREATE INDEX IF NOT EXISTS idx_user_puppet_tickets_user ON public.user_puppet_tickets(user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_user_puppet_tickets_theater ON public.user_puppet_tickets(theater_id);

-- Enable Row-Level Security
ALTER TABLE public.puppet_theaters ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_puppet_tickets ENABLE ROW LEVEL SECURITY;

-- Read policy for published theaters
CREATE POLICY "Published puppet theaters readable by all"
  ON public.puppet_theaters
  FOR SELECT
  USING (is_published = true);

-- Dual-layer privacy read policy for user puppet tickets
CREATE POLICY "Puppet tickets readable if user privacy permits"
  ON public.user_puppet_tickets
  FOR SELECT
  USING (
    auth.uid() = user_id
    OR EXISTS (
      SELECT 1 FROM public.profiles p
      WHERE p.id = user_puppet_tickets.user_id
        AND COALESCE(p.hide_visits_history, false) = false
    )
  );

CREATE POLICY "Users can insert their own puppet tickets"
  ON public.user_puppet_tickets
  FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own puppet tickets"
  ON public.user_puppet_tickets
  FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete their own puppet tickets"
  ON public.user_puppet_tickets
  FOR DELETE
  USING (auth.uid() = user_id);

-- Seed Curated Tashkent Puppet Theaters & Ateliers
INSERT INTO public.puppet_theaters (
  id, slug, name, district, chief_master, founded_year, available_seats,
  max_seats, supported_formats, latitude, longitude
) VALUES
(
  'f1000000-0000-0000-0000-000000000001',
  'theater-state-puppet-kosmonavtlar',
  'Uzbekistan State Puppet Theater',
  'Yakkasaray Kosmonavtlar',
  'Usto Mansur Qo''g''irchoqsoz',
  1939,
  48,
  64,
  ARRAY['chodir_jamol', 'chodir_xayol'],
  41.3052,
  69.2618
),
(
  'f1000000-0000-0000-0000-000000000002',
  'atelier-old-city-chodir',
  'Old City Chodir Jamol Master Atelier',
  'Shaykhontohur Chorsu',
  'Usto Ikrom Usta-Qo''g''irchoq',
  1978,
  16,
  24,
  ARRAY['chodir_jamol'],
  41.3268,
  69.2372
),
(
  'f1000000-0000-0000-0000-000000000003',
  'studio-chilonzor-marionette',
  'Chilonzor Silk String Marionette Studio',
  'Chilonzor Quarter 7',
  'Usto Dilshod Marionetkasoz',
  1995,
  24,
  36,
  ARRAY['chodir_xayol'],
  41.2842,
  69.2155
)
ON CONFLICT (slug) DO UPDATE SET
  name = EXCLUDED.name,
  district = EXCLUDED.district,
  chief_master = EXCLUDED.chief_master,
  founded_year = EXCLUDED.founded_year,
  available_seats = EXCLUDED.available_seats,
  max_seats = EXCLUDED.max_seats,
  supported_formats = EXCLUDED.supported_formats,
  latitude = EXCLUDED.latitude,
  longitude = EXCLUDED.longitude;

-- Security Definer RPC for Reserving Puppet Theater Tickets (+35 XP)
CREATE OR REPLACE FUNCTION public.reserve_puppet_theater_ticket(
  p_theater_slug TEXT,
  p_performance_id TEXT,
  p_seats_count INTEGER DEFAULT 1
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
  v_user_id UUID := auth.uid();
  v_theater RECORD;
  v_seats INTEGER := COALESCE(p_seats_count, 1);
BEGIN
  IF v_user_id IS NULL THEN
    RETURN jsonb_build_object(
      'success', false,
      'error', 'Authentication required to reserve puppet theater tickets.'
    );
  END IF;

  -- Validate seats count
  IF v_seats < 1 OR v_seats > 10 THEN
    RETURN jsonb_build_object(
      'success', false,
      'error', 'Seats count must be between 1 and 10.'
    );
  END IF;

  -- Locate active theater
  SELECT * INTO v_theater
  FROM public.puppet_theaters
  WHERE slug = LOWER(TRIM(p_theater_slug)) AND is_published = true;

  IF NOT FOUND THEN
    RETURN jsonb_build_object(
      'success', false,
      'error', 'Puppet theater stage not found or unpublished.'
    );
  END IF;

  -- Check seat availability
  IF v_theater.available_seats < v_seats THEN
    RETURN jsonb_build_object(
      'success', false,
      'error', 'Not enough seats available for this performance.'
    );
  END IF;

  -- Insert ticket reservation and decrement available seats
  INSERT INTO public.user_puppet_tickets (
    user_id, theater_id, performance_id, seats_count, xp_awarded, status
  ) VALUES (
    v_user_id, v_theater.id, p_performance_id, v_seats, 35, 'confirmed'
  );

  UPDATE public.puppet_theaters
  SET available_seats = GREATEST(0, available_seats - v_seats)
  WHERE id = v_theater.id;

  RETURN jsonb_build_object(
    'success', true,
    'theater_slug', v_theater.slug,
    'performance_id', p_performance_id,
    'seats_count', v_seats,
    'xp_awarded', 35,
    'remaining_seats', GREATEST(0, v_theater.available_seats - v_seats)
  );
END;
$$;
