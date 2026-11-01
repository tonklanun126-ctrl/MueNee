# Phase 1 foundation validation

This is the historical foundation-only build record. Later food-settings and
profile-settings work rebuilds the APK at the same output path; see
[food settings and price UX](food-settings-and-price-ux.md) and
[profile settings](profile-settings.md) for current behavior.

## Scope

Android Flutter scaffold, Riverpod application scope, `go_router`, Material 3
theme, and the recommendation placeholder at `/`. Phase 2 is not started.
The feature-based architecture is recorded in
[ADR 0001](architecture/adr/0001-feature-based-flutter-architecture.md).

## Toolchain

Validated checkout: `D:\Project\MauNeePJ\MueNee`.
Local SDKs and caches live outside the repository in `../.tooling`.

| Component | Version |
| --- | --- |
| Flutter | 3.47.2 stable |
| Dart | 3.13.2 |
| Java | Microsoft OpenJDK 17.0.20.1 |
| Android platform / build-tools | 36 / 36.0.0 |
| Android NDK | 28.2.13676358 (r28c) |
| Gradle wrapper | 9.3.1 |
| Android Gradle plugin | 9.1.0 |
| Kotlin Gradle plugin | 2.4.0 |

## Local Windows commands

Run in PowerShell from the repository directory. These environment variables
apply only to the current shell; they reuse this checkout's existing tools.
On another machine, use its installed SDK paths instead. The local `bin`
directory contains this machine's Git wrapper and is not a portable dependency.

```powershell
$tooling = (Resolve-Path ..\.tooling).Path
$env:JAVA_HOME = Join-Path $tooling 'jdk\jdk-17.0.20.1+1'
$env:ANDROID_HOME = Join-Path $tooling 'android-sdk'
$env:ANDROID_SDK_ROOT = $env:ANDROID_HOME
$env:ANDROID_USER_HOME = Join-Path $tooling 'android-user-home'
$env:GRADLE_USER_HOME = Join-Path $tooling 'gradle-home'
$env:PUB_CACHE = Join-Path $tooling 'pub-cache'
$env:LOCALAPPDATA = Join-Path $tooling 'localappdata'
$env:PATH = "$tooling\bin;$tooling\flutter\bin;$env:JAVA_HOME\bin;$env:PATH"

flutter pub get
flutter analyze --no-pub
flutter test --no-pub

# Reuse the repository's 2 GiB heap and two-worker limit.
# Compile Kotlin in the Gradle process and stop Gradle after the build.
$env:GRADLE_OPTS = '-Dorg.gradle.project.kotlin.compiler.execution.strategy=in-process -Dorg.gradle.daemon=false'
flutter build apk --debug --no-pub
```

`android/local.properties` holds local Flutter/Android SDK paths and stays
ignored by Git. Normal Flutter commands may also write tool state under the
Windows user profile; a restricted runner must permit those writes.

## Recovery and results (2026-09-05)

- The previous NDK install had only `.installer` at its destination. Resuming
  SDK Manager installation completed successfully; `source.properties`,
  `package.xml`, and the Windows LLVM compiler are now present.
- Previous JVM/Kotlin logs recorded native allocation failure and Windows
  error 1455 (pagefile too small). The existing Gradle memory settings were
  preserved. No system pagefile settings were changed.
- `flutter analyze --no-pub`: passed, no issues found.
- `flutter test --no-pub`: passed, one placeholder widget test.
- `flutter build apk --debug --no-pub` with the `GRADLE_OPTS` above: passed
  (exit code 0; Gradle reported 280.6 seconds).
- APK: `build/app/outputs/flutter-apk/app-debug.apk`, 162,012,899 bytes.
- `aapt dump badging`: package `com.muenee.app`, version `1.0.0+1`, label
  `MueNee`, launch activity `com.muenee.app.MainActivity`, minimum SDK 24,
  target SDK 36; includes `arm64-v8a`, `armeabi-v7a`, and `x86_64`.
- `apksigner verify --verbose`: passed (APK Signature Scheme v2, one signer).
- SHA-256: `27c18a71913dc93e9df83f98fead0e8246cafb430ead552518afe77f578fe0a9`.
- The build emitted an SDK XML v3/v4 tooling warning, but completed successfully.

