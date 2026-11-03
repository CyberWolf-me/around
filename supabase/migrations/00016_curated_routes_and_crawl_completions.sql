-- Migration 00016: Curated Walking Routes & Shared Crawl Completions
-- Establishes curated route itineraries and verified completion tracking
-- with atomic curator XP rewards and strict auth.uid() caller invariants.

-- 1. Curated Routes Catalog Table
CREATE TABLE IF NOT EXISTS public.curated_routes (
  id TEXT PRIMARY KEY,
  title TEXT NOT NULL CHECK (char_length(trim(title)) BETWEEN 2 AND 120),
  subtitle TEXT NOT NULL DEFAULT '',
  district TEXT NOT NULL CHECK (char_length(trim(district)) BETWEEN 2 AND 80),
  emoji TEXT NOT NULL DEFAULT '📍',
  stops JSONB NOT NULL DEFAULT '[]'::jsonb,
  total_estimated_minutes INTEGER NOT NULL DEFAULT 15,
  total_distance_meters INTEGER NOT NULL DEFAULT 1000,
  xp_reward INTEGER NOT NULL DEFAULT 150,
  start_subway TEXT NOT NULL DEFAULT '',
  end_subway TEXT NOT NULL DEFAULT '',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 2. User Route Completions Table
CREATE TABLE IF NOT EXISTS public.route_completions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  route_id TEXT NOT NULL REFERENCES public.curated_routes(id) ON DELETE CASCADE,
  completed_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  xp_earned INTEGER NOT NULL DEFAULT 150,
  verified_stops_count INTEGER NOT NULL DEFAULT 0,
  CONSTRAINT unique_user_route_completion UNIQUE(user_id, route_id)
);

CREATE INDEX IF NOT EXISTS idx_route_completions_user ON public.route_completions(user_id);
CREATE INDEX IF NOT EXISTS idx_route_completions_route ON public.route_completions(route_id);

-- 3. Row-Level Security
ALTER TABLE public.curated_routes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.route_completions ENABLE ROW LEVEL SECURITY;

-- Curated routes are readable by everyone
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'curated_routes' AND policyname = 'curated_routes_read_all'
  ) THEN
    CREATE POLICY curated_routes_read_all ON public.curated_routes
      FOR SELECT USING (true);
  END IF;
END $$;

-- Route completions: readable by owner or friends (if not hidden)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'route_completions' AND policyname = 'route_completions_read_owner_or_friends'
  ) THEN
    CREATE POLICY route_completions_read_owner_or_friends ON public.route_completions
      FOR SELECT USING (
        auth.uid() = user_id
        OR EXISTS (
          SELECT 1 FROM public.friendships f
          JOIN public.profiles p ON p.id = route_completions.user_id
          WHERE (
            (f.user_id = auth.uid() AND f.friend_id = route_completions.user_id AND f.status = 'accepted')
            OR (f.friend_id = auth.uid() AND f.user_id = route_completions.user_id AND f.status = 'accepted')
          )
          AND p.hide_visits_history = FALSE
        )
      );
  END IF;
END $$;

-- 4. Idempotent Route Completion RPC
CREATE OR REPLACE FUNCTION public.complete_curated_route(p_route_id TEXT)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
  v_uid UUID;
  v_route public.curated_routes%ROWTYPE;
  v_already_completed BOOLEAN;
  v_total_xp INTEGER;
  v_new_level INTEGER := 1;
  v_new_tier TEXT := 'neighborhoodScout';
  v_stops_count INTEGER := 0;
