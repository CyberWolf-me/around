-- Migration 00037: Tashkent Metro Station Architecture & Ceramic Mosaics Guide Schema & RPC
-- Enables discovery of underground subway architectural heritage, ceramic smalt mosaics, and digital exploration stamps (+30 XP).

-- 1. Metro Stations Definition Table
CREATE TABLE IF NOT EXISTS public.metro_stations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  station_key TEXT UNIQUE NOT NULL CHECK (char_length(trim(station_key)) BETWEEN 3 AND 60),
  name_uz TEXT NOT NULL CHECK (char_length(trim(name_uz)) BETWEEN 2 AND 100),
  name_ru TEXT NOT NULL CHECK (char_length(trim(name_ru)) BETWEEN 2 AND 100),
  name_en TEXT NOT NULL CHECK (char_length(trim(name_en)) BETWEEN 2 AND 100),
  line_id TEXT NOT NULL CHECK (line_id IN ('chilanzar', 'uzbekistan', 'yunusabad', 'circle')),
  opening_year INTEGER NOT NULL CHECK (opening_year >= 1970),
  architect TEXT NOT NULL CHECK (char_length(trim(architect)) BETWEEN 2 AND 120),
  mosaic_artist TEXT NOT NULL CHECK (char_length(trim(mosaic_artist)) BETWEEN 2 AND 120),
  architectural_style TEXT NOT NULL CHECK (char_length(trim(architectural_style)) BETWEEN 3 AND 160),
  mosaic_description TEXT NOT NULL,
  marble_pillars TEXT NOT NULL,
  lighting_style TEXT NOT NULL,
  audio_guide_track_url TEXT NOT NULL DEFAULT '',
  audio_guide_snippet_uz TEXT NOT NULL DEFAULT '',
  audio_guide_snippet_ru TEXT NOT NULL DEFAULT '',
  audio_guide_snippet_en TEXT NOT NULL DEFAULT '',
  latitude DOUBLE PRECISION NOT NULL,
  longitude DOUBLE PRECISION NOT NULL,
  stamp_points INTEGER NOT NULL DEFAULT 30 CHECK (stamp_points > 0),
  is_active BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 2. User Metro Mosaic Stamps Table
CREATE TABLE IF NOT EXISTS public.metro_mosaic_stamps (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  station_id UUID NOT NULL REFERENCES public.metro_stations(id) ON DELETE CASCADE,
  notes TEXT,
  photo_proof_url TEXT,
  points_awarded INTEGER NOT NULL DEFAULT 30 CHECK (points_awarded >= 0),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT unique_user_station_stamp UNIQUE (user_id, station_id)
);

