# Around — Adversarial Product, UX & Growth Critique Report (Phase 11 Audit)

**Audit Date**: November 2, 2026  
**Auditor Personas**: Adversarial Product Critic, Senior UX Architect, Viral Growth Lead  
**Target Milestone**: Phase 11 — Viral Growth, Taste Passports & Contextual Discovery  
**Branch**: `feat/polsia-autonomous-loop-phase-11`

---

## Executive Summary & Strategic Tension

With Phase 9 (Real-Time Channels, 24h Venue Stories, Biometric Vault) and Phase 10 (Universal Deep Linking, Offline Outbox Exponential Retry Engine) verified and tagged (`v1.1.0-staging.1`), the product foundation is technically rock-solid:
- **66/66 Flutter unit & widget tests** pass.
- **16/16 Web Vitest tests** pass.
- **0 compiler & analyzer warnings**.

However, an adversarial product audit reveals 4 critical growth and UX barriers preventing Around from achieving organic network effects in Tashkent:

1. **Zero External Virality / Shareable Social Artifacts**:
   - Currently, a user who curates 20 amazing coffee spots in Mirabad has no single, high-aesthetic artifact to share to Instagram Stories or Telegram channels.
   - Discovery is trapped inside the client instead of generating organic user-to-user referral loops.

2. **High Friction in Mutual Friendship Onboarding**:
   - The "Dual-layer privacy" model requires mutual consent before friends-only drops unlock.
   - However, finding a friend currently requires knowing their exact username and navigating search. There is no instantaneous Invite Link or QR-code handshake.

3. **Static Venue Discovery vs. Real-Time Tashkent Rhythms**:
   - Venues are currently organized by static categories (`Specialty Roastery`, `Bakery`).
   - But Tashkent's urban social life is strictly time-contextual: morning sourdough & quiet laptop booths (08:00–12:00), mid-day business espresso (12:00–17:00), and sunset courtyards/cocktail vinyl sets (18:00+). The app does not adapt to the clock.

4. **Monolingual Friction in a Trilingual Metropolis**:
   - Tashkent is culturally trilingual: Uzbek (`O'zbekcha`), Russian (`Русский`), and English (`English`).
   - The UI is currently English-only, creating unnecessary cognitive friction for everyday local Tashkent residents.

---

## Actionable Phase 11 Backlog Specifications

### `P11-01`: Shareable Tashkent Taste Passport & Profile Card
- **Domain**: `Engagement` / `Discovery`
- **Core User Problem**: Users cannot show off their curated taste or favorite venues outside the app.
- **Deliverables**:
  - `TastePassportWidget`: An editorial, high-aesthetic digital passport card showcasing user's top recommended venues, district badges, and avatar.
  - Deep link handler `around://passport/:username` with rich copyable summary.
  - Interactive Preview & Share Modal on `ProfileScreen`.

### `P11-02`: Mutual Friend Invite Links & QR Connection Engine
- **Domain**: `Social Graph` / `Growth`
- **Core User Problem**: Adding friends requires manual search and asynchronous approval.
- **Deliverables**:
  - `FriendInviteService`: Generates deterministic invite codes and signed URLs (`https://around.tashkent.app/invite/:code`).
  - Auto-handshake: Opening an invite code immediately establishes or requests mutual friendship upon authentication.
  - Quick QR/Invite sheet in Profile and Settings.

### `P11-03`: Contextual Time-of-Day Atmosphere Engine & Real-Time Filter
- **Domain**: `Discovery` / `Places`
- **Core User Problem**: Explore recommendations ignore the current time and mood of the city.
- **Deliverables**:
  - `AtmosphereService`: Evaluates live Tashkent local time (`TimeOfDayMode`: Morning Brew, Afternoon Focus, Evening Golden Hour, Late Night Vinyl).
  - Dynamic atmosphere chip pills on `ExploreScreen` and `FeedScreen`.
  - Filter places by live ambiance score and operational vibe.

### `P11-04`: Trilingual Tashkent Localization Engine (UZ / RU / EN)
- **Domain**: `Platform` / `Identity`
- **Core User Problem**: English-only UI alienates local Russian- and Uzbek-speaking residents.
- **Deliverables**:
  - `LocaleService`: Persistent language selector (`en`, `ru`, `uz`) with Riverpod state.
  - Tashkent localized dictionary for common navigation labels, category pills, kicker strings, and action buttons.
  - In-app language switcher modal accessible from Settings.
