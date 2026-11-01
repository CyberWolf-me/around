-- ============================================================================
-- AROUND — MIGRATION 00006: 8-DOMAIN PLATFORM EXPANSION & INTELLIGENT DISCOVERY
-- Task IDs: P3-05, P4-01, P5-01, P6-01, STG-03, STG-04, SEC-13
-- ============================================================================

-- 1. Custom & Collaborative Collections (Phase 3.6 & Phase 4.5 — Collections Domain)
CREATE TABLE IF NOT EXISTS public.collections (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  owner_id UUID NOT NULL DEFAULT auth.uid() REFERENCES public.profiles(id) ON DELETE CASCADE,
  title TEXT NOT NULL CHECK (char_length(trim(title)) BETWEEN 1 AND 80),
  description TEXT NOT NULL DEFAULT '' CHECK (char_length(description) <= 300),
  audience TEXT NOT NULL DEFAULT 'friends' CHECK (audience IN ('private', 'friends', 'public')),
  is_collaborative BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.collection_items (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  collection_id UUID NOT NULL REFERENCES public.collections(id) ON DELETE CASCADE,
  place_id UUID NOT NULL REFERENCES public.places(id) ON DELETE CASCADE,
  added_by UUID NOT NULL DEFAULT auth.uid() REFERENCES public.profiles(id) ON DELETE CASCADE,
  note TEXT NOT NULL DEFAULT '' CHECK (char_length(note) <= 240),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT unique_collection_place UNIQUE (collection_id, place_id)
);

CREATE INDEX IF NOT EXISTS idx_collections_owner ON public.collections(owner_id);
CREATE INDEX IF NOT EXISTS idx_collection_items_collection ON public.collection_items(collection_id);

ALTER TABLE public.collections ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.collection_items ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "collections_select_policy" ON public.collections;
CREATE POLICY "collections_select_policy"
  ON public.collections FOR SELECT
  TO authenticated
  USING (
    auth.uid() = owner_id
    OR (audience = 'public' AND NOT public.is_blocked(auth.uid(), owner_id))
    OR (audience = 'friends' AND public.are_friends(auth.uid(), owner_id) AND NOT public.is_blocked(auth.uid(), owner_id))
  );

DROP POLICY IF EXISTS "collections_modify_owner" ON public.collections;
CREATE POLICY "collections_modify_owner"
  ON public.collections FOR ALL
  TO authenticated
  USING (auth.uid() = owner_id)
  WITH CHECK (auth.uid() = owner_id);

DROP POLICY IF EXISTS "collection_items_select_policy" ON public.collection_items;
CREATE POLICY "collection_items_select_policy"
  ON public.collection_items FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.collections c
      WHERE c.id = collection_id
        AND (
          c.owner_id = auth.uid()
          OR (c.audience = 'public' AND NOT public.is_blocked(auth.uid(), c.owner_id))
          OR (c.audience = 'friends' AND public.are_friends(auth.uid(), c.owner_id) AND NOT public.is_blocked(auth.uid(), c.owner_id))
        )
    )
  );

DROP POLICY IF EXISTS "collection_items_insert_policy" ON public.collection_items;
CREATE POLICY "collection_items_insert_policy"
  ON public.collection_items FOR INSERT
  TO authenticated
  WITH CHECK (
    auth.uid() = added_by
    AND EXISTS (
      SELECT 1 FROM public.collections c
      WHERE c.id = collection_id
        AND NOT public.is_blocked(auth.uid(), c.owner_id)
        AND (
          c.owner_id = auth.uid()
          OR (c.is_collaborative = TRUE AND public.are_friends(auth.uid(), c.owner_id))
        )
    )
  );

DROP POLICY IF EXISTS "collection_items_delete_policy" ON public.collection_items;
CREATE POLICY "collection_items_delete_policy"
  ON public.collection_items FOR DELETE
  TO authenticated
  USING (
    auth.uid() = added_by
    OR EXISTS (
      SELECT 1 FROM public.collections c
      WHERE c.id = collection_id AND c.owner_id = auth.uid()
    )
  );

