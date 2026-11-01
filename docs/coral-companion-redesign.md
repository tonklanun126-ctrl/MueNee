# Coral Companion redesign

Date: 2026-09-27. Scope: the existing MueNee Flutter app, not an additional
product phase. `DESIGN.md` and `PROJECT_CONTEXT.md` remain the product and
phase references.

## Visual system

`lib/app/theme/app_theme.dart` defines the cream canvas, coral action/selection,
ink, warning, success, typography, and shared Material control styling.
`lib/app/theme/app_tokens.dart` defines 4/8/12/16/24/32 px spacing and field,
button, card, and hero radii. Shared section, budget-chip, status, and brand
widgets live under `lib/app/widgets/`. Motion is short and respects reduced
motion; confirmation haptics keep the existing setting.

The fork/spoon/smile brand source is `assets/brand/muenee_launcher.svg`; a 512
px PNG is supplied for previews. The Android legacy, adaptive, and monochrome
launcher icons and Android splash drawables follow the same mark. The cream
splash is intentionally static and contains no loading promise.

Prompt Regular/SemiBold/Bold and Noto Sans Thai variable fonts are bundled
under `assets/fonts/`. Their upstream source is Google Fonts, with the OFL
license text stored beside each family. Do not remove or rename those license
files when redistributing the app.

Upstream font records: [Prompt](https://github.com/google/fonts/tree/main/ofl/prompt)
and [Noto Sans Thai](https://github.com/google/fonts/tree/main/ofl/notosansthai).

## Flow and guardrails

Home's budget shortcuts open the existing Budget form with a prefilled draft;
they do not persist a selection. Location, budget, food restrictions, and
allergies still require their original confirmations before recommendation
queries. Home's “น่ากิน ใกล้คุณ” area is an honest empty/prompt state until
eligibility and catalog results are available, rather than fake restaurant
data. Recommendations and detail retain the price-source, estimation, and
allergen cautions. AI scan results remain editable and require explicit review
before a meal write. Analytics and Crashlytics remain opt-in; this refresh
does not send live requests or enable consent.

The Material theme carries the system across auth, location, profile, food
preferences, map, tracking, AI review, privacy settings, dialogs, and snackbars.
Screen-specific heroes, result cards, map fallback, and empty/error states
use the shared color, radius, typography, and action hierarchy. Main navigation
keeps icon and Thai text labels.

## Acceptance record

On 2026-09-27, `flutter analyze --no-pub` reported no issues and all 118
`flutter test --no-pub` cases passed, including 320×640/200%-text checks.
`scripts/run_coral_visual.ps1` passed all eight Android 16/API 36 visual
integration cases. Screenshots are in `artifacts/coral-companion/`:
`coral-home.png`, `coral-budget.png`, `coral-preferences.png`,
`coral-recommendations.png`, `coral-restaurant-detail.png`,
`coral-tracking.png`, `coral-ai-review.png`, and `coral-settings.png`.
The recommendation, restaurant, tracking, and AI-review imagery uses labeled
local visual fixtures; it is not evidence of live catalog, Firestore, or Gemini
service acceptance.

The normal live-config universal Android debug APK is
`artifacts/coral-companion/MueNee-Coral-Companion-1.0.1-5000-debug.apk`
(180,995,007 bytes; SHA-256
`A453772DD64704C847949A6D4F219E2A40315B9AC7FDAA3C6BE87E8DE7EEC0D7`).
`aapt` reports package `com.muenee.app`, versionCode 5000, versionName 1.0.1,
and arm64-v8a/armeabi-v7a/x86_64 native libraries. `apksigner verify` passed
with APK Signature Scheme v2. It is debug-signed, not a Play Store release.
The APK installed with `adb install -r` over the preceding versionCode 1
emulator installation without uninstall. The regular app started and remained
running at Home (`coral-live-home-5000.png`); the inspected AndroidRuntime and
Flutter error log had no crash. Physical Redmi Note 12 Pro 5G acceptance is
still pending.

During an earlier visual run, Flutter's installer automatically uninstalled
an older versionCode 4001 APK on the test AVD after a version-downgrade error;
this erased that emulator installation's local app data. It did not touch the
user's phone or the live Firebase project. The versionCode 5000 APK avoids
that downgrade path for the tested older builds. A screenshot shows layout
only; it does not prove a live Firestore write, Maps tile, Gemini analysis,
or monitoring report. Phase 11 map-key/real-tile and Phase 14/15 live-service
acceptance remain separate from this visual redesign.
