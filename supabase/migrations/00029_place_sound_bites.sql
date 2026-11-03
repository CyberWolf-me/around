-- Migration 00029: Place Sound Bites & Courtyard Voice Notes Schema & RPC
-- Enables community audio impressions attached to places with dual-layer privacy protection.

CREATE TABLE IF NOT EXISTS public.place_sound_bites (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  place_id UUID NOT NULL REFERENCES public.places(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  audio_url TEXT NOT NULL CHECK (char_length(trim(audio_url)) > 0),
  duration_seconds INTEGER NOT NULL CHECK (duration_seconds >= 2 AND duration_seconds <= 45),
  waveform_data NUMERIC[] NOT NULL DEFAULT '{}',
  transcription_snippet TEXT CHECK (transcription_snippet IS NULL OR char_length(transcription_snippet) <= 300),
  category_tag TEXT NOT NULL DEFAULT 'ambient' CHECK (category_tag IN ('ambient', 'barista_tip', 'history', 'whisper')),
  likes_count INTEGER NOT NULL DEFAULT 0 CHECK (likes_count >= 0),
  privacy TEXT NOT NULL DEFAULT 'public' CHECK (privacy IN ('public', 'friends', 'private')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Indexes for lightning-fast retrieval
CREATE INDEX IF NOT EXISTS idx_place_sound_bites_place ON public.place_sound_bites(place_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_place_sound_bites_user ON public.place_sound_bites(user_id);

-- Enable Row-Level Security
ALTER TABLE public.place_sound_bites ENABLE ROW LEVEL SECURITY;

-- Read policy: Public bites readable if author does not hide visits history
CREATE POLICY "Public sound bites readable by everyone"
  ON public.place_sound_bites
  FOR SELECT
  USING (
    (
      privacy = 'public'
      AND EXISTS (
        SELECT 1 FROM public.profiles p
        WHERE p.id = place_sound_bites.user_id
          AND COALESCE(p.hide_visits_history, false) = false
      )
    )
    OR (auth.uid() = user_id)
  );

-- Insert policy: Caller must match auth.uid()
CREATE POLICY "Users can create their own place sound bites"
  ON public.place_sound_bites
  FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Update policy: Author only
CREATE POLICY "Users can update their own sound bites"
  ON public.place_sound_bites
  FOR UPDATE
  USING (auth.uid() = user_id);

-- Delete policy: Author only
CREATE POLICY "Users can delete their own sound bites"
  ON public.place_sound_bites
  FOR DELETE
  USING (auth.uid() = user_id);

-- RPC: Get place sound bites with author metadata
CREATE OR REPLACE FUNCTION public.get_place_sound_bites(
  p_place_id UUID,
  p_limit INTEGER DEFAULT 10
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
  v_limit INTEGER := LEAST(GREATEST(COALESCE(p_limit, 10), 1), 30);
  v_bites JSONB := '[]'::jsonb;
  v_count INTEGER := 0;
BEGIN
  WITH bites AS (
    SELECT
      sb.id,
      sb.place_id,
      pl.name AS place_name,
      pl.district,
      sb.user_id AS author_id,
      COALESCE(p.full_name, p.username, 'Curator') AS author_name,
      p.avatar_url AS author_avatar_url,
      sb.audio_url,
      sb.duration_seconds,
      sb.waveform_data,
      sb.transcription_snippet,
      sb.category_tag,
      sb.likes_count,
      sb.created_at
    FROM public.place_sound_bites sb
    JOIN public.places pl ON pl.id = sb.place_id
    JOIN public.profiles p ON p.id = sb.user_id
    WHERE
      sb.place_id = p_place_id
      AND sb.privacy = 'public'
      AND COALESCE(p.hide_visits_history, false) = false
    ORDER BY sb.created_at DESC
    LIMIT v_limit
  )
  SELECT
    COALESCE(
      jsonb_agg(
        jsonb_build_object(
          'id', b.id,
          'place_id', b.place_id,
          'place_name', b.place_name,
          'district', b.district,
          'author_id', b.author_id,
          'author_name', b.author_name,
          'author_avatar_url', b.author_avatar_url,
          'audio_url', b.audio_url,
          'duration_seconds', b.duration_seconds,
          'waveform_amplitudes', to_jsonb(b.waveform_data),
          'transcription_snippet', b.transcription_snippet,
          'category_tag', b.category_tag,
          'likes_count', b.likes_count,
          'created_at', b.created_at
        ) ORDER BY b.created_at DESC
      ),
      '[]'::jsonb
    ),
    COUNT(*)
  INTO
    v_bites,
    v_count
  FROM bites b;

  RETURN jsonb_build_object(
    'success', true,
    'place_id', p_place_id,
    'count', v_count,
    'sound_bites', v_bites
  );
END;
$$;

-- Grant execution to authenticated users and anonymous visitors
GRANT EXECUTE ON FUNCTION public.get_place_sound_bites(UUID, INTEGER) TO authenticated, anon;
