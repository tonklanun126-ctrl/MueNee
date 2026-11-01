# Phase 5: Restaurant and menu seed data

Phase 5 implements development-priority item 6. It provides a small,
version-controlled catalog for the initial area around Silpakorn University,
Sanam Chandra Campus. It does not implement device location, recommendation,
maps UI, tracking, or AI features.

## Dataset

- `data/restaurants.json`: 10 real restaurant records with Google Place IDs,
  coordinates, addresses, ratings, source links, and check timestamps.
- `data/menu_items.json`: 30 menu records (three per restaurant), with integer
  baht prices, generic portion-level nutrition estimates, tags, and conservative
  dietary evidence.
- Restaurant provenance stays in version control and is intentionally stripped
  by the seed transformer because it is not in the Phase 4 Firestore schema.
- Menu price source and verification time are stored in Firestore because they
  are part of the Phase 4 price contract.

All nutrition values are estimates, not laboratory measurements or medical
advice. `ingredientsKnown` and `allergensKnown` remain `false` unless the full
recipe and cross-contact evidence are available. No initial menu is marked
halal or vegetarian merely because no conflicting ingredient was found.

Price confidence follows the approved 30-day UX contract. A `verified` price
must have an HTTPS source and a current verification timestamp. Values gathered
from review text or incomplete evidence remain `unverified`.

## Validation

Run the non-network checks:

```powershell
npm run validate:seed
npm run test:seed
npm run seed:dry-run
```

The validator checks schema versions, unique IDs and Place IDs, foreign keys,
10-20 restaurants, 3-5 menus per restaurant, the 3 km MVP boundary, enums,
URLs, timestamps, nutrition ranges, and price-evidence rules.

Run the isolated Firestore write test:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/test_seed_firestore.ps1
```

The test starts a demo-project Firestore Emulator, creates all 40 documents,
reads them back, then repeats the seed and requires the create-only guard to
refuse every overwrite. The seed tool never deletes documents.

## Live seed guard

Live seeding is a separate production mutation. Use only after the user confirms
the exact project at action time and the operator has Application Default
Credentials with Firestore write access:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/seed_firestore.ps1 `
  -ProjectId muenee-pj -ConfirmProject muenee-pj -PreflightOnly

# Run only after a separate action-time confirmation:
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/seed_firestore.ps1 `
  -ProjectId muenee-pj -ConfirmProject muenee-pj

# Read-only field-by-field verification after seeding:
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/seed_firestore.ps1 `
  -ProjectId muenee-pj -ConfirmProject muenee-pj -VerifyOnly
```

The wrapper verifies Firestore Native `(default)` in `asia-southeast1` before
starting. The Node tool validates the dataset, refuses emulator leakage, checks
all target paths, and aborts without a write if any target document exists. One
atomic batch creates the catalog, then every target path is read back. There is
no update or delete mode.

## Evidence recorded 2026-09-06

- Seed validation: 10 restaurants, 30 menus, 15 verified prices, and 15
  unverified prices.
- Three Node validator tests passed.
- Dry-run passed without connecting to Firestore.
- Firestore Emulator created and read back all 40 documents.
- A repeated Emulator seed was refused before any overwrite.
- Flutter analyze and all 51 Flutter tests passed.
- All five Firestore/Storage Emulator rules groups passed unchanged.
- Google Cloud CLI 583.0.0 and user Application Default Credentials were set up
  without creating a service-account key.
- The guarded production seed verified `muenee-pj`, Firestore Native `(default)`
  in `asia-southeast1`, then created and read back 40 documents. No document was
  updated or deleted.
- Read-only field comparison confirmed that all 40 live documents match the
  version-controlled seed exactly.
- Initial public-client verification exposed a missing restaurant composite
  index (`isActive`, `name`) in the Phase 4 index plan. The checked-in index and
  Phase 4 documentation were corrected before final client verification.
- After the deployed index reached `READY`, unauthenticated live client queries
  read exactly 10 active restaurants and 30 active menus from `muenee-pj`.
