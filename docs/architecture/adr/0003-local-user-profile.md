# ADR 0003: Local user profile inputs before account integration

- Status: Accepted for the Phase 1 profile-settings UX
- Date: 2026-09-05

## Decision

Store age, height, weight, and activity level in a separate versioned JSON
document (`muenee.user_profile.v1`) through a feature-owned repository using
`SharedPreferencesAsync`. Riverpod owns the loaded and last-confirmed profile;
the form keeps edits local until a successful save. A complete profile is
required when saving values from the form, while an empty profile remains a
valid initial state.

This is device-local setup data, not a new application database. Firestore
remains the approved primary database and account sync is deferred until
authentication and the user-profile schema are implemented.

## Consequences

- The Phase 1 flow works without sign-in and survives provider recreation.
- Clearing app data or reinstalling can remove the profile.
- The data contract is ready for later deterministic recommendation inputs but
  does not calculate calories, BMI, or medical advice.
- A repository boundary keeps storage and migration concerns out of widgets.
- The existing food-preference document and UX remain independent, so adding
  profile fields does not change food filtering behavior.

API reference: [shared_preferences](https://pub.dev/packages/shared_preferences).
