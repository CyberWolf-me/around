-- ============================================================================
-- AROUND — MIGRATION 00005: CORRECTIVE SECURITY, RLS & ACCOUNT DELETION
-- Task IDs: P1-02, P5-01, STG-01, STG-02, SEC-01, SEC-02, SEC-14
-- Purpose: Idempotent corrective migration aligned 100% with 00001–00004
--          schema columns (friendships.user_id / friend_id, post_media.created_at).
-- ============================================================================

-- 1. Drop legacy and existing get_friends_feed signatures before recreating (STG-02 / SEC-01)
DROP FUNCTION IF EXISTS public.get_friends_feed(UUID, INTEGER, INTEGER);
DROP FUNCTION IF EXISTS public.get_friends_feed(INTEGER, INTEGER);

-- 2. Recreate get_friends_feed as SECURITY INVOKER bound strictly to auth.uid() (SEC-01)
CREATE OR REPLACE FUNCTION public.get_friends_feed(
  page_limit INTEGER DEFAULT 20,
  page_offset INTEGER DEFAULT 0
)
RETURNS TABLE (
  post_id UUID,
  author_id UUID,
  author_name TEXT,
  author_username TEXT,
  author_avatar TEXT,
  place_id UUID,
  place_slug TEXT,
  place_name TEXT,
  place_category TEXT,
  place_address TEXT,
  place_district TEXT,
  note TEXT,
  rating SMALLINT,
  audience audience_type,
  size TEXT,
  tags TEXT[],
  media_url TEXT,
  saves_count INTEGER,
  created_at TIMESTAMPTZ,
  is_saved BOOLEAN
)
LANGUAGE plpgsql
STABLE
SECURITY INVOKER
SET search_path = public
AS $$
DECLARE
  caller_uid UUID := auth.uid();
BEGIN
  IF caller_uid IS NULL THEN
    RAISE EXCEPTION 'Authentication required to fetch friends feed' USING ERRCODE = '42501';
  END IF;

  RETURN QUERY
  SELECT
    po.id AS post_id,
    po.author_id,
    pr.full_name AS author_name,
    pr.username AS author_username,
    pr.avatar_url AS author_avatar,
    pl.id AS place_id,
    pl.slug AS place_slug,
    pl.name AS place_name,
    pl.category AS place_category,
    pl.street_address AS place_address,
    pl.district AS place_district,
    po.note,
    po.rating,
    po.audience,
    po.size,
    po.tags,
    (
      SELECT pm.media_url
      FROM public.post_media pm
      WHERE pm.post_id = po.id
      ORDER BY pm.is_primary DESC, pm.created_at ASC
      LIMIT 1
    ) AS media_url,
    po.saves_count,
    po.created_at,
    EXISTS(
      SELECT 1 FROM public.saved_places sp
      WHERE sp.user_id = caller_uid AND sp.place_id = pl.id
    ) AS is_saved
  FROM public.posts po
  INNER JOIN public.profiles pr ON pr.id = po.author_id
  INNER JOIN public.places pl ON pl.id = po.place_id
  WHERE
    po.is_quarantined = FALSE
    AND (
      po.author_id = caller_uid
      OR public.are_friends(caller_uid, po.author_id)
    )
    AND NOT public.is_blocked(caller_uid, po.author_id)
  ORDER BY po.created_at DESC
  LIMIT LEAST(GREATEST(page_limit, 1), 50)
  OFFSET GREATEST(page_offset, 0);
END;
$$;

REVOKE ALL ON FUNCTION public.get_friends_feed(INTEGER, INTEGER) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.get_friends_feed(INTEGER, INTEGER) TO authenticated;

-- 3. Remediate Friendship Self-Accept Escalation (SEC-02 / STG-01) using 00001 columns (user_id, friend_id)
DROP POLICY IF EXISTS "friendships_update_participants" ON public.friendships;
DROP POLICY IF EXISTS "friendships_update_recipient_only" ON public.friendships;

CREATE POLICY "friendships_update_recipient_only"
  ON public.friendships
  FOR UPDATE
  TO authenticated
  USING (auth.uid() = friend_id)
  WITH CHECK (
    auth.uid() = friend_id
    AND status IN ('accepted', 'declined')
  );

CREATE OR REPLACE FUNCTION public.enforce_friendship_transition()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = public
AS $$
BEGIN
  IF NEW.user_id <> OLD.user_id OR NEW.friend_id <> OLD.friend_id THEN
    RAISE EXCEPTION 'Cannot modify friendship participants' USING ERRCODE = '42501';
  END IF;

  IF auth.uid() IS NOT NULL AND auth.uid() <> OLD.friend_id THEN
    RAISE EXCEPTION 'Only the request recipient (friend_id) can update friendship status' USING ERRCODE = '42501';
  END IF;

  IF OLD.status = 'accepted' AND NEW.status = 'pending' THEN
    RAISE EXCEPTION 'Invalid status transition from accepted to pending' USING ERRCODE = '23514';
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_enforce_friendship_transition ON public.friendships;
CREATE TRIGGER trg_enforce_friendship_transition
  BEFORE UPDATE ON public.friendships
  FOR EACH ROW EXECUTE FUNCTION public.enforce_friendship_transition();

-- 4. Restrict Helper Functions to Authenticated Role Only (SEC-09)
REVOKE ALL ON FUNCTION public.are_friends(UUID, UUID) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.are_friends(UUID, UUID) TO authenticated;

REVOKE ALL ON FUNCTION public.is_blocked(UUID, UUID) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.is_blocked(UUID, UUID) TO authenticated;

-- 5. Enforce Dual-Layer Privacy on Storage Objects in 'post-media' Bucket (SEC-14)
UPDATE storage.buckets
SET public = FALSE
WHERE id = 'post-media';

DROP POLICY IF EXISTS "post_media_storage_auth_read" ON storage.objects;
CREATE POLICY "post_media_storage_dual_layer_read"
  ON storage.objects FOR SELECT
  TO authenticated
  USING (
    bucket_id = 'post-media'
    AND (
      (storage.foldername(name))[1] = auth.uid()::text
      OR EXISTS (
        SELECT 1
        FROM public.post_media pm
        INNER JOIN public.posts po ON po.id = pm.post_id
        WHERE pm.storage_path = storage.objects.name
          AND po.is_quarantined = FALSE
          AND NOT public.is_blocked(auth.uid(), po.author_id)
          AND (
            po.audience = 'public'
            OR (po.audience = 'friends' AND public.are_friends(auth.uid(), po.author_id))
          )
      )
    )
  );

-- 6. Server-Side Account Deletion RPC (TASK-09)
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

  DELETE FROM storage.objects
  WHERE bucket_id = 'post-media'
    AND (storage.foldername(name))[1] = caller_uid::TEXT;

  DELETE FROM public.profiles WHERE id = caller_uid;
  DELETE FROM auth.users WHERE id = caller_uid;

  RETURN TRUE;
END;
$$;

REVOKE ALL ON FUNCTION public.delete_own_account() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.delete_own_account() TO authenticated;
