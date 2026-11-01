# ADR 0010: Deterministic client-side Top 3 recommendations

- Status: Accepted
- Date: 2026-09-08

## Context

The MVP needs three nearby menu suggestions after location, budget, and food
preferences are ready. The initial catalog has 10 restaurants and 30 menus.
Its prices and nutrition include explicit confidence, while complete dietary
evidence is intentionally often unknown. There is no approved nutrition target
or trusted need for server-side ranking at this scale.

## Decision

Read bounded active restaurant and menu candidate sets from public, read-only
Firestore queries and rank them locally with deterministic Dart code. Reject
inactive, orphaned, over-budget, and food-safety-ineligible menus before scoring.
Never relax hard dietary restrictions or allergies to fill three positions.

Eligible candidates receive at most 100 explanatory points:

- distance: 45, decreasing linearly to zero at 5 km;
- affordability within the confirmed budget: 20;
- current price confidence: 25 verified, 12 estimated, 0 unverified;
- preference: 10 when no disliked ingredient is declared, otherwise 0.

Regardless of points, eligible disliked menus follow all eligible non-disliked
menus, preserving the approved soft-preference contract. Remaining ties resolve
by distance, price, Thai menu name, and document ID. Return at most three.

Within each preference tier, pick the best menu from each unused restaurant
before filling remaining slots from repeated restaurants. This variety rule
can favor a lower-scoring restaurant; it never moves a disliked item ahead of
an eligible non-disliked item. Distance is straight-line, not a travel route.

Nutrition estimates are displayed but not scored until a validated personal
nutrition target exists. Restaurant rating is also not scored because its source
and freshness are not yet part of the recommendation contract. Gemini is not
used.

## Consequences

- The same inputs and evaluation time produce the same ranking.
- Ranking is inspectable, testable, and inexpensive for the MVP catalog size.
- A strict setting may legitimately produce zero results; the UI explains this
  and offers budget/settings recovery without weakening safety.
- Catalog access is read-only. No Cloud Function, new index, rule deployment,
  Firestore write, tracking event, map, or restaurant detail is introduced.
- A larger catalog or protected ranking policy may justify a server-side design
  in a separately approved phase.
