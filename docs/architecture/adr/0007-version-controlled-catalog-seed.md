# ADR 0007: Version-controlled, create-only catalog seed

Date: 2026-09-06. Status: accepted for Phase 5.

## Decision

Keep the initial real restaurant and menu catalog in reviewed JSON source files
and load it with a trusted Firebase Admin tool. Validate the full dataset before
any connection. Production writes require explicit project confirmation and a
location/type guard, and are create-only in one atomic batch.

Treat nutrition as a generic estimate and dietary evidence as incomplete unless
the full recipe and allergen/cross-contact information are known. Treat prices
as verified only when source and recent verification evidence satisfy the
existing 30-day contract.

## Consequences

- Catalog changes are reviewable and reproducible instead of existing only in
  the Firebase console.
- Re-running a seed cannot silently replace manually corrected production data;
  it stops before writing when any target path already exists.
- Existing-record updates require a future, separately reviewed migration tool.
- Restaurant source metadata stays in Git while Firestore continues to obey the
  deployed Phase 4 schema.
- Unknown ingredients/allergens remain conservative under user food filters.

See `docs/phase-5-seed-data.md` for commands, data policy, and validation.

