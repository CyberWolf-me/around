# PRODUCT.md — Around Long-Term Product Vision & Specification

## 1. Strategic Vision

**Around** is a places-first social discovery platform launching in **Tashkent, Uzbekistan**. Its central experience is not simply browsing a static directory or reading anonymous reviews—it is discovering places through **people, experiences, and communities**.

Around connects three fundamental dimensions into a single continuous product loop:
1. **Places (The Foundation of Discovery):** Real-world cafés, bakeries, study spaces, parks, and cultural venues in Tashkent with accurate geospatial coordinates, hours, vibe tags, and neighborhood context.
2. **People (The Foundation of Trust):** Mutual friends, trusted profiles, authentic relationships, and transparent social proof.
3. **Experiences (The Foundation of Engagement):** Place Drops, photos, notes, ratings, saved collections, shared plans, 24-hour stories, and contextual recommendations.

### The Core Product Loop
> **Visit a Place → Create a Drop → Choose an Audience (`Friends` or `Public`) → Friends Discover It → Save to a Collection or Create a Plan → Visit & Share Back.**

## 2. Principal User Journeys

1. **Trusted Morning / Work Spot Search:** A user in Mirabad or Yakkasaray opens **Around** to find a quiet café with power outlets and good espresso, checks the **Friends Feed** and **Explore Map**, sees a mutual friend's Drop at *Breadly Bakery & Café* or *B&B Coffee House*, and saves it to their `Want to go` shortlist.
2. **Publishing a Place Drop:** After visiting *Ecorn Patisserie* or *Chorsu Milliy Taomlar*, a user taps **DROP**, selects or captures a photo, picks the venue (or adds a new Tashkent spot), writes a short note with vibe tags, selects `Friends Only` or `Public Discovery`, and publishes.
3. **Planning with Friends:** From their **Saved** shortlist, a user switches a visited venue from `Want to go` to `Been` or creates a shared **Friend Plan** (e.g., *"Sat 10:30 AM — Morning sourdough & lavender matcha run"*) with invited friends.
4. **Privacy & Safety Control:** A user enables *"Keep my visits private"* (`hide_visits_history`) so their profile never exposes a chronological location tracker, manages incoming friend requests with mutual consent, blocks unwanted accounts, or exports/deletes their account data at any time.

## 3. Dual-Layer Content Visibility Rules

1. **Friends-Only Layer (`audience = 'friends'`)**:
   - Default setting for new Drops.
   - Visible strictly to the author and mutually accepted friends (`friendships.status = 'accepted'`).
   - Enforced at the PostgreSQL Row-Level Security (RLS) boundary (`posts_select_dual_layer` and `get_friends_feed`).
2. **Public Discovery Layer (`audience = 'public'`)**:
   - Opt-in community layer visible in Explore and the "Public Reviews" tab on Place Detail screens.
   - Automatically hides content from blocked users (`is_blocked`) and posts quarantined by community moderation (`is_quarantined = true` at `reports_count >= 3`).
3. **Chronological Visit History Suppression (`hide_visits_history = true`)**:
   - Enabled by default so viewing another user's profile never exposes a surveillance-style timeline of where they have been (`get_user_visible_drops`).

## 4. Eight Platform Capability Domains

Around's architecture is organized into eight cohesive capability domains (detailed in `PRODUCT_CAPABILITIES.md` and `ARCHITECTURE.md`):
1. **Identity:** Accounts, authentication, profiles, preferences, and GDPR lifecycle.
2. **Social Graph:** Mutual friendships, invitations, relationship states, and blocks.
3. **Places:** Tashkent venues, PostGIS coordinates, maps, search, and categories.
4. **Experiences:** Drops, photos, reviews, ratings, tags, editing, and deletion.
5. **Discovery:** Friends Feed, Global Discovery, search, and explainable recommendations.
6. **Collections:** Saved places (`want_to_go`, `been`), custom lists, and Friend Plans.
7. **Trust & Safety:** Dual-layer privacy, blocking, reporting, 3-report quarantine, and moderation audit logs.
8. **Engagement:** Activity center, notifications, 24-hour Venue Stories, reactions, and comments.
