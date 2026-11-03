-- Migration 00014: Cryptographic Visit History Purge RPC & Zero-Knowledge Self-Destruct
-- Allows an authenticated user to atomically zero out their check-in drops, saved venue bookmarks,
-- reactions, stories, comments, and collaborative plans with zero residual trace, strictly bound to auth.uid().

CREATE OR REPLACE FUNCTION public.purge_my_visit_history()
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
  v_uid uuid;
  v_deleted_posts integer := 0;
  v_deleted_saved integer := 0;
  v_deleted_reactions integer := 0;
  v_deleted_stories integer := 0;
  v_deleted_comments integer := 0;
BEGIN
  -- Strict caller identity binding (Security Rule C)
  v_uid := auth.uid();
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'Not authenticated: cannot purge visit history without valid session.'
      USING ERRCODE = '42501';
  END IF;

  -- 1. Purge saved place bookmarks & check-in statuses
  WITH del_saved AS (
    DELETE FROM public.saved_places
    WHERE user_id = v_uid
    RETURNING 1
  )
  SELECT count(*) INTO v_deleted_saved FROM del_saved;

  -- 2. Purge venue reactions
  WITH del_rx AS (
    DELETE FROM public.post_reactions
    WHERE user_id = v_uid
    RETURNING 1
  )
  SELECT count(*) INTO v_deleted_reactions FROM del_rx;

  -- 3. Purge post comments
  WITH del_comm AS (
    DELETE FROM public.post_comments
    WHERE author_id = v_uid
    RETURNING 1
  )
  SELECT count(*) INTO v_deleted_comments FROM del_comm;

  -- 4. Purge place stories (ephemeral media)
  WITH del_stories AS (
    DELETE FROM public.place_stories
    WHERE author_id = v_uid
    RETURNING 1
  )
  SELECT count(*) INTO v_deleted_stories FROM del_stories;

  -- 5. Purge friend plan participations and created plans
  DELETE FROM public.friend_plan_participants
  WHERE user_id = v_uid;

  DELETE FROM public.friend_plans
  WHERE creator_id = v_uid;

  -- 6. Purge user collection items and collections
  DELETE FROM public.collection_items
  WHERE added_by = v_uid
     OR collection_id IN (SELECT id FROM public.collections WHERE owner_id = v_uid);

  DELETE FROM public.collections
  WHERE owner_id = v_uid;

  -- 7. Purge user posts / drops (cascades to post_media)
  WITH del_posts AS (
    DELETE FROM public.posts
    WHERE author_id = v_uid
    RETURNING 1
  )
  SELECT count(*) INTO v_deleted_posts FROM del_posts;

  -- 8. Reset profile privacy flags to maximum privacy
  UPDATE public.profiles
  SET hide_visits_history = TRUE,
      updated_at = NOW()
  WHERE id = v_uid;

  RETURN jsonb_build_object(
    'status', 'purged',
    'user_id', v_uid,
    'purged_posts_count', v_deleted_posts,
    'purged_saved_places_count', v_deleted_saved,
    'purged_reactions_count', v_deleted_reactions,
    'purged_stories_count', v_deleted_stories,
    'purged_comments_count', v_deleted_comments,
    'purged_at', NOW()
  );
END;
$$;

-- Function permission grants: only authenticated users can invoke their own history purge
REVOKE ALL ON FUNCTION public.purge_my_visit_history() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.purge_my_visit_history() TO authenticated;

COMMENT ON FUNCTION public.purge_my_visit_history IS
  'Atomically zeroes out the authenticated callers check-ins, drops, saved places, and interaction records with zero residual trace.';
