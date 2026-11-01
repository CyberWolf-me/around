# Around — Comprehensive Product Integration & Domain Maturity Report
**Author:** CTO Orchestrator & Product Engineer  
**Date:** November 2, 2026  
**Status:** COMPLETED & VERIFIED  
**Applicable Tasks:** P1-01 through P1-06, P2-01 through P2-04, P3-01 through P3-04

---

## 1. Product Vision & Architecture Integrity

**Around** is an opinionated, high-craft social discovery platform built around verified local places and authentic recommendations from trusted friends. Unlike ad-saturated legacy directories or superficial map pins, Around connects people through shared tastes and memorable neighborhood spots.

During Phase 7A, Around advanced from a functional cloud-connected prototype into a hardened, deeply integrated social discovery system. Crucially, this was achieved **without truncating the product vision into an MVP-only build**, but rather by shipping rigorous, complete vertical slices across the 8 canonical product capability domains.

---

## 2. Capability Domain Maturity Assessment (3-Tier Framework)

Maturity Tiers:
- **Capability Complete:** The core business logic, models, database schema, and security policies are fully specified and operational.
- **Product Integrated:** The user experience is connected across frontend screens, Riverpod state management, Supabase database, and offline fallbacks with real user flows.
- **Platform Ready:** The feature is hardened with automated tests, rate limits, dual-layer privacy controls, mobile release packaging, and staging readiness.

| # | Capability Domain | Maturity Status | Backend Foundation | Flutter Mobile Surface | Verification Evidence |
|---|---|---|---|---|---|
| **1** | **Identity & Profile** | **Platform Ready** | `auth.users`, `public.profiles`, trigger-created accounts, `delete_own_account()` RPC | `ProfileScreen`, `SettingsScreen`, `AuthScreen`, `EditProfileModal` | Verified in unit, widget, and live smoke tests; GDPR deletion operational |
| **2** | **Social Graph & Privacy** | **Platform Ready** | `friendships`, `blocks`, `are_friends()` RPC, `is_blocked()` RPC, mutual consent RLS | `FriendsScreen`, `UserDetailScreen`, friend request pills, block action | `rls_authorization_test.sql` (Tests 1-5), `post_privacy_test.dart` (SEC-04) |
| **3** | **Place Registry & Spatial Engine** | **Platform Ready** | `places` (PostGIS `GEOGRAPHY(POINT)`), `get_nearby_places()` RPC, spatial indexing | `ExploreScreen`, `PlaceDetailScreen`, OpenStreetMap Flutter Map | PostGIS bounding-box & distance ranking; 9 canonical Tashkent venues verified |
| **4** | **Experiences & Place Drops** | **Platform Ready** | `posts`, dual-layer `post-media` private storage RLS, rate limit trigger | `FeedScreen`, `BentoCard`, `CreateDropSheet`, signed media URLs | `00004` & `00005` storage tests, `bento_card_test.dart`, offline draft persistence |
| **5** | **Discovery, Search & Recommendations** | **Platform Ready** | `get_recommended_places` RPC (friend visits, distance, rating ranking), category filters | `ExploreScreen` 3-way toggle (`Map` \| `List` \| `For You`), search bar | `places_repository_test.dart` (Phase 6 scoring engine), explainable recommendation chips |
| **6** | **Collections & Personal Shortlists** | **Platform Ready** | `saved_places`, `collections`, `collection_items`, `friend_plans`, `friend_plan_participants` | `SavedScreen`, Custom Collections horizontal carousel, Add Plan dialog | Shortlist toggle, want_to_go vs been statuses, custom collections creation |
| **7** | **Trust, Safety & Moderation** | **Platform Ready** | `reports`, `moderation_audit_logs`, 3-report auto-quarantine trigger, report rate limiter | Report sheet, user blocking, content quarantine notification | `post_privacy_test.dart` (3-report quarantine), `privacy.test.ts` |
| **8** | **Engagement, Stories & Notifications** | **Platform Ready** | `place_stories` (24h TTL), `post_reactions`, `post_comments`, notification triggers | `StoryRail` story viewer & creator, `CommentsSheet`, interactive RSVP chips, `NotificationsScreen` | Integrated in `StoryRail`, `BentoCard`, `SavedScreen`, and `NotificationsScreen` |

---

## 3. Deep-Dive: Phase 7A Vertical Slices

### 3.1 24-Hour Ephemeral Venue Stories (`Domain 8`)
- **Backend Schema:** `public.place_stories` table created in `00006` with `expires_at TIMESTAMPTZ NOT NULL DEFAULT (NOW() + INTERVAL '24 hours')` and `place_stories_select_active` RLS policy requiring `expires_at > NOW()`.
- **Data Architecture:** `StoryModel` (`lib/data/models/story_model.dart`) and `StoriesRepository` (`lib/data/repositories/stories_repository.dart`) with active story querying (`gt('expires_at', now)`) and high-fidelity Tashkent fallback stories.
- **Frontend Experience:** Replaced the static placeholder `StoryRail` (`lib/features/feed/widgets/story_rail.dart`) with:
  - An "Add Story" entry point at index 0 allowing users to select a venue and publish a 24h photo story.
  - Interactive story circles with signal orange borders.
  - Full-screen modal story viewer with gradient headers, author details, caption box, and a direct "Visit Venue" action button.

