-- Migration 00030: Metro Station Passport Stamps & Check-In Seals Schema & RPC
-- Enables explorers to collect ceramic stamps for visiting stations and venues across the Tashkent Metro network.

CREATE TABLE IF NOT EXISTS public.user_metro_stamps (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  station_id TEXT NOT NULL CHECK (char_length(trim(station_id)) BETWEEN 2 AND 80),
  line TEXT NOT NULL CHECK (line IN ('chilanzar', 'uzbekistan', 'yunusabad')),
  place_id UUID REFERENCES public.places(id) ON DELETE SET NULL,
  xp_awarded INTEGER NOT NULL DEFAULT 25 CHECK (xp_awarded >= 0),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT unique_user_station_stamp UNIQUE (user_id, station_id)
);

-- Indexes for instant profile stamp book queries
CREATE INDEX IF NOT EXISTS idx_user_metro_stamps_user ON public.user_metro_stamps(user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_user_metro_stamps_station ON public.user_metro_stamps(station_id);

-- Enable Row-Level Security
ALTER TABLE public.user_metro_stamps ENABLE ROW LEVEL SECURITY;

-- Read policy: Owner can always view; others can view if user has hide_visits_history = false
CREATE POLICY "Metro stamps readable if privacy allows"
  ON public.user_metro_stamps
  FOR SELECT
  USING (
    auth.uid() = user_id
    OR EXISTS (
      SELECT 1 FROM public.profiles p
      WHERE p.id = user_metro_stamps.user_id
        AND COALESCE(p.hide_visits_history, false) = false
    )
  );

-- Insert policy: Caller must match auth.uid()
CREATE POLICY "Users can only claim stamps for themselves"
  ON public.user_metro_stamps
  FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Delete policy: Owner only
CREATE POLICY "Users can delete their own stamps"
  ON public.user_metro_stamps
  FOR DELETE
  USING (auth.uid() = user_id);

-- RPC: Claim a metro station passport stamp
CREATE OR REPLACE FUNCTION public.claim_metro_station_stamp(
  p_station_id TEXT,
  p_place_id UUID DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
  v_user_id UUID := auth.uid();
  v_station_id TEXT := LOWER(TRIM(p_station_id));
  v_line TEXT;
  v_stamp_id UUID;
  v_is_new BOOLEAN := false;
  v_xp INTEGER := 25;
BEGIN
  IF v_user_id IS NULL THEN
    RETURN jsonb_build_object(
      'success', false,
      'error', 'Authentication required to claim metro stamps.'
    );
  END IF;

  -- Determine line by station identifier
  CASE v_station_id
    WHEN 'mustaqillik_maydoni', 'amir_temur_xiyoboni', 'paxtakor', 'novza' THEN
      v_line := 'chilanzar';
    WHEN 'kosmonavtlar', 'alisher_navoiy', 'chorsu', 'oybek' THEN
      v_line := 'uzbekistan';
    WHEN 'ming_urik', 'bodomzor', 'shahriston', 'yunus_rajabiy' THEN
      v_line := 'yunusabad';
    ELSE
      v_line := 'uzbekistan';
  END CASE;

  -- Insert stamp idempotently
  INSERT INTO public.user_metro_stamps (
    user_id,
    station_id,
    line,
    place_id,
    xp_awarded
  ) VALUES (
    v_user_id,
    v_station_id,
    v_line,
    p_place_id,
    v_xp
  )
  ON CONFLICT (user_id, station_id) DO NOTHING
  RETURNING id INTO v_stamp_id;

  IF v_stamp_id IS NOT NULL THEN
    v_is_new := true;
    -- Award curator XP to user profile
    UPDATE public.profiles
    SET experience_points = COALESCE(experience_points, 0) + v_xp
    WHERE id = v_user_id;
  END IF;

  RETURN jsonb_build_object(
    'success', true,
    'station_id', v_station_id,
    'line', v_line,
    'is_new_claim', v_is_new,
    'xp_awarded', CASE WHEN v_is_new THEN v_xp ELSE 0 END,
    'claimed_at', NOW()
  );
END;
$$;

-- Grant execution to authenticated users
GRANT EXECUTE ON FUNCTION public.claim_metro_station_stamp(TEXT, UUID) TO authenticated;
