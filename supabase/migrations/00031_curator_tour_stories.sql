-- Migration 00031: Curator Audio Walking Tours & Multi-Stop Venue Narratives
-- Enables local curators to publish sequential audio walking tours with geotargeted chapter triggers.

CREATE TABLE IF NOT EXISTS public.curator_tours (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  creator_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  title TEXT NOT NULL CHECK (char_length(trim(title)) BETWEEN 2 AND 150),
  subtitle TEXT NOT NULL DEFAULT '' CHECK (char_length(subtitle) <= 300),
  district TEXT NOT NULL DEFAULT 'Mirabad' CHECK (char_length(district) <= 80),
  cover_image_url TEXT,
  estimated_walking_minutes INTEGER NOT NULL DEFAULT 45 CHECK (estimated_walking_minutes >= 5),
  xp_reward INTEGER NOT NULL DEFAULT 100 CHECK (xp_reward >= 0),
  privacy TEXT NOT NULL DEFAULT 'public' CHECK (privacy IN ('public', 'friends', 'private')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.tour_stop_stories (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tour_id UUID NOT NULL REFERENCES public.curator_tours(id) ON DELETE CASCADE,
  chapter_index INTEGER NOT NULL CHECK (chapter_index >= 1),
  title TEXT NOT NULL CHECK (char_length(trim(title)) BETWEEN 2 AND 150),
  place_id UUID REFERENCES public.places(id) ON DELETE SET NULL,
  venue_name TEXT NOT NULL CHECK (char_length(trim(venue_name)) > 0),
  latitude NUMERIC(9, 6) NOT NULL,
  longitude NUMERIC(9, 6) NOT NULL,
  trigger_radius_meters NUMERIC(6, 1) NOT NULL DEFAULT 50.0 CHECK (trigger_radius_meters >= 10.0),
  audio_url TEXT NOT NULL CHECK (char_length(trim(audio_url)) > 0),
  duration_seconds INTEGER NOT NULL CHECK (duration_seconds >= 10 AND duration_seconds <= 900),
  transcript TEXT NOT NULL DEFAULT '',
  curator_notes TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT unique_tour_chapter_index UNIQUE (tour_id, chapter_index)
);

-- Fast query indexes
CREATE INDEX IF NOT EXISTS idx_curator_tours_creator ON public.curator_tours(creator_id);
CREATE INDEX IF NOT EXISTS idx_curator_tours_district ON public.curator_tours(district);
CREATE INDEX IF NOT EXISTS idx_tour_stop_stories_tour ON public.tour_stop_stories(tour_id, chapter_index ASC);

-- Enable Row-Level Security
ALTER TABLE public.curator_tours ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tour_stop_stories ENABLE ROW LEVEL SECURITY;

-- Read policy: Public tours readable if author privacy allows
CREATE POLICY "Public curator tours readable by everyone"
  ON public.curator_tours
  FOR SELECT
  USING (
    (
      privacy = 'public'
      AND EXISTS (
        SELECT 1 FROM public.profiles p
        WHERE p.id = curator_tours.creator_id
          AND COALESCE(p.hide_visits_history, false) = false
      )
    )
    OR (auth.uid() = creator_id)
  );

CREATE POLICY "Public tour stop stories readable by everyone"
  ON public.tour_stop_stories
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.curator_tours t
      WHERE t.id = tour_stop_stories.tour_id
        AND (
          t.privacy = 'public'
          OR t.creator_id = auth.uid()
        )
    )
  );

-- Mutation policies: Only tour creator can insert/update/delete
CREATE POLICY "Creators can insert their own tours"
  ON public.curator_tours
  FOR INSERT
  WITH CHECK (auth.uid() = creator_id);

CREATE POLICY "Creators can update their own tours"
  ON public.curator_tours
  FOR UPDATE
  USING (auth.uid() = creator_id);

CREATE POLICY "Creators can delete their own tours"
  ON public.curator_tours
  FOR DELETE
  USING (auth.uid() = creator_id);

CREATE POLICY "Creators can manage stops for their tours"
  ON public.tour_stop_stories
  FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM public.curator_tours t
      WHERE t.id = tour_stop_stories.tour_id
        AND t.creator_id = auth.uid()
    )
  );

-- RPC: Get tour details with ordered chapters and author metadata
CREATE OR REPLACE FUNCTION public.get_curator_tour_details(p_tour_id UUID)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
  v_tour RECORD;
  v_chapters JSONB := '[]'::jsonb;
BEGIN
  -- Retrieve tour header
  SELECT
    t.id,
    t.title,
    t.subtitle,
    t.district,
    t.cover_image_url,
    t.estimated_walking_minutes,
    t.xp_reward,
    t.creator_id,
    COALESCE(p.full_name, p.username, 'Curator') AS curator_name,
    p.avatar_url AS curator_avatar_url
  INTO v_tour
  FROM public.curator_tours t
  JOIN public.profiles p ON p.id = t.creator_id
  WHERE t.id = p_tour_id
    AND (
      t.privacy = 'public'
      OR t.creator_id = auth.uid()
    );

  IF NOT FOUND THEN
    RETURN jsonb_build_object(
      'success', false,
      'error', 'Curator tour not found or access restricted.'
    );
  END IF;

  -- Aggregate chapter stops in sequence
  SELECT
    COALESCE(
      jsonb_agg(
        jsonb_build_object(
          'id', s.id,
          'tour_id', s.tour_id,
          'chapter_index', s.chapter_index,
          'title', s.title,
          'venue_id', COALESCE(s.place_id::text, ''),
          'venue_name', s.venue_name,
          'latitude', s.latitude,
          'longitude', s.longitude,
          'trigger_radius_meters', s.trigger_radius_meters,
          'audio_url', s.audio_url,
          'duration_seconds', s.duration_seconds,
          'transcript', s.transcript,
          'curator_notes', s.curator_notes
        ) ORDER BY s.chapter_index ASC
      ),
      '[]'::jsonb
    )
  INTO v_chapters
  FROM public.tour_stop_stories s
  WHERE s.tour_id = p_tour_id;

  RETURN jsonb_build_object(
    'success', true,
    'tour', jsonb_build_object(
      'id', v_tour.id,
      'title', v_tour.title,
      'subtitle', v_tour.subtitle,
      'district', v_tour.district,
      'cover_image_url', v_tour.cover_image_url,
      'estimated_walking_minutes', v_tour.estimated_walking_minutes,
      'xp_reward', v_tour.xp_reward,
      'curator_id', v_tour.creator_id,
      'curator_name', v_tour.curator_name,
      'curator_avatar_url', v_tour.curator_avatar_url,
      'stops', v_chapters
    )
  );
END;
$$;

-- Grant execution to authenticated users and anonymous visitors
GRANT EXECUTE ON FUNCTION public.get_curator_tour_details(UUID) TO authenticated, anon;