-- 2. Friend Plan Invitations & RSVPs (Phase 4.1 — Collections / Social Ecosystem)
CREATE TABLE IF NOT EXISTS public.friend_plan_participants (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  plan_id UUID NOT NULL REFERENCES public.friend_plans(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  rsvp_status TEXT NOT NULL DEFAULT 'invited' CHECK (rsvp_status IN ('invited', 'going', 'declined')),
  responded_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT unique_plan_participant UNIQUE (plan_id, user_id)
);

CREATE INDEX IF NOT EXISTS idx_plan_participants_plan ON public.friend_plan_participants(plan_id);
CREATE INDEX IF NOT EXISTS idx_plan_participants_user ON public.friend_plan_participants(user_id);

ALTER TABLE public.friend_plan_participants ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "plan_participants_select" ON public.friend_plan_participants;
CREATE POLICY "plan_participants_select"
  ON public.friend_plan_participants FOR SELECT
  TO authenticated
  USING (
    auth.uid() = user_id
    OR EXISTS (
      SELECT 1 FROM public.friend_plans fp
      WHERE fp.id = plan_id
        AND NOT public.is_blocked(auth.uid(), fp.creator_id)
        AND (fp.creator_id = auth.uid() OR public.are_friends(auth.uid(), fp.creator_id))
    )
  );

DROP POLICY IF EXISTS "plan_participants_insert_creator" ON public.friend_plan_participants;
CREATE POLICY "plan_participants_insert_creator"
  ON public.friend_plan_participants FOR INSERT
  TO authenticated
  WITH CHECK (
    NOT public.is_blocked(auth.uid(), user_id)
    AND EXISTS (
      SELECT 1 FROM public.friend_plans fp
      WHERE fp.id = plan_id AND fp.creator_id = auth.uid()
    )
  );

DROP POLICY IF EXISTS "plan_participants_update_own_rsvp" ON public.friend_plan_participants;
CREATE POLICY "plan_participants_update_own_rsvp"
  ON public.friend_plan_participants FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id AND rsvp_status IN ('going', 'declined'));

DROP POLICY IF EXISTS "plan_participants_delete" ON public.friend_plan_participants;
CREATE POLICY "plan_participants_delete"
  ON public.friend_plan_participants FOR DELETE
  TO authenticated
  USING (
    auth.uid() = user_id
    OR EXISTS (
      SELECT 1 FROM public.friend_plans fp
      WHERE fp.id = plan_id AND fp.creator_id = auth.uid()
    )
  );

-- 3. 24-Hour Venue Stories (Phase 4.2 — Engagement Domain)
CREATE TABLE IF NOT EXISTS public.place_stories (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  author_id UUID NOT NULL DEFAULT auth.uid() REFERENCES public.profiles(id) ON DELETE CASCADE,
  place_id UUID NOT NULL REFERENCES public.places(id) ON DELETE CASCADE,
  media_url TEXT NOT NULL CHECK (char_length(trim(media_url)) BETWEEN 1 AND 500),
  caption TEXT NOT NULL DEFAULT '' CHECK (char_length(caption) <= 180),
  audience audience_type NOT NULL DEFAULT 'friends',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  expires_at TIMESTAMPTZ NOT NULL DEFAULT (NOW() + INTERVAL '24 hours')
);

CREATE INDEX IF NOT EXISTS idx_place_stories_active ON public.place_stories (place_id, expires_at DESC);

ALTER TABLE public.place_stories ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "place_stories_select_active" ON public.place_stories;
CREATE POLICY "place_stories_select_active"
  ON public.place_stories FOR SELECT
  TO authenticated
  USING (
    expires_at > NOW()
    AND (
      auth.uid() = author_id
      OR (audience = 'public' AND NOT public.is_blocked(auth.uid(), author_id))
      OR (audience = 'friends' AND public.are_friends(auth.uid(), author_id) AND NOT public.is_blocked(auth.uid(), author_id))
    )
  );

DROP POLICY IF EXISTS "place_stories_insert_own" ON public.place_stories;
CREATE POLICY "place_stories_insert_own"
  ON public.place_stories FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = author_id AND expires_at > NOW());

DROP POLICY IF EXISTS "place_stories_delete_own" ON public.place_stories;
CREATE POLICY "place_stories_delete_own"
  ON public.place_stories FOR DELETE
  TO authenticated
  USING (auth.uid() = author_id);

-- 4. Drop Reactions & Comments (Phase 4.3 — Engagement Domain, SEC-13 Remediated)
CREATE TABLE IF NOT EXISTS public.post_reactions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  post_id UUID NOT NULL REFERENCES public.posts(id) ON DELETE CASCADE,
  user_id UUID NOT NULL DEFAULT auth.uid() REFERENCES public.profiles(id) ON DELETE CASCADE,
  reaction TEXT NOT NULL DEFAULT 'heart' CHECK (reaction IN ('heart', 'fire', 'bookmark_nod', 'coffee')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT unique_post_user_reaction UNIQUE (post_id, user_id, reaction)
);

