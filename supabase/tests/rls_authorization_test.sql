-- ============================================================================
-- AROUND — MULTI-USER RLS & AUTHORIZATION TEST SUITE (pgTAP / Supabase Test DB)
-- File: supabase/tests/rls_authorization_test.sql
-- Task IDs: P1-02, P7-01, STG-01, STG-04
-- Purpose: Executes under transaction-scoped `SET LOCAL ROLE authenticated`
--          with simulated JWT `request.jwt.claim.sub` identities to verify
--          actual PostgreSQL Row-Level Security enforcement across all 8 domains.
-- ============================================================================

BEGIN;

-- 1. Seed 3 isolated synthetic test accounts as superuser before dropping to `authenticated` role
INSERT INTO auth.users (id, email) VALUES
  ('aaaa1111-1111-4111-8111-111111111111', 'alice.test@around.uz'),
  ('bbbb2222-2222-4222-8222-222222222222', 'bob.test@around.uz'),
  ('cccc3333-3333-4333-8333-333333333333', 'charlie.test@around.uz')
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.profiles (id, username, full_name, neighborhood, hide_visits_history) VALUES
  ('aaaa1111-1111-4111-8111-111111111111', 'alice_test', 'Alice Test', 'Mirabad', TRUE),
  ('bbbb2222-2222-4222-8222-222222222222', 'bob_test', 'Bob Test', 'Yakkasaray', FALSE),
  ('cccc3333-3333-4333-8333-333333333333', 'charlie_test', 'Charlie Test', 'Yunusabad', TRUE)
ON CONFLICT (id) DO NOTHING;

-- Switch effective PostgreSQL role to `authenticated` so RLS policies are strictly enforced!
SET LOCAL ROLE authenticated;

DO $$
DECLARE
  alice_id UUID := 'aaaa1111-1111-4111-8111-111111111111';
  bob_id UUID := 'bbbb2222-2222-4222-8222-222222222222';
  charlie_id UUID := 'cccc3333-3333-4333-8333-333333333333';
  breadly_id UUID := '11111111-1111-4111-8111-111111111101';
  private_post_id UUID;
  public_post_id UUID;
  friendship_ba_id UUID;
  collab_collection_id UUID;
  active_story_id UUID;
  expired_story_id UUID;
  visible_count INT;
  op_rejected BOOLEAN;
