-- Migration 00032: Architectural Badge Quests & Discovery Passports Schema & RPC
-- Enables explorers to complete thematic architecture quests, collect landmark stops, and unlock curator prestige badges across Tashkent.

-- 1. Architectural Quests Definition Table
CREATE TABLE IF NOT EXISTS public.architectural_quests (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  slug TEXT UNIQUE NOT NULL CHECK (char_length(trim(slug)) BETWEEN 3 AND 80),
  title TEXT NOT NULL CHECK (char_length(trim(title)) BETWEEN 3 AND 120),
  badge_name TEXT NOT NULL CHECK (char_length(trim(badge_name)) BETWEEN 3 AND 80),
  description TEXT NOT NULL CHECK (char_length(trim(description)) BETWEEN 10 AND 500),
  category TEXT NOT NULL DEFAULT 'Modernism' CHECK (category IN ('Modernism', 'Heritage', 'Contemporary', 'Mosaics')),
  badge_icon TEXT NOT NULL DEFAULT 'building.columns',
  badge_accent_color_hex TEXT NOT NULL DEFAULT '#D97706',
  required_stops_count INTEGER NOT NULL DEFAULT 3 CHECK (required_stops_count > 0),
  xp_reward INTEGER NOT NULL DEFAULT 50 CHECK (xp_reward >= 0),
  curator_quote TEXT,
  is_published BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 2. Architectural Quest Stops Table
CREATE TABLE IF NOT EXISTS public.architectural_quest_stops (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  quest_id UUID NOT NULL REFERENCES public.architectural_quests(id) ON DELETE CASCADE,
  stop_key TEXT NOT NULL CHECK (char_length(trim(stop_key)) BETWEEN 2 AND 80),
  place_id UUID REFERENCES public.places(id) ON DELETE SET NULL,
  name TEXT NOT NULL CHECK (char_length(trim(name)) BETWEEN 2 AND 120),
  district TEXT NOT NULL CHECK (char_length(trim(district)) BETWEEN 2 AND 80),
  architectural_style TEXT NOT NULL CHECK (char_length(trim(architectural_style)) BETWEEN 2 AND 100),
  year_built INTEGER CHECK (year_built BETWEEN 1000 AND 2100),
  architectural_fact TEXT NOT NULL CHECK (char_length(trim(architectural_fact)) BETWEEN 5 AND 600),
  latitude DOUBLE PRECISION NOT NULL,
  longitude DOUBLE PRECISION NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT unique_quest_stop UNIQUE (quest_id, stop_key)
);

-- 3. User Landmark Visits for Quests Table
CREATE TABLE IF NOT EXISTS public.user_quest_visits (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  quest_id UUID NOT NULL REFERENCES public.architectural_quests(id) ON DELETE CASCADE,
  stop_key TEXT NOT NULL CHECK (char_length(trim(stop_key)) BETWEEN 2 AND 80),
  place_id UUID REFERENCES public.places(id) ON DELETE SET NULL,
  visited_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT unique_user_quest_stop UNIQUE (user_id, quest_id, stop_key)
);

-- 4. User Unlocked Architectural Badges Table
CREATE TABLE IF NOT EXISTS public.user_unlocked_badges (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  quest_id UUID NOT NULL REFERENCES public.architectural_quests(id) ON DELETE CASCADE,
  badge_name TEXT NOT NULL,
  xp_awarded INTEGER NOT NULL DEFAULT 50 CHECK (xp_awarded >= 0),
  unlocked_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT unique_user_badge UNIQUE (user_id, quest_id)
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_arch_quests_slug ON public.architectural_quests(slug);
CREATE INDEX IF NOT EXISTS idx_arch_stops_quest ON public.architectural_quest_stops(quest_id);
CREATE INDEX IF NOT EXISTS idx_user_quest_visits_user ON public.user_quest_visits(user_id, quest_id);
CREATE INDEX IF NOT EXISTS idx_user_unlocked_badges_user ON public.user_unlocked_badges(user_id, unlocked_at DESC);

-- Enable Row-Level Security
ALTER TABLE public.architectural_quests ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.architectural_quest_stops ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_quest_visits ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_unlocked_badges ENABLE ROW LEVEL SECURITY;

-- Read policies for public quest definitions
CREATE POLICY "Published quests are readable by everyone"
  ON public.architectural_quests
  FOR SELECT
  USING (is_published = true);

CREATE POLICY "Quest stops are readable by everyone"
  ON public.architectural_quest_stops
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.architectural_quests q
      WHERE q.id = architectural_quest_stops.quest_id
        AND q.is_published = true
    )
  );

