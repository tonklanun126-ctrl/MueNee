# Phase 15: Monitoring, privacy and polish

Phase 15 adds the monitoring foundation and the final planned interaction
polish without changing recommendation, nutrition, location, catalog or meal-log
behavior.

## Privacy-first collection

Analytics and Crashlytics are independently opt-in. Both Android manifest
defaults are `false`; the app only applies an enabled state after loading the
versioned `muenee.telemetry_settings.v1` record from device-local preferences.
Opening the app, signing in, or using a protected feature is not consent.

The `/privacy-settings` screen is available to guests from Home. It explains
each collection type, supports separate switches, uses an explicit save action,
and rolls back to the last confirmed state when persistence or SDK application
fails. A corrupt local record is an error and is never interpreted as consent.

MueNee's Analytics event allowlist contains only these parameter-free events:

- `meal_flow_started`
- `budget_confirmed`
- `preferences_confirmed`
- `recommendation_meal_recorded`
- `food_scan_analysis_completed`
- `food_scan_meal_recorded`

Named router destinations provide stable screen names. Event parameters, user
properties and user IDs are deliberately absent. MueNee does not add coordinates,
addresses, budget values, dietary restrictions, nutrition, food names, image
data, email, Firebase UID or free text to Analytics events.

When crash reporting is enabled, uncaught Flutter and asynchronous errors go to
Crashlytics. Expected repository/model failures are recorded with a fixed safe
code rather than the original exception message. No custom user identifier,
food data or location is attached. Crash reports can still contain normal SDK,
device, app-version and stack-trace diagnostics, which the UI discloses.

The isolated `demo-muenee-pj` mode and test doubles always receive a no-op
telemetry service. This prevents emulator acceptance from becoming a hidden
production measurement run.

## Android integration

The project uses `firebase_analytics` and `firebase_crashlytics`. Live-config
Android builds conditionally apply Google Services and Crashlytics Gradle
plugins. Emulator builds skip those Gradle plugins so the existing explicit
`demo-muenee-pj` initialization cannot be replaced by the live native config.

The validated local `google-services.json` is required at
`android/app/google-services.json` for a live-config Android build and remains
Git-ignored. It contains mobile client configuration, never service-account
credentials. `scripts/configure_firebase.ps1` now stages both ignored build
inputs after validating the project and Android package.

## Interaction polish

- successful budget, food-preference and privacy confirmations use a light
  platform haptic;
- shared motion tokens define short press, selection and content durations;
- the privacy state transition becomes immediate when the platform requests
  reduced motion;
- all new controls retain explicit labels, 48 logical-pixel Material targets,
  scrolling, visible error/success state, and 320 x 640 at 200% text support.

No decorative looping animation, artificial delay, randomized result, health
score or unsupported personalization was added.

## Student validation plan

This is a plan, not completed user research. Recruit representative students
around the initial Silpakorn University area and ask each participant to:

1. find an eligible meal within a stated budget;
2. change the budget without losing confirmed food settings;
3. explain the price and nutrition uncertainty shown for a recommendation;
4. find the privacy page, explain both switches, and reverse a saved choice.

Record task completion, time to first useful result, wrong turns, points of
confusion and the participant's explanation in research notes outside Analytics.
Establish the baseline before setting numerical improvement targets. Do not
place participant names, emails, locations, dietary constraints or quoted
feedback in Firebase Analytics.

## Validation and live boundary

Verified locally on 2026-09-12:

- `flutter analyze --no-pub`: clean;
- all 117 Flutter tests: passed, including default opt-out, versioned local
  round-trip, corrupt-data rejection, rollback, event allowlist, guest routing,
  UI save/error states, and 320 x 640 at 200% text;
- Android 16 / API 36 isolated integration: passed enabling both choices,
  remounting to prove persistence, disabling both choices again and restoring
  the exact previous local record;
- `artifacts/phase-15-polish/privacy-settings-enabled.png`: captured on Android
  and visually inspected without clipping, overflow or a debug banner;
- live-config x86_64 debug APK: 127,853,870 bytes, APK Signature Scheme v2
  verified with one signer, SHA-256
  `A168327F2BFB23BDDD4CA09E74F3FCB3974C5AEA8204EA9B5C42C03C31C28F02`;
- packaged manifest inspection: both collection defaults are `false`, and the
  Crashlytics registrars are present.

Firestore/Storage rules and indexes were unchanged. The native integration used
the isolated demo variant and generated no application document writes.

No Analytics integration, Crashlytics dashboard, collection setting, test event
or forced crash has been changed in live `muenee-pj`. Live acceptance requires
separate approval to enable/review the Firebase integrations, opt in on a test
device, send one bounded debug validation event and non-fatal report, then verify
their arrival in Firebase Console. Do not ship a force-crash button.
