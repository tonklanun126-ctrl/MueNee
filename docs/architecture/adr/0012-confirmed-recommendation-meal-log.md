# ADR 0012: Confirmed recommendation meal logs

- Status: Accepted
- Date: 2026-09-10

## Context

After viewing a recommendation and its restaurant, the user needs to record the
chosen meal for later daily tracking. A tap must not be confused with restaurant
ordering, and client-owned logs must remain private to the signed-in user.

## Decision

Require an authenticated account and an explicit confirmation sheet before a
recommendation meal is created. Write an auto-ID `meal_logs` document through a
repository with the Phase 4 schema, recommendation source, selected catalog IDs,
nutrition snapshot and Firestore server timestamp. Keep transient save state in
an auto-disposed Riverpod notifier and suppress duplicate confirmation while the
same screen is saving or already successful.

## Consequences

- Ownership and timestamp are enforced by existing Firestore rules.
- The nutrition value is an estimate copied at selection time, not medical advice.
- The action records consumption intent only; no order or payment is created.
- Reloading the detail page can allow another log because persistent history and
  duplicate policy belong to Phase 13, not this transient Phase 12 guard.
- No new collection, index, rule deployment or server function is required.
