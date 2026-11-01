# Phase 2: Firebase connection

The authorized scope is development-priority item 3 in `PROJECT_CONTEXT.md`.
Authentication is item 4 and remains a separate implementation step.

## Firebase project and app

- Project: `muenee-pj` (provided by the user).
- Project number: `229088552669` (verified in Firebase Console).
- Android package: `com.muenee.app`.
- Android app nickname: `MueNee Android`.
- Android Firebase App ID: `1:229088552669:android:a2dc1af6116c797030dd34`.
- The Android registration was created and verified in Console on 2026-09-06.
- No service-account key, Firebase login token or password is needed in Flutter.

## Configure a live Android build

In Firebase Console, open Project settings > General > MueNee Android and
download `google-services.json`. Keep it outside Git, for example at
`config/google-services.json` (ignored). From the project directory:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/configure_firebase.ps1 -GoogleServicesJson config/google-services.json
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/build_android.ps1
```

The converter validates `muenee-pj` and `com.muenee.app`, then generates
`config/firebase.local.json` without overwriting any existing file. It never
prints the client API key. `config/firebase.example.json` documents the fields.
Execution policy above applies only to the new PowerShell process; it does not
change the machine's policy. The build helper uses the sibling local toolchain
and preserves the repository Gradle memory settings.

With your own installed Flutter/Android SDK, the equivalent commands are:

```powershell
flutter pub get
flutter run --dart-define-from-file=config/firebase.local.json
flutter build apk --debug --dart-define-from-file=config/firebase.local.json
```

Explicit Dart `FirebaseOptions` configure and validate the default native
Firebase app. These three
plugins do not require adding the Google Services Gradle plugin or checking in
native config. Re-evaluate FlutterFire configuration when adding Google sign-in,
Crashlytics or another service that needs native resources/plugins.

The live app initializes App Check with Play Integrity. For a local debug device,
`--dart-define=FIREBASE_APP_CHECK_DEBUG=true` explicitly selects the debug provider;
its token must be registered privately in Console before enforcement. Never put
debug tokens in source, reports or chat. Profile/release builds reject this flag.
Do not turn on enforcement until valid app attestation has been tested.

## Provision and deploy Firestore

The production `(default)` database must be created explicitly in Singapore as
`asia-southeast1` before any rules deployment. Do not run a raw first-time
`firebase deploy --only firestore` against a project without a database: Firebase
CLI can auto-create `(default)` in its own fallback location.

After the database exists, use the guarded deployment helper:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/deploy_firestore.ps1
```

The helper reads database metadata first and refuses to deploy unless the
project is `muenee-pj`, the database is Firestore Native `(default)`, and its
location is exactly `asia-southeast1`. It then publishes the checked-in
deny-all rules and empty index definition. Never use the demo project for a
live deployment.

## Local Emulator Suite

Requires Node 22+ and Java 21 for Firebase CLI 15. Android builds still use JDK 17.
Install the pinned test tooling with `npm ci`. The local `.firebaserc` defaults
to the **demo** project. Always use `--project muenee-pj` explicitly for any
deliberate live administrative operation; emulator commands pin the demo ID.

```powershell
npm run emulators
flutter run --dart-define=FIREBASE_MODE=emulator
```

Set Java 21 on `PATH` before `npm run emulators`. In this checkout it is installed
under `../.tooling/jdk/jdk-21.0.12.1+1`. The Android emulator uses `10.0.2.2:8080`
to reach Firestore bound to the host's `127.0.0.1:8080`. Storage uses port 9199
for rule tests; the mobile Storage SDK is deferred until uploads are in scope.
For a physical device, use `adb reverse tcp:8080 tcp:8080` and
`--dart-define=FIREBASE_EMULATOR_HOST=127.0.0.1`; no LAN listener is needed.

No real-project options are used in emulator mode, even if a live config file
was also passed. The Firestore disk cache is disabled for emulator runs.
There are no app startup reads, listeners, writes, or profile migrations.

## Validation

```powershell
flutter analyze --no-pub
flutter test --no-pub --concurrency=1
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/test_firebase_rules.ps1
flutter test integration_test/firebase_connection_test.dart -d <device-id> --dart-define=FIREBASE_MODE=emulator
```

The integration test also supports a live config after a Firestore database
with deny-all rules exists. It only attempts a server read of a nonexistent
`_phase2_probe/no-data` document and expects `permission-denied`; no document or
collection is created. SDK initialization does not itself verify network access,
database provisioning, API-key restrictions or App Check attestation.

With a connected Android device or emulator, run the guarded live acceptance:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/test_firebase_live_android.ps1 -DeviceId emulator-5556
```

The helper validates the ignored config is live and belongs to `muenee-pj`
before invoking the read-only probe.

For a backend-only check that does not depend on Android VM-service stability:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/test_firestore_live_rules.ps1
```

