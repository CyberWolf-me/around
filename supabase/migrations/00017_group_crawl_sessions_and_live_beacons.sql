-- Migration 00017: Group Crawl Sessions & Live Venue Beacons
-- Establishes synchronized group walking crawl rooms with discrete venue beacons
-- strictly preserving caller identity via auth.uid() and zero raw GPS storage.

-- 1. Group Crawl Sessions Table
CREATE TABLE IF NOT EXISTS public.group_crawl_sessions (
  session_code TEXT PRIMARY KEY CHECK (char_length(trim(session_code)) BETWEEN 6 AND 20),
  route_id TEXT NOT NULL REFERENCES public.curated_routes(id) ON DELETE CASCADE,
  route_title TEXT NOT NULL CHECK (char_length(trim(route_title)) BETWEEN 2 AND 120),
  host_user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  squad_bonus_xp INTEGER NOT NULL DEFAULT 200,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 2. Group Crawl Participants Table
CREATE TABLE IF NOT EXISTS public.group_crawl_participants (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  session_code TEXT NOT NULL REFERENCES public.group_crawl_sessions(session_code) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  current_place_id TEXT CHECK (current_place_id IS NULL OR char_length(trim(current_place_id)) <= 100),
  visited_stop_ids TEXT[] NOT NULL DEFAULT ARRAY[]::TEXT[],
  is_host BOOLEAN NOT NULL DEFAULT FALSE,
  last_active TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT unique_session_participant UNIQUE(session_code, user_id)
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_crawl_sessions_host ON public.group_crawl_sessions(host_user_id);
CREATE INDEX IF NOT EXISTS idx_crawl_participants_session ON public.group_crawl_participants(session_code);
CREATE INDEX IF NOT EXISTS idx_crawl_participants_user ON public.group_crawl_participants(user_id);

-- 3. Row-Level Security
ALTER TABLE public.group_crawl_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.group_crawl_participants ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'group_crawl_sessions' AND policyname = 'group_crawl_sessions_read'
  ) THEN
    CREATE POLICY group_crawl_sessions_read ON public.group_crawl_sessions
      FOR SELECT USING (is_active = TRUE);
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'group_crawl_sessions' AND policyname = 'group_crawl_sessions_host_insert'
  ) THEN
    CREATE POLICY group_crawl_sessions_host_insert ON public.group_crawl_sessions
      FOR INSERT WITH CHECK (auth.uid() = host_user_id);
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'group_crawl_sessions' AND policyname = 'group_crawl_sessions_host_update'
  ) THEN
    CREATE POLICY group_crawl_sessions_host_update ON public.group_crawl_sessions
      FOR UPDATE USING (auth.uid() = host_user_id);
  END IF;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'group_crawl_participants' AND policyname = 'group_crawl_participants_read'
  ) THEN
    CREATE POLICY group_crawl_participants_read ON public.group_crawl_participants
      FOR SELECT USING (
        auth.uid() = user_id
        OR session_code IN (
          SELECT gcp.session_code FROM public.group_crawl_participants gcp
          WHERE gcp.user_id = auth.uid()
        )
      );
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'group_crawl_participants' AND policyname = 'group_crawl_participants_write'
  ) THEN
    CREATE POLICY group_crawl_participants_write ON public.group_crawl_participants
      FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
  END IF;
END $$;

-- 4. Idempotent Join or Update Group Crawl RPC
CREATE OR REPLACE FUNCTION public.join_or_update_group_crawl(
  p_session_code TEXT,
  p_current_place_id TEXT DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
  v_uid UUID;
  v_session public.group_crawl_sessions%ROWTYPE;
  v_is_host BOOLEAN;
  v_visited TEXT[];
  v_participants_json jsonb;
BEGIN
  -- Strict caller identity binding (Security Rule C)
  v_uid := auth.uid();
  IF v_uid IS NULL THEN
    RETURN jsonb_build_object('success', false, 'error', 'Authentication required to join crawl session.');
  END IF;

  -- Verify session exists and is active
  SELECT * INTO v_session
  FROM public.group_crawl_sessions
  WHERE session_code = trim(p_session_code) AND is_active = TRUE;

  IF NOT FOUND THEN
    RETURN jsonb_build_object('success', false, 'error', 'Active crawl session not found.');
  END IF;

  v_is_host := (v_session.host_user_id = v_uid);

  -- Fetch existing visited stops if already in session
  SELECT visited_stop_ids INTO v_visited
  FROM public.group_crawl_participants
  WHERE session_code = v_session.session_code AND user_id = v_uid;

  IF v_visited IS NULL THEN
    v_visited := ARRAY[]::TEXT[];
  END IF;

  IF p_current_place_id IS NOT NULL AND trim(p_current_place_id) <> '' THEN
    IF NOT (trim(p_current_place_id) = ANY(v_visited)) THEN
      v_visited := array_append(v_visited, trim(p_current_place_id));
    END IF;
  END IF;

  -- Upsert participant state
  INSERT INTO public.group_crawl_participants (
    session_code,
    user_id,
    current_place_id,
    visited_stop_ids,
    is_host,
    last_active
  ) VALUES (
    v_session.session_code,
    v_uid,
    NULLIF(trim(p_current_place_id), ''),
    v_visited,
    v_is_host,
    NOW()
  )
  ON CONFLICT (session_code, user_id) DO UPDATE SET
    current_place_id = COALESCE(NULLIF(trim(EXCLUDED.current_place_id), ''), group_crawl_participants.current_place_id),
    visited_stop_ids = v_visited,
    last_active = NOW();

  -- Aggregate active squad participants
  SELECT jsonb_agg(
    jsonb_build_object(
      'user_id', p.id,
      'name', p.full_name,
      'avatar_initials', UPPER(SUBSTRING(p.full_name, 1, 2)),
      'current_place_id', gcp.current_place_id,
      'visited_stop_ids', gcp.visited_stop_ids,
      'is_host', gcp.is_host,
      'last_active', gcp.last_active
    )
  ) INTO v_participants_json
  FROM public.group_crawl_participants gcp
  JOIN public.profiles p ON p.id = gcp.user_id
  WHERE gcp.session_code = v_session.session_code;

  RETURN jsonb_build_object(
    'success', true,
    'session_code', v_session.session_code,
    'route_id', v_session.route_id,
    'route_title', v_session.route_title,
    'squad_bonus_xp', v_session.squad_bonus_xp,
    'participants', COALESCE(v_participants_json, '[]'::jsonb)
  );
END;
$$;

-- Grants
GRANT EXECUTE ON FUNCTION public.join_or_update_group_crawl(TEXT, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.join_or_update_group_crawl(TEXT, TEXT) TO service_role;

COMMENT ON FUNCTION public.join_or_update_group_crawl IS
  'Joins or updates venue check-in state in an active group crawl session bound to auth.uid().';
