# ADR 0005: Email/password authentication

Date: 2026-09-06. Status: accepted for Phase 3; future account-schema work remains.

Phase 3 implements development-order item 4 using Firebase Auth 6.6.1.
The account route is optional while existing local features remain available.
Email/password is the initial provider. Firebase SDK owns session persistence;
the app never stores passwords or tokens in SharedPreferences.

The feature uses a repository and Riverpod userChanges stream, initialized after
Firebase startup. Emulator mode attaches Auth to the configured loopback host
on port 9099 before accessing authentication. Forms support sign-in, sign-up,
password confirmation, reset, explicit verification mail, reload and sign-out.
Registration requires eight characters locally; Firebase enforces server policy.
Verification mail is explicit, so mail failure cannot disguise successful signup.

Android debug builds permit HTTP only to `10.0.2.2`, `127.0.0.1`, and `localhost`
through a debug-only network security resource so the native Auth SDK can reach
the local emulator. Release/profile network policy is unchanged. Native lifecycle
tests refuse live configuration and use only generated emulator accounts.

Local profile/preferences remain shared device data, stated in the account UI.
Account-scoped profile storage and authorization belong to the schema phase.
Firestore/Storage deny-all rules remain unchanged. Verification UI alone is not
backend authorization. Future rules must enforce identity/verification as needed.

Email/Password is enabled in Firebase Authentication; email-link sign-in remains
disabled. Do not use real customer credentials in tests. Live mailbox verification
and reset were completed by the authorized user; persisted-session acceptance was
verified with a generated emulator account/device.

Reference: https://firebase.google.com/docs/auth/flutter/password-auth
