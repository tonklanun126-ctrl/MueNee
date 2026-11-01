# ADR 0002: Local food preferences before account integration

- Status: Accepted; incorporated into the Phase 8 meal flow
- Date: 2026-09-05

## Decision

Use `SharedPreferencesAsync` through a feature-owned repository to store one
versioned JSON document (`muenee.food_preferences.v1`). Riverpod owns loading
and confirmed state. A form holds unsaved edits; provider state changes only
after storage succeeds. Unknown formats fail visibly and are not reset silently.

This is device-local preference storage, not another application database.
Firestore remains the approved primary database. Cross-device/account sync,
authentication, and migration to Firestore are deferred until their own tasks.

## Consequences

- Users can reopen the app and reuse their choices without an account.
- Reinstalling or clearing application data can remove these preferences.
- Preferences are not a medical record or a guarantee of allergen-free food.
  Menu preview filtering requires declared allergen metadata; the UI instructs
  users to confirm ingredients/cross-contact with the restaurant before ordering.
- The repository can later be replaced without putting storage code in widgets.
- Plugin/platform storage adds Android build dependencies but does not change
  Flutter, Riverpod, go_router, or the approved backend.

Phase 8 reuses this persisted contract in the core meal flow. A confirmed
budget can continue to the same settings screen in meal-flow mode. That mode
requires an explicit confirmation even when the saved selection is empty, and
does not start recommendation ranking or write preferences to Firebase.

API reference: [shared_preferences](https://pub.dev/packages/shared_preferences).
