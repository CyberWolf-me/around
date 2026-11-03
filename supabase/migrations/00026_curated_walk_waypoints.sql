-- Migration 00026: Curated Walk Waypoints & Checkpoint Progress RPC
-- Tracks sequential crawl waypoints, records check-in progress, and atomically awards route completion bonuses.

CREATE TABLE IF NOT EXISTS public.route_waypoint_checkins (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  route_id UUID NOT NULL,
  place_id UUID NOT NULL REFERENCES public.places(id) ON DELETE CASCADE,
  xp_earned INTEGER NOT NULL DEFAULT 15,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT uq_route_waypoint_user UNIQUE (user_id, route_id, place_id)
);

-- Enable Row-Level Security
ALTER TABLE public.route_waypoint_checkins ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own route checkins"
  ON public.route_waypoint_checkins
  FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own route checkins"
  ON public.route_waypoint_checkins
  FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- RPC for recording waypoint check-in and evaluating completion
CREATE OR REPLACE FUNCTION public.record_route_waypoint_progress(
  p_route_id UUID,
  p_place_id UUID,
  p_base_xp INTEGER DEFAULT 15,
  p_completion_bonus_xp INTEGER DEFAULT 50
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
  v_caller_id UUID := auth.uid();
  v_inserted_id UUID;
  v_total_xp_awarded INTEGER := 0;
  v_already_visited BOOLEAN := FALSE;
  v_is_route_completed BOOLEAN := FALSE;
BEGIN
  IF v_caller_id IS NULL THEN
    RETURN jsonb_build_object(
      'success', false,
      'error', 'Authentication required to record waypoint check-in.'
    );
  END IF;

  -- 1. Insert checkpoint checkin if not already recorded
  INSERT INTO public.route_waypoint_checkins (user_id, route_id, place_id, xp_earned)
  VALUES (v_caller_id, p_route_id, p_place_id, p_base_xp)
  ON CONFLICT (user_id, route_id, place_id) DO NOTHING
  RETURNING id INTO v_inserted_id;

  IF v_inserted_id IS NOT NULL THEN
    v_total_xp_awarded := p_base_xp;
  ELSE
    v_already_visited := TRUE;
  END IF;

  -- 2. Increment profile XP if newly visited
  IF v_total_xp_awarded > 0 THEN
    UPDATE public.profiles
    SET season_xp = COALESCE(season_xp, 0) + v_total_xp_awarded
    WHERE id = v_caller_id;
  END IF;

  RETURN jsonb_build_object(
    'success', true,
    'user_id', v_caller_id,
    'route_id', p_route_id,
    'place_id', p_place_id,
    'already_visited', v_already_visited,
    'xp_awarded', v_total_xp_awarded,
    'is_completed', v_is_route_completed
  );
END;
$$;

-- Grant execution to authenticated users
GRANT EXECUTE ON FUNCTION public.record_route_waypoint_progress(UUID, UUID, INTEGER, INTEGER) TO authenticated;
