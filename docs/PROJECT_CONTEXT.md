# Project Context

## Overview

**Food Waste App** (working name — final brand TBD) is a mobile marketplace that connects bakeries, cafes, and pastry shops near a university campus with nearby users (primarily students). Businesses list their end-of-day surplus products at discounted prices; users reserve them via the app and pick them up in person before closing time.

## Why This Project Exists

Turkey wastes 7.7 million tons of food annually, with 93 kg per capita yearly loss. No dominant player exists in the Turkish surplus food market:
- **Too Good To Go** (global leader, 120M+ users across 21 countries) does not operate in Turkey.
- **Fazla Gıda** (Turkish competitor) pivoted to B2B and couldn't scale B2C beyond Istanbul.
- **Yenir** operates at small scale with limited reach.

Demand exists; supply does not. The university campus is a contained test market with high concentration of price-sensitive users and nearby food businesses.

## Target Users

### End Users
- University students (18-25) near Istanbul University
- Price-sensitive, environmentally conscious
- Smartphone-native, comfortable with mobile payments and pickup flows
- Value both savings AND impact (saving food from waste)

### Business Users
- Bakeries, cafes, pastry shops within 2 km of campus
- Small-to-medium independent shops (not chains)
- Daily surplus of shelf-stable baked goods (bread, pastries, sandwiches, desserts)
- Not digitally sophisticated — the app MUST be simple enough for a baker with no tech background

**Restaurants are explicitly out of scope** for MVP due to cooked-food safety risk and complex onboarding.

## Core Value Proposition

### For Users
"Save food from waste, save money, and feel good about it — pick up discounted bakery items from local shops."

### For Businesses
"Recover revenue from products that would otherwise go to waste — zero fees during pilot, no cash register integration required, we bring you customers."

## Differentiation

The app must differ from TGTG/Fazla Gıda on three axes:

1. **Hybrid listing model** — businesses can list either menu items (user sees exactly what they're buying) OR surprise boxes (mystery bag of mixed items). Business chooses per product. TGTG only offers surprise boxes.
2. **Dynamic time-based pricing** — price automatically drops as pickup deadline approaches (e.g., -3h: 30% off, -2h: 50% off, -1h: 70% off). Creates urgency and encourages repeat app visits.
3. **Bakery/cafe focus** — intentional narrow focus reduces food safety risk, simplifies onboarding, builds trust faster.

## MVP Scope (6 weeks)

### In Scope
- User and business authentication
- KVKK compliance (privacy notice, consent flow, user agreement)
- Business profile and product listing (hybrid: menu or surprise box)
- Map view (Google Maps) + list view of nearby products
- Product detail page with live-updating dynamic pricing countdown
- Reservation flow (NO in-app payment — user pays business directly on pickup)
- Business-side order management (approve, reject, mark picked up)
- Impact dashboard (kg saved, money saved, CO2 prevented)
- Order history

### Out of Scope (future phases)
- In-app payment (Iyzico integration)
- Push notifications (FCM)
- Reviews/ratings
- Delivery/courier integration
- Multi-city expansion
- B2B analytics suite
- Subscription model
- Multi-language support

## Success Metrics (End of 6 Weeks)

| Metric | Target | Stretch |
|--------|--------|---------|
| Onboarded businesses | 5 | 8+ |
| Registered users | 30 | 100+ |
| Total orders | 50 | 200+ |
| Food waste prevented | 25 kg | 100+ kg |
| User satisfaction | 4.0/5 | 4.5+ |

## Business Model (Future Phases)

**Phase 1 (MVP, current):** Free for businesses. Goal is onboarding and proving value.

**Phase 2 (post-MVP):** Commission model (10-15% per transaction — exact rate TBD).

**Phase 3 (long-term):** Commission + optional annual business subscription for premium features.

The MVP does NOT implement payment. All payment happens offline (user pays business at pickup). This intentionally bypasses Turkish e-commerce regulations during the pilot phase.

## Non-Negotiable Constraints

- **Timeline:** 6 weeks, hard deadline (course project).
- **Team:** 4 people (including project lead).
- **Budget:** Zero TL (no paid services, must use free tiers).
- **Legal:** KVKK compliance is mandatory (privacy notice, explicit consent, user agreement).
- **Food safety:** Liability disclaimer required in user agreement; business protocol must include food safety undertaking.

## Brand Identity

### Color Palette
Intentionally terracotta-based to differentiate from green-dominated food waste app category:

- **Primary accent:** Terracotta (`#C1440E`)
- **Dark surfaces/text:** Dark brown (`#2C1A0E`)
- **Backgrounds:** Warm beige (`#F5F0EB`)
- **Secondary accent:** Light terracotta (`#E8A090`)
- **Semantic green:** Small accent for impact metrics only (`#059669`)

### Tone of Voice
- Warm, human, grounded (not corporate)
- Simple language (most users are students with busy schedules)
- Urgency without anxiety (dynamic pricing creates FOMO but should feel fun, not stressful)
- Turkish first, English support deferred to future phase

## Open Decisions (Not Yet Finalized)

These are intentionally unresolved and documented so the agent does NOT invent values:

- **Brand name** — currently placeholder "Food Waste App"
- **Dynamic pricing tiers** — proposed 30%/50%/70% at 3h/2h/1h marks, pending team vote
- **Dynamic pricing trigger** — automatic vs hybrid (business override), pending decision
- **Commission rate (Phase 2)** — 10-15% range, pending decision
- **Impact coefficient** — proposed 0.8 kg/order average weight, 2.5 kg CO2/order

When the agent encounters these, it should mark them clearly in code with `TODO: pending team decision` rather than hardcoding values.