-- Dual-layer privacy read policy for user quest visits
CREATE POLICY "Quest visits readable if user privacy permits"
  ON public.user_quest_visits
  FOR SELECT
  USING (
    auth.uid() = user_id
    OR EXISTS (
      SELECT 1 FROM public.profiles p
      WHERE p.id = user_quest_visits.user_id
        AND COALESCE(p.hide_visits_history, false) = false
    )
  );

CREATE POLICY "Users can insert their own quest visits"
  ON public.user_quest_visits
  FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete their own quest visits"
  ON public.user_quest_visits
  FOR DELETE
  USING (auth.uid() = user_id);

-- Dual-layer privacy read policy for unlocked badges
CREATE POLICY "Unlocked badges readable if user privacy permits"
  ON public.user_unlocked_badges
  FOR SELECT
  USING (
    auth.uid() = user_id
    OR EXISTS (
      SELECT 1 FROM public.profiles p
      WHERE p.id = user_unlocked_badges.user_id
        AND COALESCE(p.hide_visits_history, false) = false
    )
  );

CREATE POLICY "Users can only insert badges for themselves"
  ON public.user_unlocked_badges
  FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Seed Initial Curated Quests
INSERT INTO public.architectural_quests (
  id, slug, title, badge_name, description, category, badge_icon, badge_accent_color_hex, required_stops_count, xp_reward, curator_quote
) VALUES
(
  'e1000000-0000-0000-0000-000000000001',
  'tashkent-modernism',
  'Soviet Modernism & Brise-Soleil Trail',
  'Modernist Connoisseur',
  'Explore the bold concrete facades, geometric solar sun-screens, and dramatic cantilevered canopies of 1960s-1980s Tashkent.',
  'Modernism',
  'building.columns',
  '#D97706',
  3,
  50,
  'The post-1966 earthquake reconstruction transformed Tashkent into an open-air laboratory of experimental solar architecture.'
),
(
  'e1000000-0000-0000-0000-000000000002',
  'silk-road-heritage',
  'Silk Road Majolica & Minaret Route',
  'Silk Road Custodian',
  'Journey through centuries of turquoise glazed majolica, intricate wood-carved columns, and grand madrasah courtyards in Old City.',
  'Heritage',
  'sparkles',
  '#2563EB',
  3,
  50,
  'Old Tashkent preserves the centuries-old spatial rhythm of the mahalla surrounding towering spiritual landmarks.'
)
ON CONFLICT (slug) DO NOTHING;

-- Seed Stops for Modernism Quest
INSERT INTO public.architectural_quest_stops (
  quest_id, stop_key, name, district, architectural_style, year_built, architectural_fact, latitude, longitude
) VALUES
(
  'e1000000-0000-0000-0000-000000000001',
  'hotel-uzbekistan',
  'Hotel Uzbekistan',
  'Mirabad',
  'Soviet Modernism / Brise-Soleil',
  1974,
  'Features an iconic sweeping curved facade wrapped in a decorative concrete brise-soleil lattice inspired by traditional Uzbek panjara.',
  41.3115,
  69.2796
),
(
  'e1000000-0000-0000-0000-000000000001',
  'tashkent-circus',
  'Tashkent State Circus',
  'Shaykhontohur',
  'Futuristic Modernism / Sky Blue Dome',
  1976,
  'Known as the "Flying Saucer", its sky-blue faceted dome spans 76 meters without central support pillars.',
  41.3262,
  69.2389
),
(
  'e1000000-0000-0000-0000-000000000001',
  'blue-domes',
  'Golubye Kupola (Blue Domes)',
  'Yakkasaray',
  'Modernist Pavilions / Ceramic Vaults',
  1970,
  'Designed by Vil Muratov, combining airy open terraces under hemispherical ceramic-tiled domes nestled in park greenery.',
  41.3090,
  69.2678
)
ON CONFLICT (quest_id, stop_key) DO NOTHING;

