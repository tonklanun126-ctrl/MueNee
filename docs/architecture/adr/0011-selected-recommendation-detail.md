# ADR 0011: Preserve the selected recommendation snapshot in restaurant detail

- Status: Accepted
- Date: 2026-09-08

## Context

Phase 10 needs a restaurant/menu detail page reached from the deterministic Top
3 list. The list already holds strictly decoded active restaurant and menu
documents, the computed straight-line distance, and the displayed rank. Reading
those documents again could make the destination disagree with the card during
one navigation and would add two unnecessary public reads.

## Decision

Push a typed, immutable `RestaurantDetailArguments` value containing the
selected restaurant, menu, distance, and rank. Include both document IDs in the
route and reject the navigation data if either ID does not match the route.
Keep the source recommendations page on the Navigator stack so Android Back
returns to its existing scroll state.

Do not silently load a direct/restored detail URL in this MVP increment. Without
the selected snapshot, show a safe recovery page that returns to recommendations.
This makes the session boundary explicit and avoids introducing another loading
contract or stale-cache policy inside Phase 10.

## Consequences

- The card and detail page show one consistent snapshot and incur no extra
  Firestore reads or writes.
- Route/path mismatches fail without exposing IDs or SDK details.
- Process-restored deep links require the user to generate recommendations again.
  A future explicit repository-backed deep-link contract may replace this when
  product requirements justify its reads, loading states, and freshness policy.
- Maps, meal selection, and tracking remain outside this decision.
