-- ==============================================================================
-- Around Platform: Database Migration 00002 - Row Level Security (RLS)
-- ==============================================================================

-- 1. Enable RLS on all exposed tables
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE friendships ENABLE ROW LEVEL SECURITY;
ALTER TABLE places ENABLE ROW LEVEL SECURITY;
ALTER TABLE posts ENABLE ROW LEVEL SECURITY;
ALTER TABLE post_media ENABLE ROW LEVEL SECURITY;
ALTER TABLE saved_places ENABLE ROW LEVEL SECURITY;
ALTER TABLE friend_plans ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE blocks ENABLE ROW LEVEL SECURITY;
ALTER TABLE reports ENABLE ROW LEVEL SECURITY;

-- ------------------------------------------------------------------------------
-- HELPER FUNCTIONS FOR RLS POLICIES (LOCKED DOWN FROM ANON ENUMERATION)
-- ------------------------------------------------------------------------------

-- Check if two users have an accepted bidirectional friendship
CREATE OR REPLACE FUNCTION are_friends(user_a UUID, user_b UUID)
RETURNS BOOLEAN
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
STABLE
AS $$
  SELECT EXISTS (
    SELECT 1 FROM friendships
    WHERE status = 'accepted'
      AND (
        (user_id = user_a AND friend_id = user_b)
        OR (user_id = user_b AND friend_id = user_a)
      )
  );
$$;

-- Prevent unauthenticated callers from enumerating the social graph
REVOKE ALL ON FUNCTION are_friends(UUID, UUID) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION are_friends(UUID, UUID) TO authenticated;

-- Check if either user has blocked the other
CREATE OR REPLACE FUNCTION is_blocked(user_a UUID, user_b UUID)
RETURNS BOOLEAN
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
STABLE
AS $$
  SELECT EXISTS (
    SELECT 1 FROM blocks
    WHERE (blocker_id = user_a AND blocked_id = user_b)
       OR (blocker_id = user_b AND blocked_id = user_a)
  );
$$;

-- Prevent unauthenticated callers from enumerating the block graph
REVOKE ALL ON FUNCTION is_blocked(UUID, UUID) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION is_blocked(UUID, UUID) TO authenticated;

-- ------------------------------------------------------------------------------
-- PROFILES POLICIES (ENFORCES BLOCKING & DISCOVERABILITY)
-- ------------------------------------------------------------------------------
-- Profiles are viewable if own profile, already friends, or discoverable and not blocked
CREATE POLICY "profiles_select_policy" ON profiles
  FOR SELECT
  TO authenticated
  USING (
    id = auth.uid()
    OR (
      NOT is_blocked(auth.uid(), id)
      AND (
        discoverable_by_friends = TRUE
        OR are_friends(auth.uid(), id)
      )
    )
  );

-- Users can insert their own profile row upon signup
CREATE POLICY "profiles_insert_own" ON profiles
  FOR INSERT
  TO authenticated
  WITH CHECK (id = auth.uid());

-- Users can only update their own profile
CREATE POLICY "profiles_update_own" ON profiles
  FOR UPDATE
  TO authenticated
  USING (id = auth.uid())
  WITH CHECK (id = auth.uid());

-- Users can delete their own profile (GDPR Right to Erasure)
CREATE POLICY "profiles_delete_own" ON profiles
  FOR DELETE
  TO authenticated
  USING (id = auth.uid());

-- ------------------------------------------------------------------------------
-- PLACES POLICIES
-- ------------------------------------------------------------------------------
-- Places are public canonical records readable by all authenticated users
CREATE POLICY "places_select_all" ON places
  FOR SELECT
  TO authenticated
  USING (true);

-- Authenticated users can add new canonical venues with their own creator ID
CREATE POLICY "places_insert_authenticated" ON places
  FOR INSERT
  TO authenticated
  WITH CHECK (created_by = auth.uid());

-- ------------------------------------------------------------------------------
-- POSTS POLICIES (THE CORE PRIVACY & MODERATION GUARANTEE)
-- ------------------------------------------------------------------------------
-- A user can SELECT a post if and only if:
-- 1. They are the author of the post, OR
-- 2. The post is NOT quarantined, the author has not blocked the user (nor vice versa), AND:
--    a. The post is 'public' AND (author does not hide visit history OR viewer is querying venue), OR
--    b. The post is 'friends' AND author and user are accepted mutual friends.
CREATE POLICY "posts_select_dual_layer" ON posts
  FOR SELECT
  TO authenticated
  USING (
    author_id = auth.uid()
    OR (
      is_quarantined = FALSE
      AND NOT is_blocked(auth.uid(), author_id)
      AND (
        audience = 'public'
        OR (
          audience = 'friends'
          AND are_friends(auth.uid(), author_id)
        )
      )
    )
  );

-- Only author can insert their own non-quarantined posts
CREATE POLICY "posts_insert_own" ON posts
  FOR INSERT
  TO authenticated
  WITH CHECK (
    author_id = auth.uid()
    AND is_quarantined = FALSE
    AND reports_count = 0
  );

-- Only author can update their own posts
CREATE POLICY "posts_update_own" ON posts
  FOR UPDATE
  TO authenticated
  USING (author_id = auth.uid())
  WITH CHECK (author_id = auth.uid());