-- RPC: Record a landmark stop visit and evaluate badge unlock
CREATE OR REPLACE FUNCTION public.record_quest_stop_visit(
  p_quest_slug TEXT,
  p_stop_key TEXT,
  p_place_id UUID DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
  v_user_id UUID := auth.uid();
  v_quest RECORD;
  v_stop RECORD;
  v_visited_count INTEGER;
  v_already_visited BOOLEAN;
  v_badge_already_unlocked BOOLEAN;
  v_badge_unlocked_now BOOLEAN := false;
BEGIN
  IF v_user_id IS NULL THEN
    RETURN jsonb_build_object(
      'success', false,
      'error', 'Authentication required to record quest landmark visits.'
    );
  END IF;

  -- Locate quest
  SELECT * INTO v_quest
  FROM public.architectural_quests
  WHERE slug = LOWER(TRIM(p_quest_slug)) AND is_published = true;

  IF NOT FOUND THEN
    RETURN jsonb_build_object(
      'success', false,
      'error', 'Architectural quest not found or not published.'
    );
  END IF;

  -- Locate stop
  SELECT * INTO v_stop
  FROM public.architectural_quest_stops
  WHERE quest_id = v_quest.id AND stop_key = LOWER(TRIM(p_stop_key));

  IF NOT FOUND THEN
    RETURN jsonb_build_object(
      'success', false,
      'error', 'Quest stop landmark not found.'
    );
  END IF;

  -- Check if already visited
  SELECT EXISTS (
    SELECT 1 FROM public.user_quest_visits
    WHERE user_id = v_user_id AND quest_id = v_quest.id AND stop_key = v_stop.stop_key
  ) INTO v_already_visited;

  IF NOT v_already_visited THEN
    INSERT INTO public.user_quest_visits (
      user_id, quest_id, stop_key, place_id
    ) VALUES (
      v_user_id, v_quest.id, v_stop.stop_key, COALESCE(p_place_id, v_stop.place_id)
    );
  END IF;

  -- Count total visited stops for this quest
  SELECT COUNT(*) INTO v_visited_count
  FROM public.user_quest_visits
  WHERE user_id = v_user_id AND quest_id = v_quest.id;

  -- Check if badge was already unlocked
  SELECT EXISTS (
    SELECT 1 FROM public.user_unlocked_badges
    WHERE user_id = v_user_id AND quest_id = v_quest.id
  ) INTO v_badge_already_unlocked;

  -- If required count met and not unlocked yet, unlock badge!
  IF v_visited_count >= v_quest.required_stops_count AND NOT v_badge_already_unlocked THEN
    INSERT INTO public.user_unlocked_badges (
      user_id, quest_id, badge_name, xp_awarded
    ) VALUES (
      v_user_id, v_quest.id, v_quest.badge_name, v_quest.xp_reward
    );

    v_badge_unlocked_now := true;
  END IF;

  RETURN jsonb_build_object(
    'success', true,
    'quest_slug', v_quest.slug,
    'stop_key', v_stop.stop_key,
    'visited_count', v_visited_count,
    'required_stops', v_quest.required_stops_count,
    'is_completed', (v_visited_count >= v_quest.required_stops_count),
    'badge_unlocked_now', v_badge_unlocked_now,
    'badge_name', v_quest.badge_name,
    'xp_awarded', CASE WHEN v_badge_unlocked_now THEN v_quest.xp_reward ELSE 0 END
  );
END;
$$;
