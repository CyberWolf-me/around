-- ==============================================================================
-- Around Platform: Database Migration 00007 - Auto-Confirm Users & Public Profile Triggers
-- ==============================================================================

SET search_path TO public, extensions;

-- Auto-confirm any newly signed-up user in development / staging
-- so physical mobile device testers can register and sign in immediately
-- without requiring third-party transactional SMTP setup.
CREATE OR REPLACE FUNCTION public.auto_confirm_all_users()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NEW.email_confirmed_at IS NULL THEN
    NEW.email_confirmed_at := NOW();
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_auto_confirm_users ON auth.users;
CREATE TRIGGER trg_auto_confirm_users
  BEFORE INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.auto_confirm_all_users();
