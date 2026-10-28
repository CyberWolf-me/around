# ADR 002: Dual-Layer Privacy & Audience Isolation Engine

## Status
Accepted

## Context
Around's core product hypothesis states: *"People discover places more confidently when real experiences from trusted friends are connected to useful public place information."*
However, connecting social recommendations to real-world venues introduces significant privacy risks:
- Users do not want the public internet to track their routine coffee spots, study schedules, or weekend plans.
- Traditional review apps force either complete anonymity or complete public exposure.
- Users need granular control per contribution (Friends Only vs. Public).

## Decision
We enforce a **Dual-Layer Content Privacy Model**:
1. **Explicit Audience Selection at Creation**:
   - Every Place Drop requires an explicit audience setting (`friends` or `public`).
   - The user configures a global default (e.g., "Friends Only" by default), which pre-populates the creator flow but can be overridden per post.
2. **Strict Query & Filter Layer**:
   - The Feed screen queries *only* contributions from followed connections.
   - The Explore screen queries *only* contributions flagged as `public`.
   - Place pages partition social proof into two distinct sections:
     - Top Section: Friends' recommendations and photos (visible only if connections have dropped the venue).
     - Bottom Section: Public community reviews and ratings.
3. **Location History Decoupling**:
   - Marking a drop as Public shares only the specific photo, note, and rating. It never exposes the user's historical movements, itinerary, or current live GPS location.
   - A global privacy toggle ("Keep my visits private") completely suppresses the user's name from public visit lists.

## Consequences
- **Positive**:
  - Unmatched user trust: university students and young urbanites can share candid recommendations with close friends without fear of public stalking.
  - Clear UX boundaries that prevent accidental oversharing.
  - Compliant with App Store Review Guidelines (Section 5.1) and GDPR principles of data minimization.
- **Negative / Mitigations**:
  - Public place pages have fewer drops initially if most users post to friends; mitigated by pre-seeding verified local public reviews and encouraging public tips for non-sensitive venue insights.