The later food-settings build used the same output path and was validated as
follows:

- Direct `android\\gradlew.bat --no-daemon --max-workers=1 assembleDebug`:
  passed in 2m 48s after CMake 3.22.1 installation.
- APK size: 202,146,844 bytes; SHA-256:
  `a416a1805953438919b1a584f6e6f3269539cd38c7b24d05491c8e29d34f20bf`.
- `aapt dump badging` and `apksigner verify --verbose`: passed. The artifact
  contains the food-settings UI and `shared_preferences` Android plugin.

The Phase 1 analyze, widget-test, and debug APK build checks are complete.
NDK/build recovery required no repository Gradle configuration edits; the later
food-settings and profile-settings source changes are documented separately.

The profile-settings source, Phase 1 visual foundation, and dark status-bar
icons were rebuilt after those changes with the same memory-conscious direct
Gradle command:

- `android\\gradlew.bat --no-daemon --max-workers=1 assembleDebug`: passed;
  Gradle reported `BUILD SUCCESSFUL`.
- `flutter analyze --no-pub`: passed, no issues found.
- `flutter test --no-pub --concurrency=1`: passed, 25 tests.
- APK: `build/app/outputs/flutter-apk/app-debug.apk`, 164,395,389 bytes.
- `aapt dump badging`: `com.muenee.app`, version `1.0.0+1`, minimum SDK 24,
  target SDK 36; includes `arm64-v8a`, `armeabi-v7a`, and `x86_64`.
- `apksigner verify --verbose`: passed (APK Signature Scheme v2, one signer).
- SHA-256: `e03697f5c498d53d04ba8d548e89011eb1fba39a981628ab74873cb0e59882eb`.

The current Material 3 theme follows the Phase 1 MueNee visual contract in
[`DESIGN.md`](../DESIGN.md): warm white surfaces with coral-red primary actions,
orange secondary accents, and yellow highlights. Green is reserved for semantic
success and verified-price states.

## Emulator smoke test (2026-09-05)

The final source was also validated on an Android 16 / API 36 Google APIs
x86_64 emulator:

- Android Emulator 37.1.11 and the API 36 system image were installed under
  the sibling `../.tooling/android-sdk` directory.
- WHPX hardware acceleration was available. The successful AVD used a Nexus 4
  768x1280 profile with `-lowram`, 1,536 MiB RAM, two CPU cores, software GPU,
  no audio, and no window. No pagefile or repository Gradle settings changed.
- A 1,024 MiB attempt could render the app but caused Android System UI and app
  ANR dialogs. Raising only the test AVD to 1,536 MiB resolved the ANRs.
- The x86_64-only smoke-test APK was installed successfully from
  `build/app/outputs/flutter-apk/app-x86_64-debug.apk`: 77,118,059 bytes,
  SHA-256 `876d3246089e87fcd7eb2a2df82029836b1aab767db57201702db769df803e72`.
- Home rendered with readable dark status-bar icons on the warm canvas.
- Profile values age 30, height 170 cm, weight 65 kg, and moderate activity
  survived a force-stop and relaunch.
- Food settings no pork, halal only, peanut allergy, mushroom dislike, and hide
  disliked menus survived a force-stop and relaunch.
- The preview applied those settings and displayed 1 of 6 fictional menus.
- The estimated-price sheet displayed its source, missing verification date,
  all three confidence definitions, and fictional-data warning.
- Final logcat review found no MueNee ANR, fatal exception, Flutter error, or
  unhandled exception during the 1,536 MiB run.

Screenshots are under [`artifacts/phase-1-device-smoke`](../artifacts/phase-1-device-smoke),
including [Home](../artifacts/phase-1-device-smoke/home-1536.png),
[reopened profile](../artifacts/phase-1-device-smoke/profile-reopened.png),
[filtered preview](../artifacts/phase-1-device-smoke/food-preview.png), and
[price evidence](../artifacts/phase-1-device-smoke/price-sheet.png).

Phase 1 is complete. A physical handset has not been used, but build, automated
tests, installation, launch, interaction, persistence, and visual smoke checks
all passed on the API 36 emulator.
