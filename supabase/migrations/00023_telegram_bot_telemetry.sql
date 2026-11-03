-- Migration 00023: Telegram Bot Telemetry & Command Routing Audit
-- Tracks bot command interactions and deep link conversions.

-- 1. Bot Command Logs Table
CREATE TABLE IF NOT EXISTS public.bot_command_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
  telegram_chat_id BIGINT NOT NULL,
  command TEXT NOT NULL CHECK (char_length(trim(command)) BETWEEN 1 AND 50),
  language_code TEXT NOT NULL DEFAULT 'en',
  payload TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Indexes for telemetry and analytics queries
CREATE INDEX IF NOT EXISTS idx_bot_command_chat ON public.bot_command_logs(telegram_chat_id);
CREATE INDEX IF NOT EXISTS idx_bot_command_created ON public.bot_command_logs(created_at);
CREATE INDEX IF NOT EXISTS idx_bot_command_user ON public.bot_command_logs(user_id);

-- 2. Row-Level Security
ALTER TABLE public.bot_command_logs ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'bot_command_logs' AND policyname = 'bot_command_logs_user_read'
  ) THEN
    CREATE POLICY bot_command_logs_user_read ON public.bot_command_logs
      FOR SELECT USING (auth.uid() = user_id);
  END IF;
END $$;

-- 3. Idempotent Record Bot Command RPC
CREATE OR REPLACE FUNCTION public.record_bot_command(
  p_command TEXT,
  p_telegram_chat_id BIGINT,
  p_language_code TEXT DEFAULT 'en',
  p_payload TEXT DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
  v_uid UUID;
  v_clean_command TEXT;
  v_clean_lang TEXT;
  v_log_id UUID;
BEGIN
  v_uid := auth.uid();
  v_clean_command := LOWER(trim(COALESCE(p_command, '')));
  IF char_length(v_clean_command) = 0 THEN
    RETURN jsonb_build_object('success', false, 'error', 'Command must not be empty.');
  END IF;

  v_clean_lang := LOWER(trim(COALESCE(p_language_code, 'en')));
  IF char_length(v_clean_lang) > 5 THEN
    v_clean_lang := 'en';
  END IF;

  INSERT INTO public.bot_command_logs (
    user_id,
    telegram_chat_id,
    command,
    language_code,
    payload
  ) VALUES (
    v_uid,
    p_telegram_chat_id,
    v_clean_command,
    v_clean_lang,
    NULLIF(trim(p_payload), '')
  )
  RETURNING id INTO v_log_id;

  RETURN jsonb_build_object(
    'success', true,
    'log_id', v_log_id,
    'command', v_clean_command,
    'language', v_clean_lang
  );
END;
$$;

-- 4. Permissions
GRANT EXECUTE ON FUNCTION public.record_bot_command(TEXT, BIGINT, TEXT, TEXT) TO anon, authenticated;
