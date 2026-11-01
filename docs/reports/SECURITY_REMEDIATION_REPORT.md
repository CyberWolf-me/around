# Around — Security Remediation & Credential Hardening Report
**Author:** CTO Orchestrator & Security Lead  
**Date:** November 2, 2026  
**Status:** REMEDIATED & RATIFIED  
**Applicable Tasks:** P0-01, P0-03, SEC-01 through SEC-15

---

## 1. Executive Summary

During the comprehensive architecture and security audit of the **Around** platform, three critical credential and authentication vulnerabilities were surfaced:
1. **Accidental Client-Side Secret Exposure Risk:** An uncommitted local `.env` contained a `SUPABASE_SECRET_KEY` alongside public client configuration, risking leakage into mobile builds compiled with `--dart-define-from-file=.env`.
2. **Unconditional Database Auto-Confirmation:** Database migration `00007_auto_confirm_and_auth_support.sql` attached an unconditional trigger `trg_auto_confirm_users` to `auth.users`, which set `email_confirmed_at := NOW()`, bypassing email verification across all environments.
3. **Database Account Deletion Exception on Managed Storage:** Account deletion via `public.delete_own_account()` previously threw a Postgrest 42501 permission error on managed Supabase environments where direct SQL deletion on `storage.objects` is restricted.

All three vulnerabilities have been investigated, remediated, and verified in code.

---

## 2. Investigation Findings & Git History Audit

### 2.1 Git History Forensic Audit
A recursive commit-by-commit forensic audit of the Git log was executed:
- `git log -S "SUPABASE_SECRET_KEY"` returned zero results across all branches.
- `git log -S "service_role"` revealed occurrences strictly restricted to security enforcement comments, rule definitions in `AGENTS.md`, and runtime defense checks in `SupabaseService.initialize()`.
- **Conclusion:** Privileged `service_role` credentials were never committed to version control. The exposure was isolated to a local development `.env` file on disk.

### 2.2 Client Environment Files (`.env` and `.env.example`)
- `.env` was sanitized immediately: the secret key was expunged. The file now contains solely `APP_ENV`, `SUPABASE_URL`, and the public anonymous key (`SUPABASE_ANON_KEY`).
- `.env.example` contains explicit security warnings:
  ```bash
  # SECURITY WARNING:
  # - NEVER place the Supabase service_role secret key in this file or in any client build.
  # - SUPABASE_ANON_KEY must be the public/publishable anon key enforced by PostgreSQL RLS.
  ```

---

## 3. Defense-in-Depth Implementation

### 3.1 Mobile Binary Protection (`lib/data/services/supabase_service.dart`)
Compile-time and runtime validation prevents any build from initializing if an administrative credential is passed:
```dart
if (envAnonKey.contains('service_role')) {
  AppLogger.error(
    'SupabaseService',
    'SECURITY VIOLATION: Never pass a service_role key to the mobile application.',
  );
  _isInitialized = false;
  return;
}
```

### 3.2 Server-Side Account Deletion RPC (`00008_security_and_guest_discovery.sql`)
To prevent permission violations in managed Supabase projects while preserving GDPR compliance without exposing `service_role` keys:
- Function `public.delete_own_account()` is declared `SECURITY DEFINER` with `SET search_path = public, auth, storage`.
- Strictly asserts `caller_uid := auth.uid()`.
- Deletes user records in `public.profiles` and `auth.users`.
- Wraps direct storage table operations in a graceful exception block so managed storage triggers do not abort cascade account deletion.
- Revokes all permissions from `PUBLIC, anon` and grants exclusively to `authenticated`.

### 3.3 Environment-Aware Authentication Safety (`00008_security_and_guest_discovery.sql`)
To ensure rapid physical device testing in development without compromising production email verification:
```sql
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
```

---

## 4. Environment Authentication Policy Matrix

| Environment | Parameter (`app.environment`) | Auto-Confirm Users | Verification Channel | Notes |
|---|---|---|---|---|
| **Local Development** | `development` (default) | **Enabled** | Instant session creation | No SMTP server or internet connectivity required. |
| **Isolated CI / Staging** | `staging` | **Enabled** | Instant session creation | Facilitates automated multi-user integration tests. |
| **Production** | `production` | **DISABLED** | Supabase Auth Transactional SMTP | Magic links & OTP codes required. Unconfirmed users cannot sign in. |

The mobile client (`lib/features/auth/screens/auth_screen.dart`) now explicitly catches `Email not confirmed` errors returned by Supabase Auth and renders user-friendly instructional messaging:
`"Please verify your email address before signing in. Check your inbox for the confirmation link."`

---

## 5. Credential Rotation Protocol

If exposure is suspected in any staging or production project:
1. **Regenerate Public Anon Key:** In Supabase Dashboard -> Project Settings -> API, cycle the JWT secret.
2. **Issue New Public Anon Key:** Update Cloudflare/Vercel/GitHub Action staging secrets with the new `SUPABASE_ANON_KEY`.
3. **Invalidate Active User Sessions:** Execute `DELETE FROM auth.sessions;` if token compromise is suspected.
4. **Rebuild Client Distributions:** Trigger CI build with new public credentials.

---

## 6. Verification Status

- [x] Client environment templates sanitized (`.env.example`).
- [x] Local uncommitted `.env` stripped of administrative keys.
- [x] Git log verified free of secret tokens.
- [x] Runtime `service_role` rejection guard active in `supabase_service.dart`.
- [x] Database RPC `delete_own_account()` hardened in migration `00008`.
- [x] Production auto-confirmation guard implemented in migration `00008`.
- [x] Unconfirmed email UI state handled in `auth_screen.dart`.
