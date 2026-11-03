# Around — Competitive Analysis: Yandex Maps, 2GIS & The Social Differentiation

**Author:** CEO & CTO  
**Date:** November 2, 2026  
**Status:** Ratified Strategy — Path A Selected with Path B Monetization Runway  
**Branch:** `feat/phase-12-strava-for-places`

---

## 0. Executive Summary & Reality Check

Our early product framing positioned Around as a "places-first discovery app" alongside Yandex Maps and 2GIS as "just navigation tools." That premise was fundamentally flawed.

In Uzbekistan, Yandex Maps (2.8M monthly users, Uzbek language support, AI review summaries, curated thematic collections, contextual neural recommendations) and 2GIS (95% field-verified data accuracy, offline directory, "Friends on the Map" location sharing) dominate utilitarian place discovery. They have tens of thousands of reviews, photos, business hours, price tiers, and delivery integrations.

**We cannot and will not compete with Yandex Maps or 2GIS on directory size or map navigation.**

Instead, Around's definitive strategic moat is the **social graph and trust layer**:
- Not *"What cafe is near me?"* (Yandex answers this)
- But *"Where did Kamila go for coffee on Saturday that she actually loved, and who wants to meet at Breadly tomorrow morning?"*

---

## 1. Feature-by-Feature Matrix: Yandex Maps vs. 2GIS vs. Around

### 1.1 Place Discovery & Content

| Feature | Yandex Maps | 2GIS | Around | Strategic Assessment |
|---|---|---|---|---|
| Curated thematic collections | Yes (32+ collections) | Yes (city guidebooks) | Yes (custom collections) | Parity; ours are friend-created |
| AI personalized recommendations | Yes (neural network context-aware) | No | Yes (time-of-day atmosphere engine) | Yandex has massive data advantage |
| AI chat for place queries | Yes (Alice AI + YandexGPT) | No | No | Commodity utility; out of scope |
| AI review summarization | Yes | No | No | We use verified friend notes, not anonymous reviews |
| Business directory (hours, pricing) | Yes (extensive) | Yes (95% field-verified) | Thin metadata | Use external APIs; do not maintain directory |
| Real-time busyness | Yes | No | No | Out of scope |
| Photos per venue | Thousands | Thousands | Drops from social circle | Ours are authentic friend memories |

### 1.2 Social & Graph Features

| Feature | Yandex Maps | 2GIS | Around | Strategic Assessment |
|---|---|---|---|---|
| Real-time location sharing | Yes (since Jan 2026) | Yes ("Friends on the Map") | No | Tracking vs. sharing intent |
| Friend-based place recommendations | **No** | **No** | **Yes** | **Core Differentiator** |
| Social feed (friend drops & ratings) | **No** | **No** | **Yes** | **Core Differentiator** |
| Mutual friendship graph (consent-based) | **No** | **No** | **Yes** | **Core Differentiator** |
| Friend plans with RSVP | **No** | **No** | **Yes** | **Core Differentiator** |
| Dual-layer privacy (Friends vs. Public RLS) | **No** | **No** | **Yes** | **Core Differentiator** |
| 24h ephemeral venue stories | **No** | **No** | **Yes** | **Core Differentiator** |
| Shareable Taste Passport | **No** | **No** | **Yes** | **Core Differentiator** |
| Telegram friend discovery & invite loop | No | No | **Planned (P12)** | **Key Distribution Weapon** |

---

## 2. The Three Strategic Paths

### Path A: Niche Social Network ("Strava for Places" / "Letterboxd for City Life")
- **Thesis:** Around is not a map utility; it is the social network for your urban lifestyle. Strava did not build GPS or maps — it built athletic identity and friend motivation on top of commodity maps. Letterboxd built cinephile social profiles on top of TMDb.
- **Mechanism:** Anchor drops and social interactions to canonical place identities resolved against external APIs (Yandex/2GIS/OSM). Feed is the home screen; friends are the retention engine.
- **Pros:** Clear positioning, avoids impossible directory maintenance, unlocks strong word-of-mouth loops.
- **Cons:** Cold-start challenge requires dense local seeding in Tashkent.

### Path B: B2B Venue SaaS & Analytics ("Square for Cafes")
- **Thesis:** Sell foot-traffic analytics, social save intent, and customer demographic insights to venue owners ($20–$50/month).
- **Mechanism:** Venues use a dashboard to track which friend circles are saving their places, viewing their stories, and organizing plans.
- **Pros:** Clear revenue from Day 1; venue owners promote Around to their patrons.
- **Cons:** B2B tooling distracts from initial consumer network effects if launched prematurely.

### Path C: Hyper-Local Community ("Nextdoor for Tashkent")
- **Thesis:** District-first neighborhood chat and recommendations.
- **Cons:** Weak identity; Telegram neighborhood chats already saturate this niche.

---

## 3. Ratified Decision: Path A with Path B Monetization Runway

**The Founder and Executive Team have ratified:**
1. **Primary Play: Path A ("Strava for Places")**
   - Reposition Around as the social network for city life and shared tastes.
   - The Social Feed is the hero screen; maps are contextual viewers.
   - Integrate Telegram friend discovery as our primary distribution engine.
   - Anchor social drops to canonical place UUIDs while allowing external directory resolution.
2. **Monetization Runway: Path B (Aggregated Venue Analytics)**
   - Architect telemetry and event instrumentation from Day 1 to record aggregated, privacy-preserving venue affinity metrics (drop counts, saves, demographic neighborhood reach, peak atmosphere hours).
   - In Phase 12D / Phase 13, package this intelligence into a self-service B2B portal for Tashkent cafe and restaurant owners.