CREATE TABLE IF NOT EXISTS public.post_comments (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  post_id UUID NOT NULL REFERENCES public.posts(id) ON DELETE CASCADE,
  author_id UUID NOT NULL DEFAULT auth.uid() REFERENCES public.profiles(id) ON DELETE CASCADE,
  body TEXT NOT NULL CHECK (char_length(trim(body)) BETWEEN 1 AND 300),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_post_reactions_post ON public.post_reactions(post_id);
CREATE INDEX IF NOT EXISTS idx_post_comments_post ON public.post_comments(post_id, created_at ASC);

ALTER TABLE public.post_reactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.post_comments ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "post_reactions_select" ON public.post_reactions;
CREATE POLICY "post_reactions_select"
  ON public.post_reactions FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.posts p
      WHERE p.id = post_id
        AND p.is_quarantined = FALSE
        AND (
          p.author_id = auth.uid()
          OR (p.audience = 'public' AND NOT public.is_blocked(auth.uid(), p.author_id))
          OR (p.audience = 'friends' AND public.are_friends(auth.uid(), p.author_id) AND NOT public.is_blocked(auth.uid(), p.author_id))
        )
    )
  );

-- SEC-13 Fix: Caller can only react to a post if they are authorized to view that post
DROP POLICY IF EXISTS "post_reactions_modify_own" ON public.post_reactions;
DROP POLICY IF EXISTS "post_reactions_insert_authorized" ON public.post_reactions;
CREATE POLICY "post_reactions_insert_authorized"
  ON public.post_reactions FOR INSERT
  TO authenticated
  WITH CHECK (
    auth.uid() = user_id
    AND EXISTS (
      SELECT 1 FROM public.posts p
      WHERE p.id = post_id
        AND p.is_quarantined = FALSE
        AND (
          p.author_id = auth.uid()
          OR (p.audience = 'public' AND NOT public.is_blocked(auth.uid(), p.author_id))
          OR (p.audience = 'friends' AND public.are_friends(auth.uid(), p.author_id) AND NOT public.is_blocked(auth.uid(), p.author_id))
        )
    )
  );

DROP POLICY IF EXISTS "post_reactions_delete_own" ON public.post_reactions;
CREATE POLICY "post_reactions_delete_own"
  ON public.post_reactions FOR DELETE
  TO authenticated
  USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "post_comments_select" ON public.post_comments;
CREATE POLICY "post_comments_select"
  ON public.post_comments FOR SELECT
  TO authenticated
  USING (
    NOT public.is_blocked(auth.uid(), author_id)
    AND EXISTS (
      SELECT 1 FROM public.posts p
      WHERE p.id = post_id
        AND p.is_quarantined = FALSE
        AND (
          p.author_id = auth.uid()
          OR (p.audience = 'public' AND NOT public.is_blocked(auth.uid(), p.author_id))
          OR (p.audience = 'friends' AND public.are_friends(auth.uid(), p.author_id) AND NOT public.is_blocked(auth.uid(), p.author_id))
        )
    )
  );

-- SEC-13 Fix: Caller can only comment on a post if they are authorized to view that post
DROP POLICY IF EXISTS "post_comments_insert_own" ON public.post_comments;
DROP POLICY IF EXISTS "post_comments_insert_authorized" ON public.post_comments;
CREATE POLICY "post_comments_insert_authorized"
  ON public.post_comments FOR INSERT
  TO authenticated
  WITH CHECK (
    auth.uid() = author_id
    AND EXISTS (
      SELECT 1 FROM public.posts p
      WHERE p.id = post_id
        AND p.is_quarantined = FALSE
        AND (
          p.author_id = auth.uid()
          OR (p.audience = 'public' AND NOT public.is_blocked(auth.uid(), p.author_id))
          OR (p.audience = 'friends' AND public.are_friends(auth.uid(), p.author_id) AND NOT public.is_blocked(auth.uid(), p.author_id))
        )
    )
  );

DROP POLICY IF EXISTS "post_comments_delete_own" ON public.post_comments;
CREATE POLICY "post_comments_delete_own"
  ON public.post_comments FOR DELETE
  TO authenticated
  USING (auth.uid() = author_id);

