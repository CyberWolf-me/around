# RELEASE_CHECKLIST.md — Around Comprehensive Platform Release Gate

This checklist defines Around's **four completion tiers** (`Schema & Backend Ready`, `Capability Complete`, `Product Integrated`, `Platform Ready`) and tracks the **Staging & Public Release Gate** across all eight product domains.

## 1. Completion Tier Definitions

| Tier | Definition | Verification Standard |
|---|---|---|
| **1. Schema & Backend Ready** | Database tables, triggers, and RLS policies are implemented and verified in SQL. | `supabase db reset` and `rls_authorization_test.sql` pass. |
| **2. Capability Complete** | Domain functionality, data contracts, and repository methods are implemented in both SQL and Dart. | Unit tests and static analysis pass. |
| **3. Product Integrated** | The domain connects seamlessly across multi-domain user journeys in `lib/` and `supabase/`. | Widget tests and cross-repository flows pass. |
| **4. Platform Ready** | Live multi-user staging RLS tests, physical iOS/Android device verification, and operational monitoring are proven. | Awarded after completing Steps 1–4 of `docs/reports/STAGING_DEPLOYMENT_PLAN.md`. |

## 2. Domain Readiness Matrix

| Domain | Required Capabilities for Release | Current Tier | Evidence in Repository |
|---|---|---|---|
| **1. Identity** | Registration, sign-in, session persistence, `syncRemoteProfile`, profile editing, privacy preferences, GDPR export & server-side account deletion (`delete_own_account()`), production email confirmation guard. | **Platform Ready** | `lib/features/auth/screens/auth_screen.dart`, `profile_screen.dart`, `settings_screen.dart`, `00004`, `00005`, `00008` |
| **2. Social Graph** | Friend discovery, `user_id`/`friend_id` requests, recipient-only acceptance (`SEC-02`), `syncRemoteFriendships`, `syncRemoteBlocks`, bidirectional blocking. | **Platform Ready** | `lib/data/repositories/profiles_repository.dart`, `user_profile_screen.dart`, `00002`, `00005`, `rls_authorization_test.sql` |
| **3. Places** | 9 canonical Tashkent venues, PostGIS spatial search (`get_nearby_places`), unauthenticated guest access, category/tag filters, `FlutterMap` & list views, directions. | **Platform Ready** | `lib/features/explore/screens/explore_screen.dart`, `place_detail_screen.dart`, `places_repository.dart`, `00003`, `00008`, `seed.sql` |
| **4. Experiences** | 4-step Drop creation, private `post-media` upload with signed URLs (`SEC-14`) & `storagePath` orphan cleanup, `editDrop` & `deleteDrop`, rating recalculation trigger. | **Platform Ready** | `lib/features/create_post/screens/create_drop_sheet.dart`, `posts_repository.dart`, `supabase_service.dart`, `00004`, `00005` |
| **5. Discovery** | Finite Friends Feed (`get_friends_feed` `SECURITY INVOKER`), `syncRemotePlaceDrops`, Place Detail Friends/Public tabs, explainable recommendations (`get_recommended_places` + ExploreScreen 'For You'). | **Platform Ready** | `lib/features/feed/screens/feed_screen.dart`, `lib/features/explore/screens/explore_screen.dart`, `places_repository.dart`, `00003`, `00005`, `00006` |
| **6. Collections** | Saved places (`want_to_go` / `been` + `syncRemoteSavedPlaces`), Friend Plans (`addPlan` + `rsvpToPlan` with interactive RSVP chips), custom curated collections (`collections`, `collection_items`). | **Platform Ready** | `lib/features/saved_places/screens/saved_screen.dart`, `saved_places_repository.dart`, `collections_repository.dart`, `00001`, `00006` |
| **7. Trust & Safety** | Dual-layer RLS, `hide_visits_history` enforcement, user/drop/place reporting, 3-report auto-quarantine, rate limiting, `moderation_audit_logs`, hardened account deletion (`00008`). | **Platform Ready** | `lib/features/settings/screens/settings_screen.dart`, `00002`, `00004`, `00005`, `00006`, `00008`, `rls_authorization_test.sql` |
| **8. Engagement** | In-app Activity & Notifications (`NotificationsRepository` + `notifications`), Drop reactions (`reactToPost`), post comments (`CommentsSheet`), 24h Venue Stories (`StoryRail` viewer & creator), Quiet Hours. | **Platform Ready** | `lib/data/repositories/notifications_repository.dart`, `stories_repository.dart`, `comments_sheet.dart`, `lib/features/feed/screens/notifications_screen.dart`, `bento_card.dart`, `story_rail.dart`, `00006` |