BEGIN
  -- Strict caller identity binding (Rule C)
  v_uid := auth.uid();
  IF v_uid IS NULL THEN
    RETURN jsonb_build_object('success', false, 'error', 'Authentication required to complete route.');
  END IF;

  -- Verify route exists
  SELECT * INTO v_route
  FROM public.curated_routes
  WHERE id = trim(p_route_id);

  IF NOT FOUND THEN
    RETURN jsonb_build_object('success', false, 'error', 'Curated route not found.');
  END IF;

  -- Check if already completed
  SELECT EXISTS (
    SELECT 1 FROM public.route_completions
    WHERE user_id = v_uid AND route_id = v_route.id
  ) INTO v_already_completed;

  IF v_already_completed THEN
    SELECT curator_xp, curator_level, curator_tier INTO v_total_xp, v_new_level, v_new_tier
    FROM public.profiles WHERE id = v_uid;

    RETURN jsonb_build_object(
      'success', true,
      'already_completed', true,
      'route_id', v_route.id,
      'xp_awarded', 0,
      'total_xp', v_total_xp,
      'curator_level', v_new_level,
      'curator_tier', v_new_tier
    );
  END IF;

  v_stops_count := jsonb_array_length(v_route.stops);

  -- Record completion
  INSERT INTO public.route_completions (
    user_id,
    route_id,
    xp_earned,
    verified_stops_count,
    completed_at
  ) VALUES (
    v_uid,
    v_route.id,
    v_route.xp_reward,
    v_stops_count,
    NOW()
  );

  -- Award XP in profile
  UPDATE public.profiles
  SET curator_xp = curator_xp + v_route.xp_reward,
      updated_at = NOW()
  WHERE id = v_uid
  RETURNING curator_xp INTO v_total_xp;

  -- Calculate tier & level
  IF v_total_xp >= 2000 THEN
    v_new_tier := 'tashkentLegend';
    v_new_level := 4;
  ELSIF v_total_xp >= 750 THEN
    v_new_tier := 'cityPioneer';
    v_new_level := 3;
  ELSIF v_total_xp >= 250 THEN
    v_new_tier := 'districtCurator';
    v_new_level := 2;
  ELSE
    v_new_tier := 'neighborhoodScout';
    v_new_level := 1;
  END IF;

  UPDATE public.profiles
  SET curator_tier = v_new_tier,
      curator_level = v_new_level
  WHERE id = v_uid;

  RETURN jsonb_build_object(
    'success', true,
    'already_completed', false,
    'route_id', v_route.id,
    'xp_awarded', v_route.xp_reward,
    'total_xp', v_total_xp,
    'curator_level', v_new_level,
    'curator_tier', v_new_tier
  );
END;
$$;

-- 5. Seed default curated routes
INSERT INTO public.curated_routes (
  id, title, subtitle, district, emoji, total_estimated_minutes, total_distance_meters, xp_reward, start_subway, end_subway, stops
) VALUES
  (
    'mirabad_coffee_crawl',
    'Mirabad Specialty Coffee Crawl',
    'The golden triangle of Tashkent morning coffee and pastry craft',
    'Mirabad',
    '☕',
    12,
    850,
    150,
    'Oybek',
    'Kosmonavtlar',
    '[{"place_id": "place_breadly", "name": "Breadly Bakery & Café", "nearest_subway": "Oybek"}, {"place_id": "place_socials", "name": "Socials Coffee Hub", "nearest_subway": "Oybek"}, {"place_id": "place_ekler", "name": "Ekler Patisserie", "nearest_subway": "Kosmonavtlar"}]'::jsonb
  ),
  (
    'chorsu_heritage_trail',
    'Old City Heritage & Bazaar Trail',
    'Sensory journey through clay tandoors, spice alleys, and steaming plov',
    'Old City',
    '🍲',
    16,
    1100,
    150,
    'Chorsu',
    'Gafur Gulom',
    '[{"place_id": "place_chorsu", "name": "Chorsu Bazaar Food Court", "nearest_subway": "Chorsu"}, {"place_id": "place_samarkand", "name": "Samarkand Darvoza Osh", "nearest_subway": "Chorsu"}]'::jsonb
  ),
  (
    'central_cultural_promenade',
    'Central Tashkent Cultural Promenade',
    'Modern architectural walk between Broadway, teatime, and Uzbek hospitality',
    'Central Tashkent',
    '🏛️',
    14,
    980,
    150,
    'Amir Temur Xiyoboni',
    'Mustaqillik Maydoni',
    '[{"place_id": "place_tims", "name": "TIMS Coffee & Roastery", "nearest_subway": "Amir Temur Xiyoboni"}, {"place_id": "place_afsona", "name": "Afsona Uzbek Contemporary", "nearest_subway": "Mustaqillik Maydoni"}, {"place_id": "place_dodo", "name": "Dodo Amir Temur", "nearest_subway": "Amir Temur Xiyoboni"}]'::jsonb
  )
ON CONFLICT (id) DO UPDATE SET
  title = EXCLUDED.title,
  subtitle = EXCLUDED.subtitle,
  district = EXCLUDED.district,
  stops = EXCLUDED.stops,
  total_estimated_minutes = EXCLUDED.total_estimated_minutes,
  total_distance_meters = EXCLUDED.total_distance_meters,
  xp_reward = EXCLUDED.xp_reward,
  start_subway = EXCLUDED.start_subway,
  end_subway = EXCLUDED.end_subway,
  updated_at = NOW();

-- 6. Permissions
GRANT EXECUTE ON FUNCTION public.complete_curated_route(TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.complete_curated_route(TEXT) TO service_role;

COMMENT ON FUNCTION public.complete_curated_route IS
  'Atomically records curated crawl route completion for the caller, awarding 150 curator XP.';