This helper reads the ignored API key in memory, never prints it, performs one
anonymous GET for the same nonexistent document, and requires HTTP 403
`PERMISSION_DENIED`. It never attempts a write.

Verified on 2026-09-06 in `D:\Project\MauNeePJ\MueNee`:

- `flutter analyze --no-pub`: passed with no issues.
- `flutter test --no-pub --concurrency=1`: all 35 tests passed. The ten Phase 2
  tests cover config validation/redaction, release safeguards, startup gating,
  timeout, readable failure, retry, and large-text layout.
- `scripts/test_firebase_rules.ps1`: all four Node test groups passed against
  Firestore and Storage emulators. Anonymous and authenticated contexts cannot
  read/list/create/update/delete Firestore data or read/list/upload/delete files.
- `scripts/test_firebase_android.ps1 -DeviceId emulator-5556`: passed on the
  Android 16 / API 36 x86_64 AVD. The native SDK initialized once, reached the
  Firestore emulator and received the expected server `permission-denied`.
- The ignored `google-services.json` was validated and converted to
  `config/firebase.local.json` for `muenee-pj` / `com.muenee.app`; neither file
  nor the client API key is tracked or printed.
- Live Firestore `(default)` is Standard/Native in Singapore
  (`asia-southeast1`) with delete protection enabled. The checked-in deny-all
  rules and empty index definition were deployed through
  `scripts/deploy_firestore.ps1` after its location guard passed.
- A first-time raw rules deployment had auto-created an empty `(default)` in
  Firebase CLI's `nam5` fallback. It was deleted before any document write; after
  waiting more than five minutes, `(default)` was recreated in Singapore. The
  guarded deployment script and the warning above prevent a repeat.
- `scripts/test_firestore_live_rules.ps1`: passed against the live endpoint with
  HTTP 403 `PERMISSION_DENIED`; the probe attempted no write.
- The live Android integration runner was attempted twice, but the constrained
  API 36 AVD went offline while Flutter connected its VM service, before the
  test body ran. This is not counted as a Firebase pass or failure. The same
  native integration test passed earlier against the local Firestore emulator.
- `scripts/build_android.ps1 -X64`: built the normal live-config APK. It
  installed and reached the existing home screen on the read-only API 36 AVD;
  logcat contained no fatal exception, ANR, unhandled exception, or MueNee
  Firebase startup failure. The APK is 110,270,278 bytes with SHA-256
  `a4520024cc5138dccf17f101f29507c5a0b868b860436ba8e48a2cd1c3b80b93`.
  `aapt` reports `com.muenee.app` version `1.0.0+1`, minimum SDK 24, target SDK
  36, and the existing arm64-v8a, armeabi-v7a, and x86_64 native ABIs.
  `apksigner verify --verbose` passed with v2 and one signer. See the
  [live startup screenshot](../artifacts/phase-2-firebase/live-main.png).
- `scripts/build_android.ps1 -Emulator -X64`: passed. The resulting debug APK is
  82,951,989 bytes with SHA-256
  `e9c8e4f6075d418802d1d7b6baeff656c4fb6a8a1108aa0c692bde9a3b506bda`.
  `aapt` reports package `com.muenee.app`, version `1.0.0+1`, minimum SDK 24,
  target SDK 36 and all three existing ABIs. `apksigner verify --verbose`
  passed with APK Signature Scheme v2 and one signer.
- The final APK installed and launched on the read-only API 36 AVD. UI hierarchy
  and visual review confirmed the existing home after Firebase startup; logcat
  contained no MueNee fatal exception, Flutter error, unhandled exception, ANR,
  or Firebase initialization failure. See the
  [Phase 2 home screenshot](../artifacts/phase-2-firebase/home.png).

The build emits upstream FlutterFire Built-in Kotlin migration and Android SDK
XML tooling-version warnings. They do not currently prevent analysis, tests,
packaging or runtime startup, but FlutterFire should be upgraded when a release
adds Built-in Kotlin support.

The Phase 2 connection acceptance is complete. App Check provider activation is
part of live startup, but a valid Play Integrity attestation and server-side
enforcement have not yet been observed; do not enable enforcement until they are
tested on a suitable device. No live data write was attempted.

## Remaining work outside this connection foundation

Authentication UI/providers, account profile sync, collection schema, production
restaurant seed data, location, maps, recommendation ranking, tracking, image
uploads and Cloud Functions/AI are not implemented in this phase. Firestore
deny-all rules are deployed live; Storage rules have only emulator coverage
because Cloud Storage is not provisioned. Storage and Cloud Functions require
their own setup/billing decisions when those features are implemented.

See [ADR 0004](architecture/adr/0004-firebase-connection.md) for the decisions.
