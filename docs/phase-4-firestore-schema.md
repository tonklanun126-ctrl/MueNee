# Phase 4: Firestore models and schema

Phase 4 implements development-priority item 5. It defines version 1 of the
application documents, the queries those documents must support, their indexes,
and client access rules. It does not add real restaurant/menu seed data or
silently copy device-local profile settings into an account.

## Query contract (designed first)

| Use case | Query | Access |
| --- | --- | --- |
| Current profile | `users/{auth.uid}` direct get | Owner only |
| Active restaurants | `restaurants where isActive == true orderBy name` | Public read |
| Active menu for one restaurant | `menu_items where restaurantId == id and isActive == true orderBy name` | Public read |
| Active recommendation candidates | `menu_items where isActive == true`, bounded to 100 | Public read |
| Recent meals | `meal_logs where userId == auth.uid orderBy createdAt desc`, with a bounded limit | Owner only |

Catalog queries must include `isActive == true`; an unbounded collection read is
rejected by rules. Meal queries must include the signed-in user's exact UID.
`firestore.indexes.json` contains the three composite indexes required by the
restaurant, menu, and meal-log queries. Live Phase 5 client verification exposed
that the active-restaurant query also needs a composite index for `isActive`
plus ordered `name`; the earlier statement that automatic single-field indexes
were sufficient was incorrect and has been corrected.
The Phase 9 bounded active-menu candidate query needs only the automatic
single-field `isActive` index and is sorted deterministically on the client.

## Common conventions

- Collection names are `users`, `restaurants`, `menu_items`, and `meal_logs`.
- Every document has `schemaVersion: 1`.
- Times are Firestore timestamps and Dart models normalize them to UTC.
- Document IDs are supplied separately to model decoding and are not duplicated
  inside the document.
- Optional strings are omitted rather than stored as empty strings.
- Client-owned create timestamps use `serverTimestamp()` so rules can require
  equality with `request.time`.
- Unknown schema versions and malformed enum/type values fail decoding; they are
  not silently replaced with defaults.

## `users/{uid}`

Fields: `schemaVersion`, optional `displayName`, `profile`, `preferences`,
optional `targetCalories`, `createdAt`, and `updatedAt`.

`profile` reuses the local version 1 contract: age, height in centimetres,
weight in kilograms, and activity level. `preferences` reuses the existing hard
restrictions, dislikes, allergy list, and hide-disliked switch. This preserves
the conservative dietary semantics already approved in Phase 1.

Only the matching authenticated UID can get, create, update, or delete this
document. Listing all users is denied. Rules enforce field allowlists, value
ranges, immutable `createdAt`, and server-authored create/update timestamps.

The model is ready for a future explicit sync flow, but Phase 4 does not choose
whether local or remote data wins. Existing settings therefore remain unchanged
on this device.

## `restaurants/{restaurantId}`

Fields: `schemaVersion`, `name`, `googlePlaceId`, `location` (`GeoPoint`),
`address`, optional `rating`, optional `imageUrl`, `verificationStatus`,
`isActive`, `createdAt`, and `updatedAt`.

Verification values are `unverified`, `pending`, and `verified`. Active records
are public read-only catalog data. All client writes are denied; Phase 5 seed
tooling must run in a trusted administrative environment.

## `menu_items/{menuItemId}`

Fields: `schemaVersion`, `restaurantId`, `name`, `price`, `nutrition`, `tags`,
dietary evidence, `isActive`, optional `imageUrl`, `createdAt`, and `updatedAt`.

`price` contains integer baht `amount`, `confidence`, and optional `source` and
`verifiedAt`. Confidence values remain `verified`, `estimated`, and
`unverified`. `nutrition` contains calories plus protein, carbs, and fat grams.
Dietary evidence stores ingredient/allergen enums together with
`ingredientsKnown`, `allergensKnown`, `vegetarianConfirmed`, and
`halalConfirmed`; absence of evidence is never treated as confirmation.

Active records are public read-only catalog data. All client writes are denied.

## `meal_logs/{mealLogId}`

Fields: `schemaVersion`, `userId`, `source`, `foodName`, `nutrition`, optional
`menuId`, `restaurantId`, and `imageUrl`, plus `createdAt`.

Source values are `recommendation`, `food_scan`, and `manual`. Only the matching
authenticated user can query, create, update, or delete a meal. Ownership and
`createdAt` cannot be changed during an update. Phase 4 defines this contract but
does not add Daily Tracking UI or write meal logs.

## Validation

Run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/check_flutter.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/test_firebase_rules.ps1
```

Model tests cover round-trip serialization, timestamps, enum mappings, local
profile/preference compatibility, and malformed data. Emulator tests cover
public active catalog reads, denied inactive/unbounded reads, owner-only user
documents and meal logs, schema validation, denied catalog writes, and the
unchanged deny-all Storage policy.

The checked-in rules and indexes must pass emulator tests before deployment.
Deploying them to `muenee-pj` is a separate live administrative action through
the existing location-guarded `scripts/deploy_firestore.ps1`.

Verified 2026-09-06: Flutter analyze passed, all 51 Flutter tests passed, and
all five Firestore/Storage Emulator rules groups passed. Before deployment, a
read-only live probe returned HTTP 403 `PERMISSION_DENIED` and attempted no
write, confirming the Phase 2 deny-all baseline. After the user explicitly
approved the production change, `scripts/deploy_firestore.ps1` verified project
`muenee-pj`, Firestore Native `(default)`, and location `asia-southeast1`; the
Firebase CLI compiled and released `firestore.rules` and deployed the two
indexes then defined. Phase 5 live-client verification later added the missing
restaurant index described above. No Firestore document was created or changed
during the Phase 4 deployment. Phase 4 acceptance is complete.
