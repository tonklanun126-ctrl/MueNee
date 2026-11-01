# MueNee

MueNee helps users discover nearby meals based on budget, preferences,
nutrition, and distance.

The MVP is Android-first and initially targets the area around Silpakorn
University, Nakhon Pathom, Thailand.

See [PROJECT_CONTEXT.md](PROJECT_CONTEXT.md) for the product scope and
[AGENTS.md](AGENTS.md) for repository development rules.

## Phase 1 foundation

The Android scaffold uses Riverpod, `go_router`, and Material 3. Its current
Coral Companion theme uses a cream canvas, coral actions, and restrained
semantic accents.
The `/` route is the Coral Companion home, leading through location, a
confirmed meal budget, food preferences, and recommendations. It also links to
local profile/food settings and a clearly labeled fictional menu preview.
The Phase 2 Firebase initialization layer is now available. The existing profile
and food settings still store data only on this device.

See [food settings and price UX](docs/food-settings-and-price-ux.md) for the new
options, filtering rules, local persistence, and implementation boundaries.
See [profile settings](docs/profile-settings.md) for the requested body
measurements, activity field, and current design baseline.
See [MueNee design direction](DESIGN.md) for the palette and component rules.
See [Coral Companion redesign](docs/coral-companion-redesign.md) for the current
brand system, icon/font sources, visual QA, and acceptance boundaries.

## Phase 2 Firebase connection

Firebase project: `muenee-pj`; registered Android package: `com.muenee.app`.
The live Firestore `(default)` database is provisioned in Singapore
(`asia-southeast1`) with delete protection. The reviewed Phase 4 owner/catalog
rules and required indexes are deployed.
See [Firebase setup and validation](docs/phase-2-firebase.md) for configuration,
startup/retry behavior, App Check, local emulators, and verification status.
Live builds require the ignored `config/firebase.local.json`. Use
`--dart-define=FIREBASE_MODE=emulator` for an isolated local demo project.
Live Firestore rules must be deployed through `scripts/deploy_firestore.ps1`,
which refuses a database outside Singapore (`asia-southeast1`).
Phase 3 adds an optional account screen with Email/Password authentication.
See [authentication status](docs/phase-3-auth.md) for the completed Phase 3
acceptance evidence.

## Phase 4 Firestore schema

Versioned models and owner-aware Firestore rules now define `users`,
`restaurants`, `menu_items`, and `meal_logs`. Active catalog records are public
read-only data; profiles and meal logs are private to their signed-in owner.
See [Firestore schema](docs/phase-4-firestore-schema.md) for fields, query
contracts, indexes, security boundaries, and validation. Phase 4 does not seed
real restaurants or migrate device-local settings automatically.

## Phase 5 catalog seed

The version-controlled initial catalog contains 10 real restaurants and 30
menus for the Sanam Chandra area. Validation, dry-run, and create-only Firestore
Emulator coverage are available. After explicit confirmation, all 40 documents
were created and verified in `muenee-pj`; no existing document was updated or
deleted. See [seed data](docs/phase-5-seed-data.md) for data confidence rules,
commands, and acceptance evidence.

## Phase 6 current location

The home flow now starts with a user-initiated current-location screen powered
by `geolocator`. It supports approximate or precise foreground permission,
clear recovery for disabled services and permission denial, and keeps the
current fix only in app memory. It does not request background location or send
coordinates to Firebase. See [location behavior](docs/phase-6-location.md) for
the privacy boundary, UI states, and validation.

## Phase 7 meal budget

The validated, session-only meal-budget model and Riverpod state are available.
They accept whole-baht input, Thai digits, and valid thousands separators
without overwriting a confirmed value after invalid input. The `/budget` screen
now provides presets, custom input, inline errors, confirmation, and unsaved-edit
protection. Open it from the home wallet action or after a ready location. See
[budget core](docs/phase-7-budget.md).

## Phase 8 food preferences

The confirmed-budget screen now continues into food settings for the current
meal. Existing device-local restrictions, allergies, dislikes, and the optional
hide-disliked behavior are reused without migration. The user explicitly
confirms even an empty saved selection, and changed settings are persisted
before confirmation. Recommendation ranking remains outside this phase. See
[Phase 8 food preferences](docs/phase-8-food-preferences.md).

## Phase 9 recommendations

The meal flow now returns up to three deterministic recommendations from the
active Firestore catalog. Budget and food safety are hard filters; disliked
eligible menus stay behind other choices. Distance, affordability, current price
confidence, and preference state determine stable ordering. Nutrition is shown
as an estimate but is not scored without a validated target. See
[Phase 9 recommendations](docs/phase-9-recommendations.md).

## Phases 10–12: detail, map and meal selection

Recommendation cards open a restaurant/menu detail page with honest price,
nutrition and dietary evidence. Its nested Google Maps page is implemented but
Phase 11 still needs a restricted Android Maps key and real-tile acceptance.
Phase 12 adds an authenticated, confirmed “record this meal” action that writes
an owner-only recommendation meal log; it does not place or pay for an order.
See [restaurant detail](docs/phase-10-restaurant-detail.md),
[Google Maps](docs/phase-11-google-maps.md), and
[meal selection](docs/phase-12-meal-selection.md).

## Phase 13 daily tracking

Signed-in users can open “บันทึก” to review one day of private meal logs, browse
earlier dates, refresh server data, and see neutral approximate nutrition totals.
The working “มื้อนี้”, “บันทึก”, and “สแกน” destinations are shown. See
[Daily Tracking](docs/phase-13-daily-tracking.md).

## Phase 14 AI Food Scan

Signed-in users can take or select one meal photo, explicitly send it through
Firebase AI Logic for a structured nutrition estimate, edit every result, and
confirm before an owner-only `food_scan` meal is created. Images remain
ephemeral and are not retained in Storage or the daily log. Local and Firebase
Emulator acceptance is complete; provisioning and a real Gemini request in
`muenee-pj` remain a separate live acceptance boundary. See
[AI Food Scan](docs/phase-14-ai-food-scan.md).

## Phase 15 monitoring and polish

Firebase Analytics and Crashlytics are integrated behind two independent,
device-local opt-in choices. Both collection types are disabled by default.
MueNee logs only named screens and a small parameter-free event allowlist; it
does not add location, budget, dietary, nutrition, food, image, email or user-ID
values. The Home privacy entry opens `/privacy-settings`, where either choice
can be reviewed and reversed. See
[monitoring, privacy and polish](docs/phase-15-monitoring-and-polish.md).

## Development

Use Flutter 3.47.2 (Dart 3.13.2), JDK 17, Android SDK platform/build-tools 36,
and NDK 28.2.13676358. Gradle is provided by the Android wrapper.

From this repository directory, with Flutter and Java on `PATH` and the Android
SDK configured:

```powershell
flutter pub get
flutter analyze
flutter test
flutter build apk --debug --dart-define-from-file=config/firebase.local.json
```

Crashlytics live-config builds also require the validated, Git-ignored Firebase
Android client file at `android/app/google-services.json`.

The APK is written to `build/app/outputs/flutter-apk/app-debug.apk`.
To launch on a connected Android device or emulator, run
`flutter run --dart-define-from-file=config/firebase.local.json`, or choose the
emulator mode documented above. A missing live config shows a startup error.

This checkout also has local tools in the sibling `../.tooling` directory.
See [Phase 1 validation](docs/phase-1-validation.md) for its Windows environment,
memory-conscious build command, APK checks, and API 36 emulator smoke results.
