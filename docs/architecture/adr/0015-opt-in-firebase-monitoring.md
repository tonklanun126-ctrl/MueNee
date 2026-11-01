# ADR 0015: Opt-in Firebase monitoring

- Status: Accepted locally
- Date: 2026-09-12

## Context

Phase 15 requires product-flow observation and crash diagnostics. MueNee also
handles location, food restrictions, nutrition estimates, meal history and
account data. Monitoring must not silently turn those values into analytics
payloads, and emulator validation must remain isolated from the live project.

## Decision

Use Firebase Analytics and Firebase Crashlytics through a small
`TelemetryService` boundary. Native collection defaults to disabled. Store two
independent, explicit choices in a versioned device-local record and apply them
only after Firebase and the record are ready.

Use named routes for screen measurement and a closed enum for parameter-free
product events. Record expected non-fatal failures with fixed codes. Do not set
Analytics user properties/IDs or Crashlytics user identifiers/custom food,
location or profile keys.

Use a no-op implementation for test doubles and `demo-muenee-pj`. Apply the
Android Google Services and Crashlytics Gradle plugins only for live-config
builds, preserving the existing explicit emulator Firebase app.

## Consequences

- Collection cannot start merely because the SDK is linked or the user signs in.
- Guests can inspect, enable, disable and reverse either choice.
- Tests can assert settings and event vocabulary without native channels or
  production network traffic.
- Parameter-free events answer coarse funnel questions but cannot segment by
  budget, dietary constraint, location, food or nutrition; this is intentional.
- Crash diagnostics may include device/app metadata and stack traces, so the UI
  discloses that fact and keeps crash reporting separately optional.
- Live Firebase Console enablement and first-event/report verification remain a
  separately authorized operational acceptance step.