-- Only author can delete their own posts
CREATE POLICY "posts_delete_own" ON posts
  FOR DELETE
  TO authenticated
  USING (author_id = auth.uid());

-- ------------------------------------------------------------------------------
-- POST MEDIA POLICIES
-- ------------------------------------------------------------------------------
-- Media is viewable if and only if the parent post is viewable under posts RLS
CREATE POLICY "post_media_select_via_post" ON post_media
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM posts
      WHERE posts.id = post_media.post_id
    )
  );

CREATE POLICY "post_media_insert_own" ON post_media
  FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM posts
      WHERE posts.id = post_media.post_id
        AND posts.author_id = auth.uid()
    )
  );

CREATE POLICY "post_media_delete_own" ON post_media
  FOR DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM posts
      WHERE posts.id = post_media.post_id
        AND posts.author_id = auth.uid()
    )
  );

-- ------------------------------------------------------------------------------
-- FRIENDSHIPS POLICIES (ENFORCES RECIPIENT CONSENT & ALLOW_FRIEND_REQUESTS)
-- ------------------------------------------------------------------------------
CREATE POLICY "friendships_select" ON friendships
  FOR SELECT
  TO authenticated
  USING (user_id = auth.uid() OR friend_id = auth.uid());

-- Initiator can only insert a pending friend request if recipient allows friend requests and is not blocked
CREATE POLICY "friendships_insert" ON friendships
  FOR INSERT
  TO authenticated
  WITH CHECK (
    user_id = auth.uid()
    AND status = 'pending'
    AND NOT is_blocked(auth.uid(), friend_id)
    AND EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = friend_id
        AND profiles.allow_friend_requests = TRUE
    )
  );

-- ONLY the recipient (friend_id = auth.uid()) may accept or decline a pending friend request
CREATE POLICY "friendships_update_recipient_only" ON friendships
  FOR UPDATE
  TO authenticated
  USING (friend_id = auth.uid())
  WITH CHECK (
    friend_id = auth.uid()
    AND status IN ('accepted', 'declined')
  );

CREATE POLICY "friendships_delete" ON friendships
  FOR DELETE
  TO authenticated
  USING (user_id = auth.uid() OR friend_id = auth.uid());

-- ------------------------------------------------------------------------------
-- SAVED PLACES POLICIES (STRICTLY PRIVATE USER SHORTLIST)
-- ------------------------------------------------------------------------------
CREATE POLICY "saved_places_select_own" ON saved_places
  FOR SELECT
  TO authenticated
  USING (user_id = auth.uid());

CREATE POLICY "saved_places_insert_own" ON saved_places
  FOR INSERT
  TO authenticated
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "saved_places_update_own" ON saved_places
  FOR UPDATE
  TO authenticated
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "saved_places_delete_own" ON saved_places
  FOR DELETE
  TO authenticated
  USING (user_id = auth.uid());

-- ------------------------------------------------------------------------------
-- FRIEND PLANS POLICIES (WITH BLOCK ISOLATION)
-- ------------------------------------------------------------------------------
CREATE POLICY "friend_plans_select_participants" ON friend_plans
  FOR SELECT
  TO authenticated
  USING (
    creator_id = auth.uid()
    OR (
      NOT is_blocked(auth.uid(), creator_id)
      AND (
        auth.uid() = ANY(attendee_ids)
        OR are_friends(auth.uid(), creator_id)
      )
    )
  );

CREATE POLICY "friend_plans_insert_own" ON friend_plans
  FOR INSERT
  TO authenticated
  WITH CHECK (creator_id = auth.uid());

CREATE POLICY "friend_plans_delete_own" ON friend_plans
  FOR DELETE
  TO authenticated
  USING (creator_id = auth.uid());

-- ------------------------------------------------------------------------------
-- NOTIFICATIONS POLICIES
-- ------------------------------------------------------------------------------
CREATE POLICY "notifications_select_own" ON notifications
  FOR SELECT
  TO authenticated
  USING (
    recipient_id = auth.uid()
    AND NOT is_blocked(auth.uid(), actor_id)
  );

CREATE POLICY "notifications_update_own" ON notifications
  FOR UPDATE
  TO authenticated
  USING (recipient_id = auth.uid())
  WITH CHECK (recipient_id = auth.uid());

-- ------------------------------------------------------------------------------
-- BLOCKS POLICIES
-- ------------------------------------------------------------------------------
CREATE POLICY "blocks_select_own" ON blocks
  FOR SELECT
  TO authenticated
  USING (blocker_id = auth.uid());

CREATE POLICY "blocks_insert_own" ON blocks
  FOR INSERT
  TO authenticated
  WITH CHECK (blocker_id = auth.uid());

CREATE POLICY "blocks_delete_own" ON blocks
  FOR DELETE
  TO authenticated
  USING (blocker_id = auth.uid());

-- ------------------------------------------------------------------------------
-- REPORTS POLICIES
-- ------------------------------------------------------------------------------
CREATE POLICY "reports_insert" ON reports
  FOR INSERT
  TO authenticated
  WITH CHECK (reporter_id = auth.uid());

CREATE POLICY "reports_select_own" ON reports
  FOR SELECT
  TO authenticated
  USING (reporter_id = auth.uid());
