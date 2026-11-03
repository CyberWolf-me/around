-- Migration 00036: Traditional Tashkent Chaykhana Culture, Samovar Gatherings & Kaytarish Rituals Schema & RPC
-- Enables explorers to discover authentic neighborhood chaykhanas, reserve tapchans, and experience the 3-step Kaytarish aeration tea ritual.

-- 1. Chaykhana Venues Definition Table
CREATE TABLE IF NOT EXISTS public.chaykhana_venues (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  slug TEXT UNIQUE NOT NULL CHECK (char_length(trim(slug)) BETWEEN 3 AND 80),
  name TEXT NOT NULL CHECK (char_length(trim(name)) BETWEEN 3 AND 120),
  district TEXT NOT NULL CHECK (char_length(trim(district)) BETWEEN 2 AND 80),
  chaykhana_usto_name TEXT NOT NULL CHECK (char_length(trim(chaykhana_usto_name)) BETWEEN 2 AND 100),
  accent_color_hex TEXT NOT NULL DEFAULT '#059669',
  samovar_type TEXT NOT NULL CHECK (char_length(trim(samovar_type)) BETWEEN 3 AND 120),
  available_tapchans INTEGER NOT NULL DEFAULT 4 CHECK (available_tapchans >= 0),
  total_tapchans INTEGER NOT NULL DEFAULT 12 CHECK (total_tapchans > 0),
  latitude DOUBLE PRECISION NOT NULL,
  longitude DOUBLE PRECISION NOT NULL,
  is_published BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 2. Tea Blends Table
CREATE TABLE IF NOT EXISTS public.tea_blends (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  chaykhana_id UUID NOT NULL REFERENCES public.chaykhana_venues(id) ON DELETE CASCADE,
  blend_key TEXT NOT NULL CHECK (char_length(trim(blend_key)) BETWEEN 2 AND 80),
  name TEXT NOT NULL CHECK (char_length(trim(name)) BETWEEN 3 AND 120),
  tea_type TEXT NOT NULL DEFAULT 'Green' CHECK (tea_type IN ('Green', 'Black', 'Herbal', 'Saffron')),
  description TEXT NOT NULL,
  botanical_ingredients TEXT[] NOT NULL DEFAULT '{}',
  water_temp_celsius INTEGER NOT NULL DEFAULT 85 CHECK (water_temp_celsius > 0),
  steep_time_seconds INTEGER NOT NULL DEFAULT 180 CHECK (steep_time_seconds > 0),
  flavor_profile TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT unique_chaykhana_blend_key UNIQUE (chaykhana_id, blend_key)
);

-- 3. User Chaykhana Gatherings Table
CREATE TABLE IF NOT EXISTS public.user_chaykhana_gatherings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  chaykhana_id UUID NOT NULL REFERENCES public.chaykhana_venues(id) ON DELETE CASCADE,
  blend_id UUID REFERENCES public.tea_blends(id) ON DELETE SET NULL,
  kaytarish_step_reached INTEGER NOT NULL DEFAULT 3 CHECK (kaytarish_step_reached >= 1 AND kaytarish_step_reached <= 3),
  xp_awarded INTEGER NOT NULL DEFAULT 35 CHECK (xp_awarded >= 0),
  gathering_status TEXT NOT NULL DEFAULT 'confirmed' CHECK (gathering_status IN ('confirmed', 'completed', 'cancelled')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT unique_user_chaykhana_gathering UNIQUE (user_id, chaykhana_id)
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_chaykhana_slug ON public.chaykhana_venues(slug);
CREATE INDEX IF NOT EXISTS idx_chaykhana_district ON public.chaykhana_venues(district);
CREATE INDEX IF NOT EXISTS idx_tea_blends_chaykhana ON public.tea_blends(chaykhana_id);
CREATE INDEX IF NOT EXISTS idx_chaykhana_gatherings_user ON public.user_chaykhana_gatherings(user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_chaykhana_gatherings_venue ON public.user_chaykhana_gatherings(chaykhana_id);

-- Enable Row-Level Security
ALTER TABLE public.chaykhana_venues ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tea_blends ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_chaykhana_gatherings ENABLE ROW LEVEL SECURITY;

-- Read policies for published venues and blends
CREATE POLICY "Published chaykhanas readable by all"
  ON public.chaykhana_venues
  FOR SELECT
  USING (is_published = true);

CREATE POLICY "Tea blends readable by all"
  ON public.tea_blends
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.chaykhana_venues v
      WHERE v.id = tea_blends.chaykhana_id
        AND v.is_published = true
    )
  );

-- Dual-layer privacy read policy for user gatherings
CREATE POLICY "Chaykhana gatherings readable if user privacy permits"
  ON public.user_chaykhana_gatherings
  FOR SELECT
  USING (
    auth.uid() = user_id
    OR EXISTS (
      SELECT 1 FROM public.profiles p
      WHERE p.id = user_chaykhana_gatherings.user_id
        AND COALESCE(p.hide_visits_history, false) = false
    )
  );

CREATE POLICY "Users can insert their own gatherings"
  ON public.user_chaykhana_gatherings
  FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own gatherings"
  ON public.user_chaykhana_gatherings
  FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete their own gatherings"
  ON public.user_chaykhana_gatherings
  FOR DELETE
  USING (auth.uid() = user_id);

-- Seed Initial Curated Tashkent Chaykhanas
INSERT INTO public.chaykhana_venues (
  id, slug, name, district, chaykhana_usto_name, accent_color_hex, samovar_type, available_tapchans, total_tapchans, latitude, longitude
) VALUES
(
  'b1000000-0000-0000-0000-000000000001',
  'chaykhana-chorsu-chinor',
  'Chorsu Chinor Chaykhana',
  'Shaykhontohur',
  'Usto Bobomurod Choychi',
  '#059669',
  'Charcoal Tinned Brass Samovar (1924)',
  4,
  12,
  41.3284,
  69.2412
),
(
  'b1000000-0000-0000-0000-000000000002',
  'chaykhana-hast-imam',
  'Hast Imam Saffron & Mint Chaykhana',
  'Almazar',
  'Usto Ilkhom Choypaz',
  '#FFD666',
  'Firewood Hammered Copper Samovar',
  6,
  16,
  41.3360,
  69.2390
),
(
  'b1000000-0000-0000-0000-000000000003',
  'chaykhana-ankhor-terrace',
  'Ankhor Embankment Riverbed Chaykhana',
  'Yakkasaray',
  'Otabek Mirzo',
  '#00D2FC',
  'Tsarist Imperial Brass Samovar (1898)',
  2,
  8,
  41.2912,
  69.2554
)
ON CONFLICT (slug) DO NOTHING;

-- Seed Signature Tea Blends
INSERT INTO public.tea_blends (
  chaykhana_id, blend_key, name, tea_type, description, botanical_ingredients, water_temp_celsius, steep_time_seconds, flavor_profile
) VALUES
(
  'b1000000-0000-0000-0000-000000000001',
  'blend-tashkent-kok-choy',
  'Old City Kok-Choy No. 95',
  'Green',
  'High-fire Chinese gunpowder green leaf aerated over centuries-old plane tree shade.',
  ARRAY['Spring Green Leaf', 'Dried Mountain Thyme', 'Wild Mint'],
  85,
  180,
  'Crisp, grassy sweetness with gentle astringency'
),
(
  'b1000000-0000-0000-0000-000000000002',
  'blend-zafaron-saffron',
  'Poytaxt Royal Saffron Amber',
  'Saffron',
  'Bukhara saffron threads steeped with wild mountain oregano and golden honey.',
  ARRAY['Red Saffron Stigmas', 'Dried Quince Blossoms', 'Ceylon Black Tip'],
  92,
  240,
  'Velvety honey, floral saffron aromatics, and toasted spice'
),
(
  'b1000000-0000-0000-0000-000000000003',
  'blend-pomegranate-hibiscus',
  'Canal Willow Pomegranate Infusion',
  'Herbal',
  'Ruby red infusion of sun-dried Kuva pomegranate peel, hibiscus petals, and clove.',
  ARRAY['Pomegranate Peel', 'Hibiscus Calyces', 'Cardamom Pods'],
  95,
  300,
  'Tart ruby fruit, sweet clove warmth, and citrus perfume'
)
ON CONFLICT (chaykhana_id, blend_key) DO NOTHING;

-- RPC: Host or join a tapchan tea gathering, complete the Kaytarish ritual and award +35 XP
CREATE OR REPLACE FUNCTION public.host_chaykhana_gathering(
  p_chaykhana_slug TEXT,
  p_blend_key TEXT DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
  v_user_id UUID := auth.uid();
  v_venue RECORD;
  v_blend RECORD;
  v_existing RECORD;
BEGIN
  IF v_user_id IS NULL THEN
    RETURN jsonb_build_object(
      'success', false,
      'error', 'Authentication required to host chaykhana gatherings.'
    );
  END IF;

  -- Locate active chaykhana
  SELECT * INTO v_venue
  FROM public.chaykhana_venues
  WHERE slug = LOWER(TRIM(p_chaykhana_slug)) AND is_published = true;

  IF NOT FOUND THEN
    RETURN jsonb_build_object(
      'success', false,
      'error', 'Chaykhana venue not found or unpublished.'
    );
  END IF;

  -- Optional blend resolution
  IF p_blend_key IS NOT NULL THEN
    SELECT * INTO v_blend
    FROM public.tea_blends
    WHERE chaykhana_id = v_venue.id AND blend_key = LOWER(TRIM(p_blend_key));
  END IF;

  -- Check existing gathering
  SELECT * INTO v_existing
  FROM public.user_chaykhana_gatherings
  WHERE user_id = v_user_id AND chaykhana_id = v_venue.id;

  IF FOUND THEN
    RETURN jsonb_build_object(
      'success', true,
      'already_reserved', true,
      'chaykhana_slug', v_venue.slug,
      'gathering_status', v_existing.gathering_status,
      'xp_awarded', v_existing.xp_awarded,
      'available_tapchans', v_venue.available_tapchans
    );
  END IF;

  -- Check tapchan availability
  IF v_venue.available_tapchans <= 0 THEN
    RETURN jsonb_build_object(
      'success', false,
      'error', 'All tapchans at this chaykhana are currently occupied.'
    );
  END IF;

  -- Insert gathering and decrement available tapchans
  INSERT INTO public.user_chaykhana_gatherings (
    user_id, chaykhana_id, blend_id, kaytarish_step_reached, xp_awarded, gathering_status
  ) VALUES (
    v_user_id, v_venue.id, v_blend.id, 3, 35, 'confirmed'
  );

  UPDATE public.chaykhana_venues
  SET available_tapchans = GREATEST(0, available_tapchans - 1)
  WHERE id = v_venue.id;

  RETURN jsonb_build_object(
    'success', true,
    'already_reserved', false,
    'chaykhana_slug', v_venue.slug,
    'gathering_status', 'confirmed',
    'xp_awarded', 35,
    'available_tapchans', (v_venue.available_tapchans - 1)
  );
END;
$$;
