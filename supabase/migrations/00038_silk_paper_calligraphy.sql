-- Migration 00038: Tashkent Mulberry Silk Paper & Calligraphy Manuscript Ateliers Schema & RPC
-- Enables discovery of 1,200-year mulberry silk paper craftsmanship, agate stone burnishing, and calligraphy masterclass reservations (+35 XP).

-- 1. Silk Paper Ateliers Definition Table
CREATE TABLE IF NOT EXISTS public.silk_paper_ateliers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  slug TEXT UNIQUE NOT NULL CHECK (char_length(trim(slug)) BETWEEN 3 AND 80),
  name TEXT NOT NULL CHECK (char_length(trim(name)) BETWEEN 3 AND 120),
  district TEXT NOT NULL CHECK (char_length(trim(district)) BETWEEN 2 AND 80),
  master_name TEXT NOT NULL CHECK (char_length(trim(master_name)) BETWEEN 2 AND 100),
  century_tradition TEXT NOT NULL,
  mulberry_variety TEXT NOT NULL,
  burnish_stone_type TEXT NOT NULL,
  supported_scripts TEXT[] NOT NULL DEFAULT '{}',
  workshop_price_uzs INTEGER NOT NULL DEFAULT 150000 CHECK (workshop_price_uzs > 0),
  available_seats INTEGER NOT NULL DEFAULT 4 CHECK (available_seats >= 0),
  max_seats INTEGER NOT NULL DEFAULT 8 CHECK (max_seats > 0),
  latitude DOUBLE PRECISION NOT NULL,
  longitude DOUBLE PRECISION NOT NULL,
  is_published BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 2. User Silk Paper Workshop Reservations Table
