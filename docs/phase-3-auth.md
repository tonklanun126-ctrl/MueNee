# Phase 3: Authentication

Verified 2026-09-06: Flutter analyze passed and all 45 Flutter tests passed
(35 existing and 10 authentication/contrast tests). The Android Auth emulator
lifecycle test also passed on Android 16/API 36 (three integration runs,
including process persistence, also rerun through Flutter driver to retain
screenshots). The final live-config Android
debug APK build and APK v2 signature verification passed. Live mailbox acceptance
was completed by the user; native process-persistence acceptance also passed.

Implemented: optional `/account` route from the home account icon, Thai
email/password forms, password confirmation, reset, verification mail, reload,
sign-out and SDK-managed session persistence. Uses the existing design tokens.
Local settings are still shared on this device; no profile sync is implemented.

Run `scripts/check_flutter.ps1` for formatting, analysis and Flutter tests.
Run `scripts/build_android.ps1 -X64` for an Android debug build with local config.
For emulator authentication, start Auth on 127.0.0.1:9099 using the demo project
alongside Firestore; the app selects the same configured emulator host.

Live Email/Password was explicitly approved and enabled in Firebase Console on
2026-09-06. Email-link/passwordless sign-in remains disabled. An authorized live
test account was created for `tonkla.nun126@gmail.com` using an in-memory random
temporary password: create, sign-out, password sign-in, verification-email
request, password-reset request, and final sign-out all succeeded. The console
Users list shows exactly this one account with created/signed-in dates Sep 6,
2026. The temporary password was neither printed nor persisted.

The user confirmed opening the Firebase verification link and completing the
password reset in Gmail. The temporary password was never printed or persisted.
The automated widget tests use an injected fake repository and send no mail.

## UI/UX review and regression fixes

- Preserve the email when switching sign-in/register/reset forms; clear passwords.
- Return to sign-in after signing out of a newly registered account.
- Keyboard Next/Done actions, dismissal on submit, multiline Thai validation.
- Disable controls while a request is pending; prevent duplicate submissions.
- Use the production theme in widget tests at 320 x 640 with 200% text scale.
- Use the existing darker coral for CTA backgrounds/text actions/focused labels.
  Tested contrast: white on dark coral 4.89:1; dark coral on canvas 4.75:1.
- Reject verification/reload without a current session instead of reporting success.

## Native emulator acceptance

Run `scripts/test_firebase_android.ps1 -Auth -DeviceId emulator-5556` with an
Android emulator already booted. The test refuses live configuration, uses
`demo-muenee-pj`, and exercises the real Dart repository/native Firebase Auth SDK.
Its out-of-band codes are emulator-only; it never accesses a real mailbox.
See [Firebase's non-interactive emulator testing guidance](https://firebase.google.com/docs/emulator-suite/connect_auth#non-interactive_testing).

The first run exposed Android blocking cleartext HTTP to `10.0.2.2`. The debug
source set now has a network security policy allowing only the three supported
local emulator hosts; all other HTTP remains disabled. Main/profile/release
manifests are unchanged. This follows Android's
[per-domain network security configuration](https://developer.android.com/privacy-and-security/security-config#CleartextTrafficPermitted).

The Flutter integration driver saves five
account UI captures into `artifacts/phase-3-auth/`. These are native Flutter
screens using the actual theme and Android Thai font fallback, not mockups.
The test cleans up only its own generated emulator account.

The persistence companion tests leave a generated emulator account signed in,
force-stop the app while retaining app data, launch a new app process, assert
that native Firebase Auth restores the same account, then delete that exact
account. This is separate from the live account and never uses its password.

The five PNG captures were opened for visual review: Thai text and form actions
are readable in the captured scroll positions, and the compact-screen widget
tests remain overflow-free. The native run used 1,536 MiB/2 cores per the existing
constrained-Windows validation procedure. No app fatal exception, unhandled
exception, or app ANR was found in the final logcat scan. Both Firebase emulators
and the Android emulator were stopped after testing.

Final normal application artifact (not the integration-test entrypoint):
`build/app/outputs/flutter-apk/app-debug.apk`, 110,624,078 bytes,
SHA-256 `61f77d24f6fdb000c626bfffa6bbe37bf4ca50988b4806404b4ccbcb645ff594`.
Package `com.muenee.app`, version `1.0.0`/1, minimum SDK 24, target SDK 36.
Build warnings remain about Firebase plugins' future Built-in Kotlin migration
and Android command-line SDK XML versions; neither prevented this build.

Passed native flow: register through the form, send verification, apply the
emulator action code, reload verified status, sign out, reject sessionless
verification/reload, request reset through the form, apply reset, reject the old
password, sign in through the form with the new password, then delete the
generated test account. No production account or email was created.

Phase 3 acceptance is complete for the requested scope: provider enabled, live
signup/sign-in/email requests passed, user-confirmed mailbox verification/reset,
and native Android lifecycle plus process-persistence tests passed. Emulator
action-code tests do not substitute for the user's live mailbox confirmation.

The 16 numbered entries in PROJECT_CONTEXT.md are development priorities, not
16 formally approved phases. Phase 1 covered priorities 1–2, Phase 2 covered 3,
and Phase 3 covers 4. Earlier chat totals of 14 phases were incorrect.
