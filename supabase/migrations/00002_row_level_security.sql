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
ALTER TABLE blocks ENABLE ROW LEVEL SECURITY;
ALTER TABLE reports ENABLE ROW LEVEL SECURITY;

-- ------------------------------------------------------------------------------
-- HELPER FUNCTIONS FOR RLS POLICIES
-- ------------------------------------------------------------------------------

-- Check if two users have an accepted bidirectional friendship
CREATE OR REPLACE FUNCTION are_friends(user_a UUID, user_b UUID)
RETURNS BOOLEAN
LANGUAGE sql
SECURITY DEFINER
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

-- Check if either user has blocked the other
CREATE OR REPLACE FUNCTION is_blocked(user_a UUID, user_b UUID)
RETURNS BOOLEAN
LANGUAGE sql
SECURITY DEFINER
STABLE
AS $$
  SELECT EXISTS (
    SELECT 1 FROM blocks
    WHERE (blocker_id = user_a AND blocked_id = user_b)
       OR (blocker_id = user_b AND blocked_id = user_a)
  );
$$;

-- ------------------------------------------------------------------------------
-- PROFILES POLICIES
-- ------------------------------------------------------------------------------
-- Public profiles viewable by authenticated users unless blocked
CREATE POLICY "profiles_select_policy" ON profiles
  FOR SELECT
  TO authenticated
  USING (
    id = auth.uid()
    OR NOT is_blocked(auth.uid(), id)
  );

-- Users can only update their own profile
CREATE POLICY "profiles_update_own" ON profiles
  FOR UPDATE
  TO authenticated
  USING (id = auth.uid())
  WITH CHECK (id = auth.uid());

-- ------------------------------------------------------------------------------
-- PLACES POLICIES
-- ------------------------------------------------------------------------------
-- Places are public canonical records readable by all authenticated users
CREATE POLICY "places_select_all" ON places
  FOR SELECT
  TO authenticated
  USING (true);

-- ------------------------------------------------------------------------------
-- POSTS POLICIES (THE CORE PRIVACY GUARANTEE)
-- ------------------------------------------------------------------------------
-- A user can SELECT a post if and only if:
-- 1. They are the author of the post, OR
-- 2. The post is 'public' AND author has not blocked the user (nor vice versa), OR
-- 3. The post is 'friends' AND author and user are accepted friends AND not blocked.
CREATE POLICY "posts_select_dual_layer" ON posts
  FOR SELECT
  TO authenticated
  USING (
    author_id = auth.uid()
    OR (
      NOT is_blocked(auth.uid(), author_id)
      AND (
        audience = 'public'
        OR (
          audience = 'friends'
          AND are_friends(auth.uid(), author_id)
        )
      )
    )
  );

-- Only author can insert their own posts
CREATE POLICY "posts_insert_own" ON posts
  FOR INSERT
  TO authenticated
  WITH CHECK (author_id = auth.uid());

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

-- ------------------------------------------------------------------------------
-- FRIENDSHIPS POLICIES
-- ------------------------------------------------------------------------------
CREATE POLICY "friendships_select" ON friendships
  FOR SELECT
  TO authenticated
  USING (user_id = auth.uid() OR friend_id = auth.uid());

CREATE POLICY "friendships_insert" ON friendships
  FOR INSERT
  TO authenticated
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "friendships_update" ON friendships
  FOR UPDATE
  TO authenticated
  USING (friend_id = auth.uid() OR user_id = auth.uid());

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

CREATE POLICY "saved_places_delete_own" ON saved_places
  FOR DELETE
  TO authenticated
  USING (user_id = auth.uid());

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
