# Phase 12: Meal selection

Phase 12 completes the “Select Meal” step after a Top 3 recommendation. The user
explicitly asked to implement it before finishing Phase 11's pending live-map
acceptance. It does not implement Phase 13 Daily Tracking.

## User flow

The restaurant detail page keeps a SafeArea-aware action visible at the bottom.

- Signed-out users see “เข้าสู่ระบบเพื่อบันทึกมื้อ” and continue to the existing
  account route. Returning Back preserves the selected recommendation snapshot.
- Signed-in users tap “เลือกเมนูนี้เป็นมื้อนี้” and review a confirmation sheet.
- The sheet names the menu and restaurant, shows estimated calories, and says
  clearly that this records a meal but does not order food or take payment.
- Confirming shows an in-progress state, then a persistent success state. A
  failed write shows readable feedback and can be retried.
- A successful selection is disabled for that detail-screen lifetime, preventing
  accidental duplicate taps. Phase 13 now provides the read-only daily list;
  editing and deletion are still outside this success state.

The action remains usable at 320 x 640 with 200% text scaling: its text can wrap,
the bottom area respects device insets, and the scrolling content has clearance.

## Firestore write contract

`FirestoreMealLogRepository` creates an auto-ID document in `meal_logs` with:

- `schemaVersion: 1`
- authenticated `userId`
- `source: recommendation`
- `foodName`, `menuId`, and `restaurantId` from the selected catalog snapshot
- the catalog `nutrition` estimate and optional menu/restaurant image
- `createdAt: FieldValue.serverTimestamp()`

An empty UID is refused before a write. Existing Phase 4 rules validate the
allowlist, nutrition ranges, ownership, and server timestamp. Catalog values are
snapshotted deliberately so future catalog edits do not rewrite a recorded meal.
This phase does not add or deploy rules/indexes and does not write live test data.

## Architecture

UI state is managed by an auto-disposed Riverpod notifier. Business persistence
is behind `MealLogRepository`; production uses Firestore and widget tests replace
it with a fake. Firebase Auth supplies the UID through the existing `Account`
stream. See [ADR 0012](architecture/adr/0012-confirmed-recommendation-meal-log.md).

## Validation

Run local checks:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/check_flutter.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/test_firebase_rules.ps1
```

With an Android emulator already booted, run the isolated native acceptance:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/test_firebase_android.ps1 -MealSelection -DeviceId emulator-5554
```

The guarded native command starts only Auth and Firestore Emulators for
`demo-muenee-pj`. It creates a unique emulator account, selects through the real
screen/repository, reads the resulting server document, verifies all Phase 12
fields and timestamp, then removes its account and meal log.

Verified 2026-09-10: analyzer clean; all 94 Flutter tests passed;
all five Firestore/Storage Rules groups passed, including a valid recommendation
meal plus denied anonymous/forged writes; and the Android 16 / API 36 native
Auth-to-Firestore selection test passed. The live-config x86_64 debug APK built
successfully (116,894,975 bytes), and APK Signature Scheme v2 verified. Its
SHA-256 is `AE3D6AAB0F201BA56DA3CF4C1F55930844E1A8241F9561C46E2301BF9EFEDE89`.
The first live-config build attempt exhausted Windows worker threads while the
emulator was still open; closing the completed emulator run and rebuilding passed.
No live `muenee-pj` data changed.

## Remaining boundary

Phase 11 still needs a restricted Maps SDK for Android key and visual confirmation
of real tiles/markers. Phase 13 now provides read-only daily history. Meal
edit/delete UI, AI Food Scan, analytics and monitoring remain unstarted.
