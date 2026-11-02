-- ============================================================================
-- AROUND — MIGRATION 00011: PRODUCTION SCALE INDEXES & QUERY OPTIMIZATION
-- Task: P12-06 (Platform Domain — Production Database Scale Indexes)
-- Purpose:
--   1. Accelerates high-throughput feed, discovery, and profile queries under
--      multi-user production loads across Tashkent.
--   2. Provides composite indexing for keyset cursor pagination on posts.
--   3. Hardens mutual friendship lookup speed for dual-layer RLS security evaluations.
--   4. Optimizes 24h venue stories active filtering and saved places status queries.
--   5. Uses idempotent IF NOT EXISTS semantics on all statements.
-- ============================================================================

-- 1. Posts: Composite indexing for place drops with audience and quarantine filter
CREATE INDEX IF NOT EXISTS idx_posts_place_audience_feed
  ON public.posts(place_id, audience, created_at DESC)
  WHERE is_quarantined = FALSE;

-- 2. Posts: Keyset cursor pagination index for get_friends_feed (author + created_at DESC + id DESC)
CREATE INDEX IF NOT EXISTS idx_posts_author_cursor_feed
  ON public.posts(author_id, created_at DESC, id DESC)
  WHERE is_quarantined = FALSE;

-- 3. Saved Places: User status filtering with recency ordering
CREATE INDEX IF NOT EXISTS idx_saved_places_user_status_created
  ON public.saved_places(user_id, status, created_at DESC);

-- 4. Saved Places: Place-to-user lookup for instantaneous "is_saved" checking
CREATE INDEX IF NOT EXISTS idx_saved_places_place_user
  ON public.saved_places(place_id, user_id);

-- 5. Friendships: Bidirectional composite indexing for fast is_friend() RLS evaluation
CREATE INDEX IF NOT EXISTS idx_friendships_mutual_status
  ON public.friendships(user_id, friend_id, status);

CREATE INDEX IF NOT EXISTS idx_friendships_reverse_status
  ON public.friendships(friend_id, user_id, status);

-- 6. Place Stories: 24h venue active story filter (expires_at DESC)
CREATE INDEX IF NOT EXISTS idx_place_stories_place_expires
  ON public.place_stories(place_id, expires_at DESC, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_place_stories_author_expires
  ON public.place_stories(author_id, expires_at DESC);

-- 7. Post Reactions: One lookup per post + user for reaction state toggle
CREATE INDEX IF NOT EXISTS idx_post_reactions_post_user
  ON public.post_reactions(post_id, user_id);

-- 8. Post Comments: Chronological post comments retrieval
CREATE INDEX IF NOT EXISTS idx_post_comments_post_created
  ON public.post_comments(post_id, created_at DESC);

-- 9. Friend Plans: Scheduled time ordering
CREATE INDEX IF NOT EXISTS idx_friend_plans_scheduled
  ON public.friend_plans(scheduled_time ASC, place_id);
