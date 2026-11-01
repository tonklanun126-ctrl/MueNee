# Phase 14: AI Food Scan

Phase 14 implements the second meal-recording path:

```text
camera or gallery image
-> explicit Analyze action
-> Firebase AI Logic structured estimate
-> editable review
-> explicit confirmation
-> owner-only meal_logs write
```

It does not implement manual meal entry, scan history, retained meal photos,
medical advice, Analytics, Crashlytics, or Phase 15 polish.

## User experience

The working “สแกน” destination is now the third bottom-navigation item. A signed-
out user is directed to the existing account flow. A signed-in user can take a
photo or choose one from the device, preview and replace it, then deliberately
start analysis.

Before analysis, the screen says that the image will be sent to the AI service
and will not be retained in the meal log. The result screen identifies nutrition
as an estimate, explains the assumed portion, and exposes editable food name,
calories, protein, carbohydrate and fat fields. Nothing is saved when an image is
selected or when analysis finishes. The final “ยืนยันและบันทึกมื้อนี้” action is
the only UI path to the write. Success links to today's Daily Tracking.

Loading, cancelled selection, invalid image, non-food, analysis failure, save
failure and success states are explicit and retryable. The screen is scrollable
and its image-source actions wrap on narrow or enlarged-text layouts.

## Image and AI contract

- `image_picker` captures or selects one image and calls `retrieveLostData()`
  after Android activity recreation.
- Input is reduced to at most 1600 x 1600 at 85% quality, limited to 10 MB, and
  restricted to JPEG, PNG, or WebP.
- Bytes stay in memory and are sent inline to Firebase AI Logic only after the
  Analyze action. Phase 14 does not write Firebase Storage.
- `firebase_ai` uses the Gemini Developer API backend and defaults to
  `gemini-3.7-flash`; `FOOD_SCAN_MODEL` can override the model at build time.
- The request uses `application/json` plus a response schema. Decoding rejects a
  non-food response, missing/wrong field types, fractional calories and values
  outside the existing `NutritionEstimate`/Firestore ranges.
- The request has a 45-second client timeout and user-facing errors do not expose
  SDK details, credentials or tokens.

## Persistence contract

`FirestoreMealLogRepository.createFoodScanMeal` accepts only a non-empty owner,
a trimmed food name up to 160 characters, and a validated nutrition estimate.
It writes `schemaVersion: 1`, the authenticated `userId`, `source: food_scan`,
the confirmed fields and a Firestore server timestamp. It intentionally omits
`imageUrl`, `menuId`, and `restaurantId`.

The existing Phase 4 meal rules and composite index already support this shape,
so no rules/index change or live deployment is required.

See [ADR 0014](architecture/adr/0014-confirmed-ai-food-scan.md).

## Validation

Verified locally on 2026-09-10 and rechecked on 2026-09-11:

- `flutter analyze --no-pub`: clean;
- all 109 Flutter tests: passed, including structured-output rejection, signed-
  out protection, no write before confirmation, edited confirmation, retry, app
  navigation, and 320 x 640 at 200% text;
- all five Firestore/Storage Rules Emulator groups: passed;
- Android 16 / API 36 Auth + Firestore Emulator flow: passed using a fake image
  and deterministic fake analyzer, proving zero documents before confirmation
  and one owner document after confirmation with `source: food_scan`, edited
  620 kcal data, no `imageUrl`, and cleanup;
- review and success screenshots captured under
  `artifacts/phase-14-food-scan/` and visually inspected without overflow.
- live-config x86_64 debug APK: 178,979,963 bytes, APK Signature Scheme v2
  verified, SHA-256
  `763B86E647DF8A561C4739C327BEBD062543AFD5780B0362A28BCC6EC40EBB4A`.

The Android build includes the real `firebase_ai` and `image_picker` plugins, but
the test deliberately replaces model output to remain deterministic and
non-billable. No live `muenee-pj` model request, document write, API enablement,
rule/index deployment, or Storage upload was performed.

## Live acceptance boundary

Phase 14 implementation is complete, but live AI acceptance remains pending.
Firebase AI Logic must be provisioned for the Gemini Developer API in
`muenee-pj`, billing/quota must be reviewed, and the current App Check posture
must be accepted. Then a real food photo must be analyzed on Android and the
estimate reviewed before any separately authorized live confirmation/write.
