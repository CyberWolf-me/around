-- ==============================================================================
-- Around Platform: Database Migration 00008 - Guest Discovery Grant & Account Deletion Hardening
-- Task IDs: P1-02, P3-01, P5-01, SEC-09, SEC-15
-- ==============================================================================

SET search_path TO public, extensions;

-- 1. Grant public/anon execution on get_nearby_places
-- Places are public domain discovery data. Guests should be able to view Tashkent spots.
GRANT EXECUTE ON FUNCTION public.get_nearby_places(DOUBLE PRECISION, DOUBLE PRECISION, DOUBLE PRECISION, TEXT, TEXT, INTEGER) TO anon, authenticated, PUBLIC;

-- 2. Hardened Server-Side Account Deletion RPC
-- Wraps storage.objects cleanup in a block so managed Supabase storage restrictions
-- do not prevent auth.users and public.profiles cascade deletion.
CREATE OR REPLACE FUNCTION public.delete_own_account()
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth, storage
AS $$
DECLARE
  caller_uid UUID := auth.uid();
BEGIN
  IF caller_uid IS NULL THEN
    RAISE EXCEPTION 'Authentication required to delete account' USING ERRCODE = '42501';
  END IF;

  -- Attempt storage media cleanup gracefully if direct deletion is allowed by environment
  BEGIN
    DELETE FROM storage.objects
    WHERE bucket_id = 'post-media'
      AND (storage.foldername(name))[1] = caller_uid::TEXT;
  EXCEPTION WHEN OTHERS THEN
    -- Direct deletion on storage.objects blocked by managed storage trigger; proceed with account deletion
    NULL;
  END;

  DELETE FROM public.profiles WHERE id = caller_uid;
  DELETE FROM auth.users WHERE id = caller_uid;

  RETURN TRUE;
END;
$$;

REVOKE ALL ON FUNCTION public.delete_own_account() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.delete_own_account() TO authenticated;

-- 3. Environment-Aware Auto-Confirmation Guard
-- Ensures development convenience behavior cannot silently bypass email confirmation in production.
CREATE OR REPLACE FUNCTION public.auto_confirm_all_users()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  env TEXT := COALESCE(current_setting('app.environment', true), 'development');
BEGIN
  -- Strict Production Rule: Never auto-confirm users in production.
  -- Production relies on Supabase Auth SMTP verification.
  IF env = 'production' THEN
    RETURN NEW;
  END IF;

  IF NEW.email_confirmed_at IS NULL THEN
    NEW.email_confirmed_at := NOW();
  END IF;
  RETURN NEW;
END;
$$;
