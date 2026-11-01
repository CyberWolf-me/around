# PRODUCT_PRINCIPLES.md — Around Core Product Principles

This document establishes the six non-negotiable product and architectural principles governing all feature design, engineering prioritization, and data modeling across the **Around** platform.

## 1. Places Are the Primary Discovery Context
Every social artifact in Around—whether a Drop, a saved list item, a friend plan, or a 24-hour story—anchors to a real-world, canonical venue in PostgreSQL/PostGIS (`public.places`). Users do not browse an abstract, ungrounded social feed; they explore real neighborhoods and streets in Tashkent (`Mirabad`, `Yakkasaray`, `Yunusabad`, `Shaykhontohur`, `Mirzo Ulugbek`) through the people they trust.

## 2. People and Relationships Provide Trust
Anonymous star averages are noisy and easily gamed. Around treats mutual social relationships (`public.friendships` with `status = 'accepted'`) as the primary trust filter. Recommendations from accepted friends are always visually and architecturally separated from general public community reviews.

## 3. Experiences Are the Primary Content Unit
A **Drop** (`public.posts` + `public.post_media`) captures an authentic lived experience at a place: a photo, a concise note, a rating, descriptive vibe tags, and an explicit audience choice. Drops connect **People** to **Places** and drive the core product loop:
> *A person visits a place → creates a Drop → chooses an audience → friends discover it → someone saves the place or creates a Plan → another person visits and shares their own experience.*

## 4. Privacy Is Enforced by the Platform, Never Just the UI
Dual-layer visibility (`friends` vs. `public`), mutual friendship consent (`SEC-02`), bidirectional blocking (`public.blocks`), and chronological visit suppression (`hide_visits_history = true`) are foundational database invariants enforced by PostgreSQL Row-Level Security (RLS) and `SECURITY INVOKER` RPCs (`auth.uid()`). Client-side filtering is a secondary UX convenience, never the security boundary.

## 5. Discovery Improves Through Genuine Community Activity
As users save places (`want_to_go`, `been`), organize collections (`public.collections`), plan outings (`public.friend_plans`), and publish Drops, discovery becomes more relevant. Ranking and recommendations (`public.get_recommended_places`) must remain explainable, debuggable, and strictly privacy-preserving—never leaking private (`friends`-only) activity or visit history into global public signals.

## 6. Evolution Without Architectural Rewrites
We build Around through **comprehensive product thinking** paired with **incremental engineering delivery**. Foundations—such as UUID identity, PostGIS spatial indexing, modular Riverpod domain repositories, and versioned SQL migrations—are designed to support all eight capability domains (`Identity`, `Social Graph`, `Places`, `Experiences`, `Discovery`, `Collections`, `Trust & Safety`, `Engagement`) without disposable code or disruptive rewrites.
