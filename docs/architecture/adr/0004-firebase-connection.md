# ADR 0004: Firebase initialization and isolated local testing

- Status: Accepted for Phase 2 Firebase connection
- Date: 2026-09-06

## Context

The user authorized Phase 2 and supplied Firebase project `muenee-pj`.
The approved development order puts Firebase connection before authentication,
Firestore schema, and production data. Existing profile and food preferences
must keep their device-local storage contracts.

## Decision

- Register only the Android app `com.muenee.app`. Use `firebase_core`,
  `cloud_firestore`, and `firebase_app_check` with Riverpod dependency injection.
- Supply explicit `FirebaseOptions` from an ignored JSON build input using
  `--dart-define-from-file`. A converter checks the project/package before
  accepting the Console's `google-services.json`. Do not store credentials in
  Dart, introduce service accounts, or require a new Firebase app per build.
- Initialize the default Firebase app from explicit options, then validate every
  option before exposing Firestore. This avoids implicit native configuration
  while remaining compatible with Firestore's native platform delegate.
- The default mode is `live` and requires configuration. Missing or invalid
  configuration produces a visible startup error. Do not silently fall back to
  demo mode or report network connectivity from SDK initialization alone.
- Provide loading, failure, timeout, and explicit retry states. Keep one native
  initialization in flight even when the UI times out, to avoid duplicate apps.
- Enable the Play Integrity App Check provider for live configuration. The
  debug provider requires an explicit debug-only build flag; do not enable
  enforcement until app registration/attestation is verified in Console.
- Emulator mode is debug-only, always uses `demo-muenee-pj`, binds services to
  loopback, and disables the Firestore disk cache. Release/profile builds reject
  emulator mode and debug App Check. USB testing can use `adb reverse`.
- Deny all Firestore and Storage access until account/schema-specific policies
  are implemented and tested. No production test-mode rules or health document.
- Test rules using the official Firebase rules test library against local
  Firestore/Storage emulators, including authenticated and anonymous access.
- Verify Android SDK connection with a read-only `Source.server` probe that
  expects a rules denial. This is a separate test, never an app startup read.

## Consequences

Flutter initialization and feature tests can run without a Firebase login.
Local preferences stay on the device; this phase creates no application
collections, sign-in UI, uploads, ranking, tracking, or Cloud Functions.

Client Firebase config is distributed in the installed APK; keeping it out of
Git does not make it a secret. Security Rules, App Check and appropriate API-key
restrictions protect backend access. App Check provider activation alone is not
proof of a valid attestation or server-side enforcement.

Java 17 remains the Android build runtime. Firebase CLI 15 requires Java 21;
the checkout keeps both versions in `.tooling` and selects per process.

References: [Flutter setup](https://firebase.google.com/docs/flutter/setup),
[Firestore emulator](https://firebase.google.com/docs/emulator-suite/connect_firestore),
[App Check](https://firebase.google.com/docs/app-check/flutter/default-providers).