-- Performance Indexes
CREATE INDEX IF NOT EXISTS idx_metro_stations_key ON public.metro_stations(station_key);
CREATE INDEX IF NOT EXISTS idx_metro_stations_line ON public.metro_stations(line_id);
CREATE INDEX IF NOT EXISTS idx_metro_stamps_user ON public.metro_mosaic_stamps(user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_metro_stamps_station ON public.metro_mosaic_stamps(station_id);

-- Enable Row-Level Security
ALTER TABLE public.metro_stations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.metro_mosaic_stamps ENABLE ROW LEVEL SECURITY;

-- Read policy for active metro stations
CREATE POLICY "Active metro stations readable by all"
  ON public.metro_stations
  FOR SELECT
  USING (is_active = true);

-- Dual-layer privacy read policy for user metro stamps
CREATE POLICY "Metro stamps readable if user privacy permits"
  ON public.metro_mosaic_stamps
  FOR SELECT
  USING (
    auth.uid() = user_id
    OR EXISTS (
      SELECT 1 FROM public.profiles p
      WHERE p.id = metro_mosaic_stamps.user_id
        AND COALESCE(p.hide_visits_history, false) = false
    )
  );

CREATE POLICY "Users can insert their own stamps"
  ON public.metro_mosaic_stamps
  FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own stamps"
  ON public.metro_mosaic_stamps
  FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete their own stamps"
  ON public.metro_mosaic_stamps
  FOR DELETE
  USING (auth.uid() = user_id);

-- Seed Initial Curated Tashkent Metro Stations
INSERT INTO public.metro_stations (
  id, station_key, name_uz, name_ru, name_en, line_id, opening_year, architect, mosaic_artist,
  architectural_style, mosaic_description, marble_pillars, lighting_style,
  audio_guide_track_url, audio_guide_snippet_uz, audio_guide_snippet_ru, audio_guide_snippet_en,
  latitude, longitude, stamp_points
) VALUES
(
  'c1000000-0000-0000-0000-000000000001',
  'kosmonavtlar',
  'Kosmonavtlar',
  'Космонавтов',
  'Cosmonauts',
  'uzbekistan',
  1984,
  'S. Sultonov',
  'Arnold Gan',
  'Cosmic Soviet Futurism & Ceramic Medallions',
  'Deep midnight-blue to black ceramic gradient walls echoing atmospheric entry, with ceramic medallions honoring Yuri Gagarin, Valentina Tereshkova, and astronomer Mirzo Ulugbek.',
  'Deep blue-grey granite and ribbed cylindrical columns',
  'Illuminated floating glass orb chandeliers resembling the Milky Way galaxy',
  'https://cdn.around.uz/audio/metro/kosmonavtlar_en.mp3',
  'Kosmonavtlar bekati - koinotga sayohat hissini uyg''otuvchi keramika ustalari Gan va Sultonov asari.',
  'Станция Космонавтов — погружение в открытый космос с медальонами Гагарина и Улугбека.',
  'Cosmonauts Station evokes a descent into deep cosmos with gradient cerulean tiles and astronomical medallions.',
  41.3094,
  69.2625,
  30
),
(
  'c1000000-0000-0000-0000-000000000002',
  'alisher_navoiy',
  'Alisher Navoiy',
  'Алишера Навои',
  'Alisher Navoi',
  'uzbekistan',
  1984,
  'R. Fayzullayev',
  'Chinghiz Akhmarov',
  'Timurid Vaulted Blue Cupolas & Epic Poem Frescoes',
  'Intricate vaulted cupolas inspired by Samarkand madrasahs, featuring majolica blue medallions illustrating scenes from Navoi''s legendary Khamsa epic.',
  'White Kyzylkum marble arches and octagonal stalactite capitals',
  'Chiseled brass hanging mosque-style chandeliers casting lace shadows',
  'https://cdn.around.uz/audio/metro/alisher_navoiy_en.mp3',
  'Alisher Navoiy bekati Temuriylar me''morchiligi va Xamsa dostonining eng nafis tasvirlariga ega.',
  'Станция Алишера Навои — шедевр восточной архитектуры с куполами и панно по мотивам Хамсы.',
  'Alisher Navoi Station presents vaulted turquoise cupolas depicting five legendary tales from the Khamsa epic.',
  41.3197,
  69.2558,
  30
),
(
  'c1000000-0000-0000-0000-000000000003',
  'pakhtakor',
  'Paxtakor',
  'Пахтакор',
  'Pakhtakor',
  'chilanzar',
  1977,
  'A. Tabibov',
  'V. Burmakin',
  'Ceramic Cotton Blossom Majolica & Smalt Arabesques',
  'Dynamic flowing mosaics made of Tashkent smalt and glazed ceramics portraying blooming cotton bolls and solar swirls in jade, cobalt, and golden ochre.',
  'Gazgan pink and white marble fluted columns',
  'Recessed geometric luminaire coffers embedded in the coffered ceiling',
  'https://cdn.around.uz/audio/metro/pakhtakor_en.mp3',
  'Paxtakor bekati 1977 yilda ochilgan bo''lib, paxta gullari va quyosh nurlarining smalta mozaikasi bilan mashhur.',
  'Станция Пахтакор украшена яркой смальтовой мозаикой цветущего хлопчатника и солнца.',
  'Pakhtakor Station is celebrated for its radiant smalt mosaics weaving cotton blossoms and solar arabesques.',
  41.3189,
  69.2562,
  30
),
(
  'c1000000-0000-0000-0000-000000000004',
  'mustaqillik_maydoni',
  'Mustaqillik Maydoni',
  'Площадь Независимости',
  'Independence Square',
  'chilanzar',
  1977,
  'L. Adamov',
  'Uzbekistan National Studio',
  'Neoclassical Ceremonial Marble & Crystal Chandeliers',
  'Polished Gazgan marble halls with geometric star marquetry floors and luminous alabaster cornices symbolizing independence and celebration.',
  'Fluted white Gazgan marble pillars topped with gilded capital leaves',
  'Massive tiered crystal chandeliers evoking celebratory ceremonial palace halls',
  'https://cdn.around.uz/audio/metro/mustaqillik_en.mp3',
  'Mustaqillik Maydoni bekati o''zining hashamatli marmar ustunlari va billur qandillari bilan ajralib turadi.',
  'Станция Мустакиллик Майдони — величественный белый мрамор и хрустальные дворцовые люстры.',
  'Independence Square Station features ceremonial white marble colonnades and tiered crystal chandeliers.',
  41.3167,
  69.2685,
  30
),
(
  'c1000000-0000-0000-0000-000000000005',
  'bodomzor',
  'Bodomzor',
  'Бадамзар',
  'Bodomzor',
  'yunusabad',
  2001,
  'A. Adylov',
  'Usto R. Tokhtayev',
  'Modernist Ceramic Filigree & Almond Blossom Lanterns',
  'Geometric ceramic relief friezes reflecting almond trees (bodom), paired with undulating ceiling plasterwork and stylized branch motifs.',
  'Curved light Nurata marble benches and circular central pedestals',
  'Pod-like sculptural almond-shaped frosted acrylic luminaires',
  'https://cdn.around.uz/audio/metro/bodomzor_en.mp3',
  'Bodomzor bekati bodom gullari shaklidagi zamonaviy yoritgichlari va nafis keramikasi bilan ajralib turadi.',
  'Станция Бодомзор известна оригинальными светильниками в форме миндаля и бирюзовым декором.',
  'Bodomzor Station features sculptural almond-shaped light pods and delicate ceramic relief patterns.',
  41.3417,
  69.2842,
  30
),
(
  'c1000000-0000-0000-0000-000000000006',
  'beruniy',
  'Beruniy',
  'Беруни',
  'Beruniy',
  'uzbekistan',
  1991,
  'S. Sultonov',
  'A. Rakhmatullaev',
  'High Geometric Domes & Astrolabe Reliefs',
  'Massive spherical tiled cupolas echoing Abu Rayhan al-Biruni''s spherical trigonometry, adorned with bronze astrolabe emblems and astronomical constellations.',
  'Polished grey marble arches with interlocking Islamic geometric friezes',
  'Concentric ring luminaires representing planetary orbits',
  'https://cdn.around.uz/audio/metro/beruniy_en.mp3',
  'Beruniy bekati buyuk allomaning falakiyot va matematika kashfiyotlariga bag''ishlangan gumbazlarga ega.',
  'Станция Беруни — планетарные своды и астролябии в честь великого средневекового энциклопедиста.',
  'Beruniy Station honors the polymath Al-Biruni with astronomical domes and planetary orbit chandeliers.',
  41.3444,
  69.2065,
  30
)
ON CONFLICT (station_key) DO UPDATE SET
  name_uz = EXCLUDED.name_uz,
  name_ru = EXCLUDED.name_ru,
  name_en = EXCLUDED.name_en,
  line_id = EXCLUDED.line_id,
  architectural_style = EXCLUDED.architectural_style,
  mosaic_description = EXCLUDED.mosaic_description,
  stamp_points = EXCLUDED.stamp_points;

-- RPC: Collect Station Ceramic Mosaic Digital Exploration Stamp (+30 XP)
CREATE OR REPLACE FUNCTION public.collect_metro_mosaic_stamp(
  p_station_key TEXT,
  p_notes TEXT DEFAULT NULL,
  p_photo_proof_url TEXT DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
  v_user_id UUID := auth.uid();
  v_station RECORD;
  v_existing RECORD;
BEGIN
  IF v_user_id IS NULL THEN
    RETURN jsonb_build_object(
      'success', false,
      'error', 'Authentication required to collect metro mosaic stamps.'
    );
  END IF;

  -- Locate active station
  SELECT * INTO v_station
  FROM public.metro_stations
  WHERE station_key = LOWER(TRIM(p_station_key)) AND is_active = true;

  IF NOT FOUND THEN
    RETURN jsonb_build_object(
      'success', false,
      'error', 'Metro station not found or inactive.'
    );
  END IF;

  -- Check existing stamp
  SELECT * INTO v_existing
  FROM public.metro_mosaic_stamps
  WHERE user_id = v_user_id AND station_id = v_station.id;

  IF FOUND THEN
    RETURN jsonb_build_object(
      'success', true,
      'already_stamped', true,
      'station_key', v_station.station_key,
      'points_awarded', v_existing.points_awarded,
      'created_at', v_existing.created_at
    );
  END IF;

  -- Insert stamp record
  INSERT INTO public.metro_mosaic_stamps (
    user_id, station_id, notes, photo_proof_url, points_awarded
  ) VALUES (
    v_user_id, v_station.id, TRIM(p_notes), TRIM(p_photo_proof_url), v_station.stamp_points
  );

  RETURN jsonb_build_object(
    'success', true,
    'already_stamped', false,
    'station_key', v_station.station_key,
    'points_awarded', v_station.stamp_points,
    'created_at', NOW()
  );
END;
$$;
