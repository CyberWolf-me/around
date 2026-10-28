# ADR 001: Mobile Application Architecture & Client Framework Selection

## Status
Accepted

## Context
Around requires a mobile-first user experience that feels native, tactile, visual, and instantaneous. The product mandates:
- Rich tactile micro-interactions (haptics, sheet gestures, bento grid layout, interactive vector maps).
- Fast shared-element transitions (hero photo flights from feed/list into place pages).
- Offline-first capabilities (caching saved places, optimistic drop creation, persistent settings).
- Multi-platform accessibility (iOS, Android, and mobile web PWA).
- Rapid iteration speed during the concept-definition and initial 20-30 user university validation phase.

## Decision
We select a **React + TypeScript + Vite** architecture with modern modular design system primitives, structured around:
1. **Presentation Layer**: Mobile-first responsive container with dual runtime capability:
   - In-device preview mode (iPhone 16 Pro and Android Google Pixel frames with authentic status bar, dynamic island, and gesture bars) for desktop/demo environments.
   - Pure standalone mobile web viewport / Progressive Web App (PWA) mode for direct on-device testing.
2. **Design Tokens & Theme Architecture**:
   - Typography: Bricolage Grotesque (display headings), Instrument Sans (body copy), Space Mono (metadata/tags).
   - Color Palette: Bone paper (`#FBFAF6`), Ink typography (`#15130F`), Signal Orange (`#FF5A1F`), Butter (`#FFE07A`), Mint (`#D5E8CB`), Cobalt (`#2B4CFF`).
   - Tactile shadows: 3px/5px solid ink offsets (`var(--sh)`).
3. **State Management**:
   - React Context + Reducer pattern with LocalStorage persistence (`src/services/storage.ts`).
   - Optimistic updates for drop publishing, bookmarking/saving, and social follows.
4. **Vector Map Engine**:
   - Custom lightweight SVG vector mapping engine with reactive pan/zoom, interactive venue pins with photo bulbs, custom Barlow Hill street grid, and user coordinate pulses.
   - Zero heavyweight 3rd-party map SDK bloat, yielding instant cold boot (<300ms) and zero API quota costs during initial validation.

## Consequences
- **Positive**:
  - Instant live reloading (Vite HMR) enables rapid UI refinement.
  - Zero cross-compilation delays: developers can test in Chrome/Safari mobile inspector and real devices immediately via local network URL.
  - Fully testable with Vitest and standard Web APIs.
  - Easy packaging into iOS/Android native wrappers (Capacitor / React Native) when expanding past the MVP pilot.
- **Negative / Mitigations**:
  - Web vibration API has varying support across iOS Safari; mitigated with a haptic abstraction service that gracefully degrades to visual cues.
