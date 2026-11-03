-- Migration 00035: Traditional Tashkent Craft Workshops & Masterclasses Schema & RPC
-- Enables explorers to discover heritage artisan ateliers (Rishtan ceramics, walnut woodcarving, suzani silk, copper chasing) and book hands-on masterclasses.

-- 1. Craft Workshops Definition Table
CREATE TABLE IF NOT EXISTS public.craft_workshops (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  slug TEXT UNIQUE NOT NULL CHECK (char_length(trim(slug)) BETWEEN 3 AND 80),
  title TEXT NOT NULL CHECK (char_length(trim(title)) BETWEEN 3 AND 120),
  district TEXT NOT NULL CHECK (char_length(trim(district)) BETWEEN 2 AND 80),
  craft_discipline TEXT NOT NULL CHECK (char_length(trim(craft_discipline)) BETWEEN 2 AND 50),
  master_artisan_name TEXT NOT NULL CHECK (char_length(trim(master_artisan_name)) BETWEEN 2 AND 100),
  master_honorific TEXT NOT NULL CHECK (char_length(trim(master_honorific)) BETWEEN 2 AND 120),
  description TEXT NOT NULL CHECK (char_length(trim(description)) BETWEEN 10 AND 600),
  accent_color_hex TEXT NOT NULL DEFAULT '#2563EB',
  latitude DOUBLE PRECISION NOT NULL,
  longitude DOUBLE PRECISION NOT NULL,
  materials TEXT[] NOT NULL DEFAULT '{}',
  is_published BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 2. Workshop Masterclasses Table
CREATE TABLE IF NOT EXISTS public.workshop_masterclasses (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  studio_id UUID NOT NULL REFERENCES public.craft_workshops(id) ON DELETE CASCADE,
  class_key TEXT NOT NULL CHECK (char_length(trim(class_key)) BETWEEN 2 AND 80),
  title TEXT NOT NULL CHECK (char_length(trim(title)) BETWEEN 3 AND 120),
  duration_minutes INTEGER NOT NULL DEFAULT 90 CHECK (duration_minutes > 0),
  skill_level TEXT NOT NULL DEFAULT 'Beginner' CHECK (skill_level IN ('Beginner', 'Intermediate', 'Master')),
  max_participants INTEGER NOT NULL DEFAULT 8 CHECK (max_participants > 0),
  price_uzs INTEGER NOT NULL DEFAULT 150000 CHECK (price_uzs >= 0),
  xp_reward INTEGER NOT NULL DEFAULT 40 CHECK (xp_reward >= 0),
  time_slot TEXT NOT NULL CHECK (char_length(trim(time_slot)) BETWEEN 3 AND 50),
  is_active BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT unique_studio_class_key UNIQUE (studio_id, class_key)
);

-- 3. User Workshop Reservations Table
CREATE TABLE IF NOT EXISTS public.user_workshop_reservations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  masterclass_id UUID NOT NULL REFERENCES public.workshop_masterclasses(id) ON DELETE CASCADE,
  studio_id UUID NOT NULL REFERENCES public.craft_workshops(id) ON DELETE CASCADE,
  xp_awarded INTEGER NOT NULL DEFAULT 40 CHECK (xp_awarded >= 0),
  reservation_status TEXT NOT NULL DEFAULT 'confirmed' CHECK (reservation_status IN ('confirmed', 'cancelled', 'completed')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT unique_user_masterclass_reservation UNIQUE (user_id, masterclass_id)
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_craft_workshops_slug ON public.craft_workshops(slug);
CREATE INDEX IF NOT EXISTS idx_craft_workshops_discipline ON public.craft_workshops(craft_discipline);
CREATE INDEX IF NOT EXISTS idx_workshop_classes_studio ON public.workshop_masterclasses(studio_id);
CREATE INDEX IF NOT EXISTS idx_workshop_reservations_user ON public.user_workshop_reservations(user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_workshop_reservations_class ON public.user_workshop_reservations(masterclass_id);

-- Enable Row-Level Security
ALTER TABLE public.craft_workshops ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.workshop_masterclasses ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_workshop_reservations ENABLE ROW LEVEL SECURITY;

-- Read policies for published workshops and active masterclasses
CREATE POLICY "Published craft workshops readable by all"
  ON public.craft_workshops
  FOR SELECT
  USING (is_published = true);

CREATE POLICY "Active workshop masterclasses readable by all"
  ON public.workshop_masterclasses
  FOR SELECT
  USING (
    is_active = true
    AND EXISTS (
      SELECT 1 FROM public.craft_workshops w
      WHERE w.id = workshop_masterclasses.studio_id
        AND w.is_published = true
    )
  );

-- Dual-layer privacy read policy for user reservations
CREATE POLICY "Workshop reservations readable if user privacy permits"
  ON public.user_workshop_reservations
  FOR SELECT
  USING (
    auth.uid() = user_id
    OR EXISTS (
      SELECT 1 FROM public.profiles p
      WHERE p.id = user_workshop_reservations.user_id
        AND COALESCE(p.hide_visits_history, false) = false
    )
  );

CREATE POLICY "Users can insert their own reservations"
  ON public.user_workshop_reservations
  FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own reservations"
  ON public.user_workshop_reservations
  FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete their own reservations"
  ON public.user_workshop_reservations
  FOR DELETE
  USING (auth.uid() = user_id);

-- Seed Initial Curated Tashkent Craft Studios
INSERT INTO public.craft_workshops (
  id, slug, title, district, craft_discipline, master_artisan_name, master_honorific, description, accent_color_hex, latitude, longitude, materials
) VALUES
(
  'c1000000-0000-0000-0000-000000000001',
  'studio-rishtan-ceramics',
  'Rishtan Blue Glaze Pottery House',
  'Shaykhontohur',
  'Ceramics',
  'Usto Alisher Nazirov',
  '7th Generation Rishtan Ceramicist',
  'Spin traditional foot-powered kick wheels and paint natural mineral Ishkor glaze onto terracotta plates.',
  '#2563EB',
  41.3284,
  69.2412,
  ARRAY['Fergana Red Clay', 'Ishkor Herbal Ash Glaze', 'Cobalt Oxide Mineral']
),
(
  'c1000000-0000-0000-0000-000000000002',
  'studio-chorsu-woodcarving',
  'Chorsu Walnut Woodcarving Atelier',
  'Old City Chorsu',
  'Woodcarving',
  'Usto Nematullo Khaydarov',
  'Master of Central Asian Floral Islimi',
  'Hand-carve geometric Parda and vegetal Islimi patterns onto mountain walnut bookstands and tea tables.',
  '#FF4800',
  41.3275,
  69.2370,
  ARRAY['Fergana Wild Walnut', 'Natural Beeswax Polish', 'Hand-Forged Steel Chisels']
),
(
  'c1000000-0000-0000-0000-000000000003',
  'studio-yakkasaray-silk',
  'Ankhor Suzani & Silk Weaving Studio',
  'Yakkasaray',
  'Silk Weaving',
  'Madina Kasimbaeva',
  'Traditional Ikat & Suzani Master',
  'Learn century-old tambour chain stitches and natural dye preparation from pomegranate rind and madder root.',
  '#A259FF',
  41.2912,
  69.2554,
  ARRAY['Margilan Mulberry Silk', 'Pomegranate Peel Yellow', 'Madder Root Crimson']
),
(
  'c1000000-0000-0000-0000-000000000004',
  'studio-mirabad-copper',
  'Mirabad Copper & Chasing Forge',
  'Mirabad',
  'Copper Embossing',
  'Usto Farrukh Kandakor',
  'Central Asian Chasing Guildmaster',
  'Chase traditional filigree relief onto tinned tea ewers and trays using copper punches and mallets.',
  '#059669',
  41.3005,
  69.2731,
  ARRAY['Tinned Red Copper Sheets', 'Black Pitch Bedding', 'Tempered Punches']
)
ON CONFLICT (slug) DO NOTHING;

-- Seed Masterclasses for Workshops
INSERT INTO public.workshop_masterclasses (
  studio_id, class_key, title, duration_minutes, skill_level, max_participants, price_uzs, xp_reward, time_slot
) VALUES
(
  'c1000000-0000-0000-0000-000000000001',
  'class-kickwheel-pottery',
  'Foot-Powered Kickwheel Pitcher Throwing',
  90,
  'Beginner',
  6,
  180000,
  40,
  '11:00 - 12:30'
),
(
  'c1000000-0000-0000-0000-000000000001',
  'class-ishkor-glaze',
  'Rishtan Turquoise Ishkor Glaze Painting',
  120,
  'Intermediate',
  5,
  220000,
  50,
  '15:00 - 17:00'
),
(
  'c1000000-0000-0000-0000-000000000002',
  'class-laukh-folding-stand',
  'Carving a Seamless Single-Piece Laukh Bookstand',
  120,
  'Intermediate',
  4,
  250000,
  45,
  '14:00 - 16:00'
),
(
  'c1000000-0000-0000-0000-000000000003',
  'class-suzani-embroidery',
  'Tashkent Pomegranate Blossom Chain Stitching',
  90,
  'Beginner',
  8,
  160000,
  40,
  '16:30 - 18:00'
),
(
  'c1000000-0000-0000-0000-000000000004',
  'class-copper-chasing',
  'Embossing Traditional Rishtan Tea Plate Rim',
  90,
  'Beginner',
  6,
  190000,
  40,
  '10:30 - 12:00'
)
ON CONFLICT (studio_id, class_key) DO NOTHING;

-- RPC: Reserve a seat in an artisan masterclass and award +40 XP
CREATE OR REPLACE FUNCTION public.reserve_craft_masterclass(
  p_studio_slug TEXT,
  p_class_key TEXT
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
  v_user_id UUID := auth.uid();
  v_studio RECORD;
  v_class RECORD;
  v_existing RECORD;
  v_confirmed_count INTEGER;
BEGIN
  IF v_user_id IS NULL THEN
    RETURN jsonb_build_object(
      'success', false,
      'error', 'Authentication required to book artisan masterclasses.'
    );
  END IF;

  -- Locate active workshop
  SELECT * INTO v_studio
  FROM public.craft_workshops
  WHERE slug = LOWER(TRIM(p_studio_slug)) AND is_published = true;

  IF NOT FOUND THEN
    RETURN jsonb_build_object(
      'success', false,
      'error', 'Craft workshop not found or unpublished.'
    );
  END IF;

  -- Locate masterclass
  SELECT * INTO v_class
  FROM public.workshop_masterclasses
  WHERE studio_id = v_studio.id AND class_key = LOWER(TRIM(p_class_key)) AND is_active = true;

  IF NOT FOUND THEN
    RETURN jsonb_build_object(
      'success', false,
      'error', 'Workshop masterclass not found or inactive.'
    );
  END IF;

  -- Check if already reserved by user
  SELECT * INTO v_existing
  FROM public.user_workshop_reservations
  WHERE user_id = v_user_id AND masterclass_id = v_class.id;

  IF FOUND THEN
    RETURN jsonb_build_object(
      'success', true,
      'already_reserved', true,
      'studio_slug', v_studio.slug,
      'class_key', v_class.class_key,
      'reservation_status', v_existing.reservation_status,
      'xp_awarded', v_existing.xp_awarded
    );
  END IF;

  -- Check capacity
  SELECT COUNT(*) INTO v_confirmed_count
  FROM public.user_workshop_reservations
  WHERE masterclass_id = v_class.id AND reservation_status = 'confirmed';

  IF v_confirmed_count >= v_class.max_participants THEN
    RETURN jsonb_build_object(
      'success', false,
      'error', 'Masterclass is fully booked.'
    );
  END IF;

  -- Create reservation
  INSERT INTO public.user_workshop_reservations (
    user_id, masterclass_id, studio_id, xp_awarded, reservation_status
  ) VALUES (
    v_user_id, v_class.id, v_studio.id, v_class.xp_reward, 'confirmed'
  );

  RETURN jsonb_build_object(
    'success', true,
    'already_reserved', false,
    'studio_slug', v_studio.slug,
    'class_key', v_class.class_key,
    'reservation_status', 'confirmed',
    'xp_awarded', v_class.xp_reward,
    'seats_remaining', (v_class.max_participants - (v_confirmed_count + 1))
  );
END;
$$;