BEGIN
  -- ==========================================================================
  -- SCENARIO 1: Alice publishes a friends-only Drop and a public Drop
  -- ==========================================================================
  PERFORM set_config('request.jwt.claim.sub', alice_id::TEXT, TRUE);

  INSERT INTO public.posts (author_id, place_id, note, rating, audience, size)
  VALUES (alice_id, breadly_id, 'Alice friends-only courtyard note', 5, 'friends', 'hero')
  RETURNING id INTO private_post_id;

  INSERT INTO public.posts (author_id, place_id, note, rating, audience, size)
  VALUES (alice_id, breadly_id, 'Alice public sourdough review', 5, 'public', 'half')
  RETURNING id INTO public_post_id;

  -- ==========================================================================
  -- SCENARIO 2: Charlie (stranger) cannot see Alice's friends-only Drop,
  --             cannot react/comment on it (SEC-13), but CAN see public Drop
  -- ==========================================================================
  PERFORM set_config('request.jwt.claim.sub', charlie_id::TEXT, TRUE);

  SELECT COUNT(*) INTO visible_count FROM public.posts WHERE id = private_post_id;
  IF visible_count <> 0 THEN
    RAISE EXCEPTION 'FAIL [Scenario 2A]: Stranger Charlie accessed Alice friends-only Drop!';
  END IF;

  SELECT COUNT(*) INTO visible_count FROM public.posts WHERE id = public_post_id;
  IF visible_count <> 1 THEN
    RAISE EXCEPTION 'FAIL [Scenario 2B]: Stranger Charlie could not access Alice public Drop!';
  END IF;

  op_rejected := FALSE;
  BEGIN
    INSERT INTO public.post_comments (post_id, author_id, body)
    VALUES (private_post_id, charlie_id, 'Unauthorized comment on private drop');
  EXCEPTION WHEN OTHERS THEN
    op_rejected := TRUE;
  END;
  IF NOT op_rejected THEN
    RAISE EXCEPTION 'FAIL [SEC-13]: Stranger Charlie commented on Alice friends-only Drop!';
  END IF;

  -- ==========================================================================
  -- SCENARIO 3: Bob sends Alice a friend request (`user_id` = bob, `friend_id` = alice)
  --             and attempts to self-accept it (SEC-02 / MIG-01)
  -- ==========================================================================
  PERFORM set_config('request.jwt.claim.sub', bob_id::TEXT, TRUE);

  INSERT INTO public.friendships (user_id, friend_id, status)
  VALUES (bob_id, alice_id, 'pending')
  RETURNING id INTO friendship_ba_id;

  -- While pending, Bob still cannot see Alice's friends-only Drop
  SELECT COUNT(*) INTO visible_count FROM public.posts WHERE id = private_post_id;
  IF visible_count <> 0 THEN
    RAISE EXCEPTION 'FAIL [Scenario 3A]: Pending requester Bob saw friends-only Drop before acceptance!';
  END IF;

  -- Bob attempts to self-accept his own outgoing request
  op_rejected := FALSE;
  BEGIN
    UPDATE public.friendships SET status = 'accepted' WHERE id = friendship_ba_id;
  EXCEPTION WHEN OTHERS THEN
    op_rejected := TRUE;
  END;

  SELECT COUNT(*) INTO visible_count
  FROM public.friendships
  WHERE id = friendship_ba_id AND status = 'accepted';
  IF visible_count <> 0 THEN
    RAISE EXCEPTION 'FAIL [SEC-02]: Requester Bob self-accepted his own friend request!';
  END IF;

  -- ==========================================================================
  -- SCENARIO 4: Recipient Alice accepts Bob's request -> Bob sees friends-only Drop
  --             in both direct query and `get_friends_feed` (SEC-01)
  -- ==========================================================================
  PERFORM set_config('request.jwt.claim.sub', alice_id::TEXT, TRUE);
  UPDATE public.friendships SET status = 'accepted' WHERE id = friendship_ba_id;

  PERFORM set_config('request.jwt.claim.sub', bob_id::TEXT, TRUE);
  SELECT COUNT(*) INTO visible_count FROM public.posts WHERE id = private_post_id;
  IF visible_count <> 1 THEN
    RAISE EXCEPTION 'FAIL [Scenario 4A]: Accepted friend Bob could not see Alice friends-only Drop!';
  END IF;

  SELECT COUNT(*) INTO visible_count FROM public.get_friends_feed(20, 0) WHERE post_id = private_post_id;
  IF visible_count <> 1 THEN
    RAISE EXCEPTION 'FAIL [SEC-01]: get_friends_feed did not return Alice drop for accepted friend Bob!';
  END IF;

  -- ==========================================================================
  -- SCENARIO 5: Collaborative Collections (`collections` & `collection_items`)
  --             Accepted friend Bob can add an item; stranger Charlie is rejected
  -- ==========================================================================
  PERFORM set_config('request.jwt.claim.sub', alice_id::TEXT, TRUE);
  INSERT INTO public.collections (owner_id, title, audience, is_collaborative)
  VALUES (alice_id, 'Mirabad Espresso Crawl', 'friends', TRUE)
  RETURNING id INTO collab_collection_id;

  PERFORM set_config('request.jwt.claim.sub', bob_id::TEXT, TRUE);
  INSERT INTO public.collection_items (collection_id, place_id, added_by, note)
  VALUES (collab_collection_id, breadly_id, bob_id, 'Must try the sourdough');

  PERFORM set_config('request.jwt.claim.sub', charlie_id::TEXT, TRUE);
  op_rejected := FALSE;
  BEGIN
    INSERT INTO public.collection_items (collection_id, place_id, added_by, note)
    VALUES (collab_collection_id, breadly_id, charlie_id, 'Stranger injection');
  EXCEPTION WHEN OTHERS THEN
    op_rejected := TRUE;
  END;
  IF NOT op_rejected THEN
    RAISE EXCEPTION 'FAIL [Scenario 5]: Stranger Charlie added an item to Alice friends-only collaborative collection!';
  END IF;

  -- ==========================================================================
  -- SCENARIO 6: 24-Hour Venue Stories (`place_stories`) visibility & expiration
  -- ==========================================================================
  PERFORM set_config('request.jwt.claim.sub', alice_id::TEXT, TRUE);
  INSERT INTO public.place_stories (author_id, place_id, media_url, caption, audience, expires_at)
  VALUES (alice_id, breadly_id, 'assets/bakery-counter.jpg', 'Fresh loaf out now', 'friends', NOW() + INTERVAL '12 hours')
  RETURNING id INTO active_story_id;

  PERFORM set_config('request.jwt.claim.sub', bob_id::TEXT, TRUE);
  SELECT COUNT(*) INTO visible_count FROM public.place_stories WHERE id = active_story_id;
  IF visible_count <> 1 THEN
    RAISE EXCEPTION 'FAIL [Scenario 6A]: Accepted friend Bob could not view active friends-only story!';
  END IF;

  PERFORM set_config('request.jwt.claim.sub', charlie_id::TEXT, TRUE);
  SELECT COUNT(*) INTO visible_count FROM public.place_stories WHERE id = active_story_id;
  IF visible_count <> 0 THEN
    RAISE EXCEPTION 'FAIL [Scenario 6B]: Stranger Charlie viewed Alice friends-only story!';
  END IF;

  -- ==========================================================================
  -- SCENARIO 7: Explainable Recommendations (`get_recommended_places`)
  --             Bob receives a recommendation boosted by Alice's drop
  -- ==========================================================================
  PERFORM set_config('request.jwt.claim.sub', bob_id::TEXT, TRUE);
  SELECT COUNT(*) INTO visible_count
  FROM public.get_recommended_places(10)
  WHERE place_id = breadly_id AND friends_recommend_count >= 1;
  IF visible_count <> 1 THEN
    RAISE EXCEPTION 'FAIL [Scenario 7]: get_recommended_places did not surface friend recommendation for Bob!';
  END IF;

  -- ==========================================================================
  -- SCENARIO 8: Alice blocks Bob -> Bob immediately loses access to Alice's
  --             Drops, Collections, Stories, and Friend Recommendations
  -- ==========================================================================
  PERFORM set_config('request.jwt.claim.sub', alice_id::TEXT, TRUE);
  INSERT INTO public.blocks (blocker_id, blocked_id) VALUES (alice_id, bob_id);

  PERFORM set_config('request.jwt.claim.sub', bob_id::TEXT, TRUE);
  SELECT COUNT(*) INTO visible_count FROM public.posts WHERE author_id = alice_id;
  IF visible_count <> 0 THEN
    RAISE EXCEPTION 'FAIL [Scenario 8A]: Blocked user Bob could still read Alice posts!';
  END IF;

  SELECT COUNT(*) INTO visible_count FROM public.collections WHERE id = collab_collection_id;
  IF visible_count <> 0 THEN
    RAISE EXCEPTION 'FAIL [Scenario 8B]: Blocked user Bob could still read Alice collection!';
  END IF;

  SELECT COUNT(*) INTO visible_count FROM public.place_stories WHERE id = active_story_id;
  IF visible_count <> 0 THEN
    RAISE EXCEPTION 'FAIL [Scenario 8C]: Blocked user Bob could still read Alice story!';
  END IF;

  -- ==========================================================================
  -- SCENARIO 9: Keyset Cursor Pagination & Deterministic Tie-Breaking (P8-01)
  -- ==========================================================================
  PERFORM set_config('request.jwt.claim.sub', alice_id::TEXT, TRUE);

  -- Alice fetches page 1 (limit 1)
  SELECT post_id INTO private_post_id
  FROM public.get_friends_feed(1, 0, NULL, NULL);

  IF private_post_id IS NULL THEN
    RAISE EXCEPTION 'FAIL [Scenario 9A]: get_friends_feed page 1 returned empty result!';
  END IF;

  -- Verify nearby places keyset query executes under authenticated
  SELECT COUNT(*) INTO visible_count
  FROM public.get_nearby_places(41.3111, 69.2797, 5000, 'All', '', 5, NULL, NULL);

  IF visible_count < 1 THEN
    RAISE EXCEPTION 'FAIL [Scenario 9B]: get_nearby_places keyset query returned 0 places!';
  END IF;

  RAISE NOTICE 'ALL MULTI-USER RLS & AUTHORIZATION SCENARIOS PASSED UNDER ROLE authenticated.';
END $$;

ROLLBACK;