-- 5. Moderation Audit Logs (Phase 5.3 — Trust & Safety Operations)
CREATE TABLE IF NOT EXISTS public.moderation_audit_logs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  target_type TEXT NOT NULL CHECK (target_type IN ('post', 'place', 'profile', 'comment')),
  target_id TEXT NOT NULL,
  action TEXT NOT NULL CHECK (action IN ('report_logged', 'auto_quarantined', 'restored', 'removed')),
  reason TEXT NOT NULL DEFAULT '',
  triggered_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE public.moderation_audit_logs ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "moderation_audit_logs_select_own" ON public.moderation_audit_logs;
CREATE POLICY "moderation_audit_logs_select_own"
  ON public.moderation_audit_logs FOR SELECT
  TO authenticated
  USING (
    triggered_by = auth.uid()
    OR EXISTS (
      SELECT 1 FROM public.posts p
      WHERE p.id::text = target_id AND p.author_id = auth.uid()
    )
  );

CREATE OR REPLACE FUNCTION public.log_post_quarantine_audit()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NEW.is_quarantined = TRUE AND OLD.is_quarantined = FALSE THEN
    INSERT INTO public.moderation_audit_logs (target_type, target_id, action, reason)
    VALUES ('post', NEW.id::TEXT, 'auto_quarantined', 'Reached 3 community moderation reports');
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_log_post_quarantine_audit ON public.posts;
CREATE TRIGGER trg_log_post_quarantine_audit
  AFTER UPDATE OF is_quarantined ON public.posts
  FOR EACH ROW EXECUTE FUNCTION public.log_post_quarantine_audit();

-- 6. Explainable, Privacy-Preserving Recommendation Engine (Phase 6 — STG-03 Fixed)
-- Uses places.rating_avg (from 00001) and restricts execution to authenticated users.
DROP FUNCTION IF EXISTS public.get_recommended_places(INT);

CREATE OR REPLACE FUNCTION public.get_recommended_places(
  limit_count INTEGER DEFAULT 10
)
RETURNS TABLE (
  place_id UUID,
  slug TEXT,
  name TEXT,
  category TEXT,
  district TEXT,
  rating_avg NUMERIC,
  friends_recommend_count BIGINT,
  relevance_score NUMERIC,
  explanation TEXT
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
    RAISE EXCEPTION 'Authentication required for personalized recommendations' USING ERRCODE = '42501';
  END IF;

  RETURN QUERY
  WITH friend_recs AS (
    SELECT
      po.place_id,
      COUNT(DISTINCT po.author_id) AS f_count
    FROM public.posts po
    WHERE po.is_quarantined = FALSE
      AND public.are_friends(caller_uid, po.author_id)
      AND NOT public.is_blocked(caller_uid, po.author_id)
    GROUP BY po.place_id
  ),
  saved_cats AS (
    SELECT DISTINCT pl.category
    FROM public.saved_places sp
    INNER JOIN public.places pl ON pl.id = sp.place_id
    WHERE sp.user_id = caller_uid
  )
  SELECT
    p.id AS place_id,
    p.slug,
    p.name,
    p.category,
    p.district,
    p.rating_avg,
    COALESCE(fr.f_count, 0) AS friends_recommend_count,
    ROUND(
      (COALESCE(fr.f_count, 0) * 3.0) +
      (CASE WHEN p.category IN (SELECT sc.category FROM saved_cats sc) THEN 1.5 ELSE 0.0 END) +
      (p.rating_avg * 0.5),
      2
    ) AS relevance_score,
    CASE
      WHEN COALESCE(fr.f_count, 0) > 0 THEN COALESCE(fr.f_count, 0)::TEXT || ' mutual friend(s) recommend this spot'
      WHEN p.category IN (SELECT sc.category FROM saved_cats sc) THEN 'Matches your saved ' || split_part(p.category, ' · ', 1) || ' spots'
      ELSE 'Top-rated in ' || p.district || ' (' || p.rating_avg::TEXT || '★)'
    END AS explanation
  FROM public.places p
  LEFT JOIN friend_recs fr ON fr.place_id = p.id
  WHERE NOT EXISTS (
    SELECT 1 FROM public.saved_places sp2
    WHERE sp2.user_id = caller_uid AND sp2.place_id = p.id AND sp2.status = 'been'
  )
  ORDER BY relevance_score DESC, p.rating_avg DESC
  LIMIT LEAST(GREATEST(limit_count, 1), 50);
END;
$$;

REVOKE ALL ON FUNCTION public.get_recommended_places(INTEGER) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.get_recommended_places(INTEGER) TO authenticated;
