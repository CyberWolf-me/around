-- Migration 00034: District Radio Channels & Field Recording Audio Sessions Schema & RPC
-- Enables explorers to tune into live ambient soundscapes across Tashkent districts with cumulative listening immersion and XP progression.

-- 1. District Radio Channels Definition Table
CREATE TABLE IF NOT EXISTS public.district_radio_channels (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  station_key TEXT UNIQUE NOT NULL CHECK (char_length(trim(station_key)) BETWEEN 3 AND 60),
  callsign TEXT NOT NULL CHECK (char_length(trim(callsign)) BETWEEN 3 AND 30),
  frequency_mhz NUMERIC(4, 1) NOT NULL CHECK (frequency_mhz >= 88.0 AND frequency_mhz <= 108.0),
  title TEXT NOT NULL CHECK (char_length(trim(title)) BETWEEN 3 AND 120),
  district TEXT NOT NULL CHECK (char_length(trim(district)) BETWEEN 2 AND 80),
  genre_description TEXT NOT NULL CHECK (char_length(trim(genre_description)) BETWEEN 5 AND 400),
  accent_color_hex TEXT NOT NULL DEFAULT '#FF4800',
  stream_url TEXT NOT NULL,
  base_listeners INTEGER NOT NULL DEFAULT 100 CHECK (base_listeners >= 0),
  current_track TEXT NOT NULL,
  curator_name TEXT NOT NULL,
  is_active BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 2. User Radio Listening Sessions Table
CREATE TABLE IF NOT EXISTS public.radio_listening_sessions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  station_id UUID NOT NULL REFERENCES public.district_radio_channels(id) ON DELETE CASCADE,
  duration_seconds INTEGER NOT NULL DEFAULT 0 CHECK (duration_seconds >= 0),
  xp_earned INTEGER NOT NULL DEFAULT 0 CHECK (xp_earned >= 0),
  last_tuned_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT unique_user_station_session UNIQUE (user_id, station_id)
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_district_radio_key ON public.district_radio_channels(station_key);
CREATE INDEX IF NOT EXISTS idx_district_radio_freq ON public.district_radio_channels(frequency_mhz);
CREATE INDEX IF NOT EXISTS idx_radio_sessions_user ON public.radio_listening_sessions(user_id, last_tuned_at DESC);
CREATE INDEX IF NOT EXISTS idx_radio_sessions_station ON public.radio_listening_sessions(station_id);

-- Enable Row-Level Security
ALTER TABLE public.district_radio_channels ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.radio_listening_sessions ENABLE ROW LEVEL SECURITY;

-- Read policies for channels
CREATE POLICY "Active district radio channels readable by all"
  ON public.district_radio_channels
  FOR SELECT
  USING (is_active = true);

-- Dual-layer privacy read policy for user listening sessions
CREATE POLICY "Radio listening sessions readable if user privacy permits"
  ON public.radio_listening_sessions
  FOR SELECT
  USING (
    auth.uid() = user_id
    OR EXISTS (
      SELECT 1 FROM public.profiles p
      WHERE p.id = radio_listening_sessions.user_id
        AND COALESCE(p.hide_visits_history, false) = false
    )
  );

CREATE POLICY "Users can insert their own radio sessions"
  ON public.radio_listening_sessions
  FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own radio sessions"
  ON public.radio_listening_sessions
  FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete their own radio sessions"
  ON public.radio_listening_sessions
  FOR DELETE
  USING (auth.uid() = user_id);

-- Seed Initial Curated Tashkent District Radio Stations
INSERT INTO public.district_radio_channels (
  id, station_key, callsign, frequency_mhz, title, district, genre_description, accent_color_hex, stream_url, base_listeners, current_track, curator_name
) VALUES
(
  'e1000000-0000-0000-0000-000000000001',
  'station-chorsu-fm',
  'CHRS 88.4',
  88.4,
  'Old City Chorsu Echoes',
  'Shaykhontohur',
  'Clay ovens, spice merchants & morning adhan reverberation',
  '#2563EB',
  'https://around.tashkent.app/radio/chorsu_ambient.aac',
  340,
  'Kaffal Shashi Courtyard Birds & Copper Chimes',
  'Akrom Chorsui'
),
(
  'e1000000-0000-0000-0000-000000000002',
  'station-mirabad-beat',
  'MRBD 94.2',
  94.2,
  'Mirabad Modern Beat',
  'Mirabad',
  'Specialty espresso hiss, vinyl crackle & evening lo-fi beats',
  '#FF4800',
  'https://around.tashkent.app/radio/mirabad_lofi.aac',
  520,
  'Shevchenko Rain & Ceramic Portafilter Knocks',
  'DJ Rustam Mirabad'
),
(
  'e1000000-0000-0000-0000-000000000003',
  'station-yunusabad-rain',
  'YNSB 101.6',
  101.6,
  'Yunusabad Night Rain',
  'Yunusabad',
  'TV tower wind chimes, nocturnal tram hum & autumn rain',
  '#059669',
  'https://around.tashkent.app/radio/yunusabad_rain.aac',
  290,
  'Amir Timur Avenue Tram Tracks & Deep Drizzle',
  'Nargiza S.'
),
(
  'e1000000-0000-0000-0000-000000000004',
  'station-yakkasaray-breeze',
  'YKKS 107.5',
  107.5,
  'Yakkasaray Park Breeze',
  'Yakkasaray',
  'Ankhor canal water ripple, plane trees & acoustic dombra',
  '#A259FF',
  'https://around.tashkent.app/radio/yakkasaray_breeze.aac',
  215,
  'Ankhor Embankment Twilight & Willow Leaves',
  'Otabek Dombra Master'
)
ON CONFLICT (station_key) DO NOTHING;

-- RPC: Record radio listening session progress and award XP upon 10 minutes immersion
CREATE OR REPLACE FUNCTION public.tune_into_district_radio(
  p_station_key TEXT,
  p_duration_seconds INTEGER DEFAULT 60
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
  v_user_id UUID := auth.uid();
  v_station RECORD;
  v_session RECORD;
  v_new_duration INTEGER;
  v_xp_awarded_now INTEGER := 0;
  v_total_xp INTEGER := 0;
BEGIN
  IF v_user_id IS NULL THEN
    RETURN jsonb_build_object(
      'success', false,
      'error', 'Authentication required to log radio listening sessions.'
    );
  END IF;

  -- Locate active station
  SELECT * INTO v_station
  FROM public.district_radio_channels
  WHERE station_key = LOWER(TRIM(p_station_key)) AND is_active = true;

  IF NOT FOUND THEN
    RETURN jsonb_build_object(
      'success', false,
      'error', 'District radio channel not found or inactive.'
    );
  END IF;

  -- Check existing session
  SELECT * INTO v_session
  FROM public.radio_listening_sessions
  WHERE user_id = v_user_id AND station_id = v_station.id;

  IF FOUND THEN
    v_new_duration := v_session.duration_seconds + GREATEST(0, p_duration_seconds);
    v_total_xp := v_session.xp_earned;

    -- Award +25 XP if threshold reached and not yet awarded
    IF v_new_duration >= 600 AND v_total_xp = 0 THEN
      v_xp_awarded_now := 25;
      v_total_xp := 25;
    END IF;

    UPDATE public.radio_listening_sessions
    SET duration_seconds = v_new_duration,
        xp_earned = v_total_xp,
        last_tuned_at = NOW()
    WHERE id = v_session.id;
  ELSE
    v_new_duration := GREATEST(0, p_duration_seconds);

    IF v_new_duration >= 600 THEN
      v_xp_awarded_now := 25;
      v_total_xp := 25;
    END IF;

    INSERT INTO public.radio_listening_sessions (
      user_id, station_id, duration_seconds, xp_earned, last_tuned_at
    ) VALUES (
      v_user_id, v_station.id, v_new_duration, v_total_xp, NOW()
    );
  END IF;

  RETURN jsonb_build_object(
    'success', true,
    'station_key', v_station.station_key,
    'callsign', v_station.callsign,
    'duration_seconds', v_new_duration,
    'xp_awarded_now', v_xp_awarded_now,
    'total_xp_earned', v_total_xp,
    'immersion_achieved', (v_new_duration >= 600)
  );
END;
$$;
