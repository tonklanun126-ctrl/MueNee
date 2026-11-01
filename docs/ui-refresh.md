# Existing-screen UI refresh

Date: 2026-09-08. First implementation increment of DESIGN.md v2, not completion
of all design specifications or future phases.

## Implemented

- Home: warm hero, editable location/budget status, context-aware primary action,
  quieter secondary actions, and scroll space for transient feedback.
- Budget: compact amount panel and safe-area bottom confirmation button.
- Food preferences: live selection counts and collapsible dislikes; hard
  restrictions/allergy filtering and explicit meal confirmation are preserved.
- Results: compact illustrated headers (explicitly labelled as illustrations),
  calmer fact labels, static accessible loading placeholders, and a bottom sheet
  explaining ranking factors, source/date, and estimate limitations.
- Shared rounded cards; user-facing privacy/profile/account copy instead of
  implementation-phase terminology; branded warm Android launch resources.
- Flow tests updated for scrollable Home. Added explanation-sheet behavior test.

No catalog, ranking, authentication, backend rules, or live data were changed.
No restaurant-detail or meal-recording controls were added before their phases.

## Validation

- Flutter analyzer: no issues.
- Flutter tests: 86 passed, including small-screen/200% text cases and existing
  filtering, persistence, budget, authentication, and navigation coverage.
- Logs: `artifacts/ui-refresh-check.log`, `artifacts/ui-refresh-build.log`.
- Android x86_64 debug APK built successfully (116326420 bytes).
- SHA-256: `C77143A5669E0A1E9B2F9542CDF3F42D1D7A9EA0A762BAEC6E16AF4806A45F34`.
- Build emits existing Kotlin migration / SDK XML compatibility warnings.
- APK Signature Scheme v2 verified. Installed with `adb install -r`, without
  clearing app data. API 36 Home, Budget, and food-preferences screenshots were
  captured and visually inspected: `artifacts/ui-refresh-home.png`,
  `artifacts/ui-refresh-budget.png`, `artifacts/ui-refresh-preferences.png`.
- Native validation is partial: emulator System UI displayed an unresponsive
  dialog during startup; choosing Wait allowed navigation to continue. Sampled
  subsequent logs had no matching app fatal/Flutter exception, but this does not
  establish a clean full-flow Android acceptance. Results/explanation are covered
  by widget tests, not a new end-to-end native acceptance in this increment.

## Remaining design work

The complete v2 specification is broader than this increment: typography/assets,
budget preset hierarchy, globally shared context presentation, motion/haptics,
and representative-user evaluation still require follow-up. Food imagery remains
explicit illustration, not verified photography of these restaurants. Phase
11–15 surfaces remain gated to their corresponding implementation work. Phase
10 restaurant detail is documented separately in `phase-10-restaurant-detail.md`.