CREATE TABLE IF NOT EXISTS public.user_silk_paper_workshops (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  atelier_id UUID NOT NULL REFERENCES public.silk_paper_ateliers(id) ON DELETE CASCADE,
  script_id TEXT NOT NULL CHECK (script_id IN ('nastaliq', 'thuluth', 'kufic', 'diwani')),
  xp_awarded INTEGER NOT NULL DEFAULT 35 CHECK (xp_awarded >= 0),
  status TEXT NOT NULL DEFAULT 'confirmed' CHECK (status IN ('confirmed', 'completed', 'cancelled')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT unique_user_paper_workshop UNIQUE (user_id, atelier_id)
);

-- Performance Indexes
CREATE INDEX IF NOT EXISTS idx_silk_ateliers_slug ON public.silk_paper_ateliers(slug);
CREATE INDEX IF NOT EXISTS idx_silk_ateliers_district ON public.silk_paper_ateliers(district);
CREATE INDEX IF NOT EXISTS idx_user_paper_workshops_user ON public.user_silk_paper_workshops(user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_user_paper_workshops_atelier ON public.user_silk_paper_workshops(atelier_id);

-- Enable Row-Level Security
ALTER TABLE public.silk_paper_ateliers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_silk_paper_workshops ENABLE ROW LEVEL SECURITY;

-- Read policy for published ateliers
CREATE POLICY "Published silk paper ateliers readable by all"
  ON public.silk_paper_ateliers
  FOR SELECT
  USING (is_published = true);

-- Dual-layer privacy read policy for user workshop reservations
CREATE POLICY "Silk paper workshops readable if user privacy permits"
  ON public.user_silk_paper_workshops
  FOR SELECT
  USING (
    auth.uid() = user_id
    OR EXISTS (
      SELECT 1 FROM public.profiles p
      WHERE p.id = user_silk_paper_workshops.user_id
        AND COALESCE(p.hide_visits_history, false) = false
    )
  );

CREATE POLICY "Users can insert their own workshop reservations"
  ON public.user_silk_paper_workshops
  FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own workshop reservations"
  ON public.user_silk_paper_workshops
  FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete their own workshop reservations"
  ON public.user_silk_paper_workshops
  FOR DELETE
  USING (auth.uid() = user_id);

-- Seed Curated Tashkent Silk Paper Ateliers
INSERT INTO public.silk_paper_ateliers (
  id, slug, name, district, master_name, century_tradition, mulberry_variety, burnish_stone_type,
  supported_scripts, workshop_price_uzs, available_seats, max_seats, latitude, longitude
) VALUES
(
  'd1000000-0000-0000-0000-000000000001',
  'atelier-chorsu-mulberry',
  'Chorsu Silk Paper & Manuscript Guild',
  'Old City Shaykhontohur',
  'Usto Mirzo Bobo Qog''ozchi',
  '10th Century Samarkand-Tashkent Silk Paper Legacy',
  'White Mulberry (Morus Alba) Inner Phloem',
  'Kyzylkum Red Agate Stone (Aqiq)',
  ARRAY['nastaliq', 'thuluth', 'kufic'],
  150000,
  4,
  8,
  41.3275,
  69.2389
),
(
  'd1000000-0000-0000-0000-000000000002',
  'atelier-hast-imam-calligraphy',
  'Hast Imam Holy Scripture & Vellum Atelier',
  'Almazar',
  'Usto Abdulaziz Mansur Calligrapher',
  'Imperial Quranic Illumination & Gold Leaf Scribing',
  'Black Mulberry (Morus Nigra) High-Cellulose Bark',
  'Mountain Chalcedony & Horn Burnisher',
  ARRAY['thuluth', 'kufic', 'diwani'],
  180000,
  2,
  6,
  41.3364,
  69.2415
),
(
  'd1000000-0000-0000-0000-000000000003',
  'atelier-navoiy-literature',
  'Navoiy Literary Manuscript & Diwani Atelier',
  'Mirabad',
  'Usto Dilshodbek Khattot',
  'Timurid Renaissance Divan & Nastaliq Miniature Scrolls',
  'Wild Pskem River Mulberry Fibers',
  'Polished Riverbed Jasper & Sea Shell',
  ARRAY['nastaliq', 'diwani'],
  140000,
  5,
  10,
  41.3052,
  69.2741
)
ON CONFLICT (slug) DO UPDATE SET
  name = EXCLUDED.name,
  district = EXCLUDED.district,
  master_name = EXCLUDED.master_name,
  supported_scripts = EXCLUDED.supported_scripts,
  workshop_price_uzs = EXCLUDED.workshop_price_uzs,
  available_seats = EXCLUDED.available_seats;

-- RPC: Reserve Silk Paper Masterclass Seat (+35 XP)
CREATE OR REPLACE FUNCTION public.reserve_silk_paper_workshop(
  p_atelier_slug TEXT,
  p_script_id TEXT DEFAULT 'nastaliq'
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
  v_user_id UUID := auth.uid();
  v_atelier RECORD;
  v_existing RECORD;
BEGIN
  IF v_user_id IS NULL THEN
    RETURN jsonb_build_object(
      'success', false,
      'error', 'Authentication required to reserve silk paper workshops.'
    );
  END IF;

  -- Validate script id
  IF p_script_id NOT IN ('nastaliq', 'thuluth', 'kufic', 'diwani') THEN
    RETURN jsonb_build_object(
      'success', false,
      'error', 'Invalid calligraphy script selected.'
    );
  END IF;

  -- Locate active atelier
  SELECT * INTO v_atelier
  FROM public.silk_paper_ateliers
  WHERE slug = LOWER(TRIM(p_atelier_slug)) AND is_published = true;

  IF NOT FOUND THEN
    RETURN jsonb_build_object(
      'success', false,
      'error', 'Silk paper atelier not found or unpublished.'
    );
  END IF;

  -- Check existing reservation
  SELECT * INTO v_existing
  FROM public.user_silk_paper_workshops
  WHERE user_id = v_user_id AND atelier_id = v_atelier.id;

  IF FOUND THEN
    RETURN jsonb_build_object(
      'success', true,
      'already_reserved', true,
      'atelier_slug', v_atelier.slug,
      'script_id', v_existing.script_id,
      'xp_awarded', v_existing.xp_awarded,
      'available_seats', v_atelier.available_seats
    );
  END IF;

  -- Check seat availability
  IF v_atelier.available_seats <= 0 THEN
    RETURN jsonb_build_object(
      'success', false,
      'error', 'All seats at this silk paper masterclass are fully booked.'
    );
  END IF;

  -- Insert reservation and decrement available seats
  INSERT INTO public.user_silk_paper_workshops (
    user_id, atelier_id, script_id, xp_awarded, status
  ) VALUES (
    v_user_id, v_atelier.id, p_script_id, 35, 'confirmed'
  );

  UPDATE public.silk_paper_ateliers
  SET available_seats = GREATEST(0, available_seats - 1)
  WHERE id = v_atelier.id;

  RETURN jsonb_build_object(
    'success', true,
    'already_reserved', false,
    'atelier_slug', v_atelier.slug,
    'script_id', p_script_id,
    'xp_awarded', 35,
    'available_seats', (v_atelier.available_seats - 1)
  );
END;
$$;
