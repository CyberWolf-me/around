-- Migration 00027: Venue Atmosphere Soundscape Presets
-- Adds ambient soundscape metadata to places table and provides get_venue_soundscape_preset RPC.

ALTER TABLE public.places
  ADD COLUMN IF NOT EXISTS soundscape_preset TEXT DEFAULT 'espresso_murmur',
  ADD COLUMN IF NOT EXISTS ambient_volume NUMERIC(3, 2) DEFAULT 0.65;

-- Update seed venues with context-appropriate soundscapes
UPDATE public.places
SET soundscape_preset = 'oriental_bazaar', ambient_volume = 0.60
WHERE name ILIKE '%chorsu%' OR category ILIKE '%market%' OR category ILIKE '%bazaar%';

UPDATE public.places
SET soundscape_preset = 'courtyard_fountain', ambient_volume = 0.50
WHERE name ILIKE '%kukeldash%' OR category ILIKE '%park%' OR category ILIKE '%courtyard%';

UPDATE public.places
SET soundscape_preset = 'espresso_murmur', ambient_volume = 0.65
WHERE name ILIKE '%breadly%' OR category ILIKE '%coffee%' OR category ILIKE '%cafe%';

-- RPC to retrieve soundscape preset for a venue
CREATE OR REPLACE FUNCTION public.get_venue_soundscape_preset(p_place_id UUID)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
  v_place_name TEXT;
  v_category TEXT;
  v_preset TEXT;
  v_volume NUMERIC(3, 2);
BEGIN
  SELECT
    name,
    category,
    COALESCE(soundscape_preset, 'espresso_murmur'),
    COALESCE(ambient_volume, 0.65)
  INTO
    v_place_name,
    v_category,
    v_preset,
    v_volume
  FROM public.places
  WHERE id = p_place_id;

  IF NOT FOUND THEN
    RETURN jsonb_build_object(
      'success', false,
      'error', 'Place not found.'
    );
  END IF;

  RETURN jsonb_build_object(
    'success', true,
    'place_id', p_place_id,
    'place_name', v_place_name,
    'category', v_category,
    'soundscape_preset', v_preset,
    'ambient_volume', v_volume
  );
END;
$$;

-- Grant execution to authenticated users and anonymous visitors
GRANT EXECUTE ON FUNCTION public.get_venue_soundscape_preset(UUID) TO authenticated, anon;
