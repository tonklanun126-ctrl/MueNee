# ADR 0014: Confirmed AI food scan with ephemeral images

- Status: Accepted
- Date: 2026-09-10

## Context

Phase 14 needs to estimate one meal from a photo without turning an uncertain AI
response into a trusted health record. Images can contain private information,
Firebase AI Logic has no local emulator, and a mobile activity can be recreated
while the Android image picker is open.

## Decision

Use `image_picker` for one camera or gallery image, resize it to at most
1600 x 1600 at 85% quality, recover Android lost data, and reject unsupported
types or payloads above 10 MB. Keep the selected bytes only in application
memory. Send them to Gemini through the authenticated Firebase AI Logic client
only after the user presses Analyze; do not upload the image to Storage or add an
image URL to the meal log.

Request JSON output with an explicit schema for recognition, Thai food name,
calories, protein, carbohydrate, fat, and a portion-assumption note. Validate the
decoded response again with the existing Firestore nutrition limits. Present all
values as estimates in editable fields. Only the explicit final confirmation may
call `createFoodScanMeal`, which writes `source: food_scan` with a server
timestamp and the signed-in UID.

Use provider abstractions for the image picker, AI analysis, and meal repository
so local and emulator tests can prove the confirmation boundary without making
a billable model request.

## Consequences

- A meal image is transmitted to the configured Gemini provider for analysis,
  but MueNee does not retain it in Storage or the daily log.
- Users must be signed in before analysis because the successful workflow writes
  private owner data and Firebase Auth/App Check protect the live client.
- Cancelled picking preserves the previous state; invalid, non-food, timeout and
  service failures remain retryable without creating a meal.
- Firebase Emulator coverage can verify Auth, Firestore Rules and the confirmed
  write, but it cannot prove live Gemini provisioning, quota, App Check or model
  output. Those require a separately authorized live acceptance run.
- Model selection can be overridden with `--dart-define=FOOD_SCAN_MODEL=...`;
  operational migration to Remote Config is deferred to the monitoring/polish
  phase.
