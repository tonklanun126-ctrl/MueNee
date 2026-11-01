# Food settings and price confidence UX

## Entry points

- Home: `ตั้งค่าอาหารที่กิน` opens `/food-settings`.
- Home: `ดูตัวอย่างเมนูและสถานะราคา` opens `/food-preview`.
- The preview links back to settings and updates after saved changes.

The existing foundation placeholder remains. This addition is limited to the
user-requested UX and a local preview, not the full recommendation engine.

## Settings

| Group | Options / behavior |
| --- | --- |
| Hard exclusions | No pork, no beef, vegetarian, halal only; combine with AND |
| Vegetarian | Excludes meat/fish/seafood; eggs and dairy are allowed |
| Halal | Requires explicit confirmation, not merely no pork |
| Allergies | Peanut, tree nuts, milk, egg, soy, wheat, fish, shellfish, sesame |
| Dislikes | Pork, beef, chicken, fish, shellfish, egg, milk, mushroom, coriander, offal |
| Hide dislikes | Off: stable ordering with disliked eligible menus last. On: exclude matches and incomplete ingredient data |

Allergy and exclusion checks happen before dislike ordering. Unknown allergen
metadata is excluded when any allergy is selected. Declared allergen data must
include known possible cross-contact. No result is labeled allergen-free.
An empty result never silently relaxes a user's restrictions.

The form has loading/retry states, a save button, failure feedback, unsaved-edit
confirmation on back, and a reset-selection action that requires saving.
It stores enum identifiers in versioned JSON, not translated display labels.
Saved state survives repository/provider recreation. No cross-device sync exists.

## Prices

| Visible status | Rule |
| --- | --- |
| ยืนยันแล้ว | Marked verified, nonempty source, verification timestamp not in the future and at most 30 days old |
| ราคาโดยประมาณ | Explicit estimate, without claiming a verified selling price |
| รอตรวจสอบ | Unverified, or verification is missing, invalid, or older than 30 days |

The 30-day threshold is a local product policy, not an externally established
standard. Verified prices use the exact amount display; the others say
`ประมาณ`. A status button opens evidence, last check date, status definitions,
and an explanation that actual prices may change.

The six preview dishes have fictional metadata. Their relative dates are
generated for demonstration, not refreshed verification of real prices.
Production verified status must eventually come from a trusted workflow.

## Implementation

- `features/profile`: immutable food preferences and user profile models, local
  repositories, Riverpod providers, and settings forms.
- `features/recommendation`: deterministic preference filter and preview screen.
- `features/restaurants`: menu/price models, fictional fixtures, price-status UI.
- `app/router/app_router.dart`: three child routes.
- `pubspec.yaml` / lockfile: `shared_preferences`; its platform test interface is
  a dev dependency for testing persisted serialization across new containers.

## Validation

- `flutter analyze --no-pub`: passed, no issues found.
- `flutter test --no-pub --concurrency=1`: passed, 25 tests. Covers persistence
  across new providers, corrupt stored data, failed saves and retry, hard and
  soft filtering, unknown metadata, price expiry, navigation, unsaved edits,
  evidence details, and a 360 x 640 screen with 1.5x text scale.
- Android debug build: passed with direct Gradle `assembleDebug` after the
  original Flutter wrapper attempt exhausted native memory. The successful
  run used one Gradle worker and JDK `_JAVA_OPTIONS` capped at 768 MiB heap /
  384 MiB metaspace, and reused the existing Gradle caches. CMake 3.22.1 was
  installed automatically. No repository Gradle or system pagefile settings
  were changed.
- The build also emitted existing Android Gradle/Kotlin deprecation warnings and
  an SDK XML tooling-version warning; none prevented packaging.

For the constrained local Windows environment, first apply the environment
setup in [Phase 1 validation](phase-1-validation.md), then use this per-shell
override and direct Gradle command. It preserves `android/gradle.properties`
and system pagefile settings:

```powershell
$env:_JAVA_OPTIONS = '-Xmx768m -XX:MaxMetaspaceSize=384m -XX:ReservedCodeCacheSize=128m -XX:ActiveProcessorCount=2'
$env:GRADLE_OPTS = '-Dorg.gradle.daemon=false'
Push-Location android
try { .\gradlew.bat --no-daemon --max-workers=1 assembleDebug }
finally { Pop-Location }
```

The resulting APK is available at
`build/app/outputs/flutter-apk/app-debug.apk` (also mirrored at
`build/app/outputs/apk/debug/app-debug.apk`).

- APK size: 164,395,389 bytes.
- `aapt dump badging`: `com.muenee.app`, version `1.0.0+1`, minimum SDK 24,
  target SDK 36, and `arm64-v8a`, `armeabi-v7a`, `x86_64` native code.
- `apksigner verify --verbose`: passed with APK Signature Scheme v2 and one
  signer.
- The latest profile-settings, visual-theme, and status-bar source rebuild
  produced SHA-256
  `e03697f5c498d53d04ba8d548e89011eb1fba39a981628ab74873cb0e59882eb`.
- API 36 emulator smoke testing confirmed saved restrictions, allergy,
  dislike, hide-disliked behavior, filtered preview, and price-evidence sheet
  after a force-stop and relaunch. See
  [Phase 1 validation](phase-1-validation.md#emulator-smoke-test-2026-09-05).

## Remaining boundaries

No real restaurant data, production verification, account/Firebase sync, or
complete recommendation ranking has been added. Profile inputs are stored
locally but are not yet used for calorie or nutrition calculations. Supported
food choices are currently predefined; free-text allergy mapping is not
implemented.

See [profile settings](profile-settings.md) for the profile fields and design
baseline.