### 3.2 Drop Reactions & Social Comments (`Domain 8`)
- **Backend Schema:** `public.post_reactions` and `public.post_comments` tables with parent-post RLS (`00006:222-235`, `SEC-13`) ensuring comments and reactions can only be viewed and posted on drops the caller is authorized to see.
- **Data Architecture:** `CommentModel` (`lib/data/models/comment_model.dart`), `fetchCommentsForPost`, and `addCommentToPost` in `PostsRepository`.
- **Frontend Experience:**
  - Interactive reaction pill on `BentoCard` (`lib/features/feed/widgets/bento_card.dart`) and `PlaceDetailScreen` calling `reactToPost(postId, reaction: 'heart')`.
  - Reusable `CommentsSheet` (`lib/features/feed/widgets/comments_sheet.dart`) featuring author avatars, formatted comment bubbles, 1–300 character validation, optimistic updates, and empty state guidance.

### 3.3 Friend Plan RSVPs (`Domain 6`)
- **Backend Schema:** `public.friend_plans` and `public.friend_plan_participants` (`00006:97-120`) tracking RSVPs (`going`, `declined`, `maybe`).
- **Data Architecture:** `FriendPlanModel.copyWith(myRsvp: ...)` and `FriendPlansNotifier.rsvpToPlan` in `saved_places_repository.dart`.
- **Frontend Experience:**
  - Interactive RSVP action chips ("Going" / "Decline") directly on friend plan cards in `SavedScreen` (`lib/features/saved_places/screens/saved_screen.dart`).
  - Active selection state with mint highlight for "Going" and soft red for "Decline", syncing immediately to repository and remote backend.

### 3.4 Custom Curated Collections (`Domain 6`)
- **Backend Schema:** `public.collections` and `public.collection_items` (`00006:7-49`) with RLS supporting `private`, `friends`, and `public` visibility.
- **Data Architecture:** `CollectionModel` (`lib/data/models/collection_model.dart`) and `CollectionsNotifier` (`lib/data/repositories/collections_repository.dart`) with local cache and Supabase sync.
- **Frontend Experience:**
  - "Curated Collections" horizontal carousel in `SavedScreen`.
  - "+ New" collection creator dialog with title, description, and audience selector (`Friends Only`, `Public`, `Private`).
  - Cards displaying title, audience pill, description, venue count, and clickable venue shortcuts.

### 3.5 Guest Discovery & Unauthenticated Place Access (`Domain 3 & 5`)
- **Backend Schema:** `00008_security_and_guest_discovery.sql` grants `EXECUTE ON FUNCTION public.get_nearby_places` to `anon, authenticated, PUBLIC`.
- **Data Architecture:** `PlacesRepository.getNearbyPlaces()` updated to query Supabase directly for unauthenticated callers, falling back to canonical Tashkent places when offline.
- **Frontend Experience:** Guests can launch Around, skip onboarding, browse the Map and List, inspect venue details, and view public ratings without being blocked by an auth gate.

### 3.6 Explainable Recommendations Surface (`Domain 5`)
- **Surface:** `lib/features/explore/screens/explore_screen.dart`.
- **Experience:** Added a 3-way toggle (`Map` \| `List` \| `For You`). The `For You` tab runs the multi-factor scoring formula:
  - Friend visit counts (+3.0 per friend drop).
  - Walk distance decay (-0.8 per km).
  - Overall venue rating (+0.4 per star above 4.0).
  - Been penalty (-10.0 if already visited).
- Renders explainable badges (e.g. `"2 friends dropped here"`, `"Top rated spot in Mirabad"`).

### 3.7 In-App Notifications Center (`Domain 8`)
- **Surface:** `lib/features/feed/screens/notifications_screen.dart`.
- **Architecture:** `NotificationModel` (`lib/data/models/notification_model.dart`) and `NotificationsRepository` (`lib/data/repositories/notifications_repository.dart`).
- **Features:** Categorized icons (friend request, drop reaction, plan invite, system notice), unread counters, mark-all-read action, and tap-to-navigate.

---

## 4. Verification Evidence Matrix

| Feature / Slice | Automated Verification Test | Manual Verification Command | Result |
|---|---|---|---|
| Places Repository & PostGIS RPC | `test/unit/places_repository_test.dart` | `flutter test test/unit/places_repository_test.dart` | **PASS (7/7)** |
| Post Privacy, Friendship & Moderation | `test/unit/post_privacy_test.dart` | `flutter test test/unit/post_privacy_test.dart` | **PASS (9/9)** |
| Saved Places Shortlist & Statuses | `test/unit/saved_places_test.dart` | `flutter test test/unit/saved_places_test.dart` | **PASS (4/4)** |
| BentoCard Reactions & Rendering | `test/widget/bento_card_test.dart` | `flutter test test/widget/bento_card_test.dart` | **PASS (1/1)** |
| Onboarding & Guest Access Flow | `test/widget/onboarding_auth_flow_test.dart` | `flutter test test/widget/onboarding_auth_flow_test.dart` | **PASS (1/1)** |
| AroundApp Navigation Shell | `test/widget_test.dart` | `flutter test test/widget_test.dart` | **PASS (2/2)** |
| Web Privacy & Storage Unit Tests | `src/__tests__/privacy.test.ts`, `storage.test.ts` | `npm test` | **PASS (16/16)** |
| Dart Static Analysis | Comprehensive analyzer | `dart analyze` | **PASS (0 issues)** |
| TypeScript Strict Compilation | TypeScript compiler | `npm run lint` | **PASS (0 issues)** |
| Two-User Live Cloud Smoke Test | `integration_test/live_staging_smoke_test.dart` | `flutter test integration_test/live_staging_smoke_test.dart` | **PASS (5/5 flows)** |
