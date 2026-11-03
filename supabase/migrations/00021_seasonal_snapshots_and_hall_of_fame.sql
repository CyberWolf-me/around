-- Migration 00021: Historical Season Snapshots & Tashkent Hall of Fame
-- Permanently stores monthly district champions, laurels, and crowns with public read access.

-- 1. Season Hall of Fame Table
CREATE TABLE IF NOT EXISTS public.season_hall_of_fame (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  season_id TEXT NOT NULL CHECK (char_length(trim(season_id)) BETWEEN 7 AND 10),
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  district TEXT NOT NULL CHECK (char_length(trim(district)) BETWEEN 2 AND 50),
  rank INTEGER NOT NULL CHECK (rank >= 1),
  season_xp INTEGER NOT NULL DEFAULT 0,
  places_count INTEGER NOT NULL DEFAULT 0,
  laurel TEXT NOT NULL CHECK (laurel IN ('champion', 'podium', 'topTen', 'explorer')),
  archived_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT unique_season_district_user UNIQUE(season_id, district, user_id)
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_hall_of_fame_season ON public.season_hall_of_fame(season_id);
CREATE INDEX IF NOT EXISTS idx_hall_of_fame_district ON public.season_hall_of_fame(district);
CREATE INDEX IF NOT EXISTS idx_hall_of_fame_user ON public.season_hall_of_fame(user_id);

-- 2. Row-Level Security
ALTER TABLE public.season_hall_of_fame ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
  -- Hall of Fame entries are public achievement records across Tashkent
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'season_hall_of_fame' AND policyname = 'season_hall_of_fame_read'
  ) THEN
    CREATE POLICY season_hall_of_fame_read ON public.season_hall_of_fame
      FOR SELECT USING (TRUE);
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'season_hall_of_fame' AND policyname = 'season_hall_of_fame_insert'
  ) THEN
    CREATE POLICY season_hall_of_fame_insert ON public.season_hall_of_fame
      FOR INSERT WITH CHECK (auth.uid() = user_id);
  END IF;
END $$;

-- 3. Idempotent Archive Season Standing RPC
CREATE OR REPLACE FUNCTION public.archive_season_standing(
  p_season_id TEXT,
  p_district TEXT,
  p_rank INTEGER,
  p_season_xp INTEGER,
  p_places_count INTEGER DEFAULT 0,
  p_laurel TEXT DEFAULT 'explorer'
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
  v_uid UUID;
  v_entry_id UUID;
  v_clean_season TEXT;
  v_clean_district TEXT;
  v_clean_laurel TEXT;
  v_rank INTEGER;
BEGIN
  -- Strict caller identity binding (Rule C)
  v_uid := auth.uid();
  IF v_uid IS NULL THEN
    RETURN jsonb_build_object('success', false, 'error', 'Authentication required to archive season standing.');
  END IF;

  v_clean_season := trim(COALESCE(p_season_id, ''));
  IF char_length(v_clean_season) = 0 THEN
    RETURN jsonb_build_object('success', false, 'error', 'Season ID must not be empty.');
  END IF;

  v_clean_district := trim(COALESCE(p_district, 'Mirabad'));
  v_rank := GREATEST(1, COALESCE(p_rank, 1));
  v_clean_laurel := LOWER(trim(COALESCE(p_laurel, 'explorer')));

  IF v_clean_laurel NOT IN ('champion', 'podium', 'topTen', 'explorer') THEN
    v_clean_laurel := 'explorer';
  END IF;

  -- Upsert into Hall of Fame archive
  INSERT INTO public.season_hall_of_fame (
    season_id,
    user_id,
    district,
    rank,
    season_xp,
    places_count,
    laurel
  ) VALUES (
    v_clean_season,
    v_uid,
    v_clean_district,
    v_rank,
    GREATEST(0, COALESCE(p_season_xp, 0)),
    GREATEST(0, COALESCE(p_places_count, 0)),
    v_clean_laurel
  )
  ON CONFLICT (season_id, district, user_id)
  DO UPDATE SET
    rank = EXCLUDED.rank,
    season_xp = EXCLUDED.season_xp,
    places_count = EXCLUDED.places_count,
    laurel = EXCLUDED.laurel,
    archived_at = NOW()
  RETURNING id INTO v_entry_id;

  -- If district champion, award crown to profile
  IF v_rank = 1 AND v_clean_laurel = 'champion' THEN
    UPDATE public.profiles
    SET crowns_count = COALESCE(crowns_count, 0) + 1
    WHERE id = v_uid;
  END IF;

  RETURN jsonb_build_object(
    'success', true,
    'entry_id', v_entry_id,
    'season_id', v_clean_season,
    'district', v_clean_district,
    'rank', v_rank,
    'laurel', v_clean_laurel
  );
END;
$$;

-- 4. Permissions
GRANT SELECT ON TABLE public.season_hall_of_fame TO anon, authenticated;
GRANT INSERT, UPDATE ON TABLE public.season_hall_of_fame TO authenticated;
GRANT EXECUTE ON FUNCTION public.archive_season_standing(TEXT, TEXT, INTEGER, INTEGER, INTEGER, TEXT) TO authenticated;
