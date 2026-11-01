# Phase 8: Food preferences in the meal flow

Phase 8 connects the existing, tested food-settings contract to the core meal
flow. It does not replace the conservative filtering policy introduced in
Phase 1 and does not implement recommendation ranking.

## User flow

1. Confirm a valid per-meal budget.
2. Choose **ต่อไป: เลือกอาหารที่กิน**.
3. Review hard dietary restrictions, allergies, dislikes, and hide-disliked
   behavior.
4. Explicitly confirm the saved selection for this meal. An empty selection is
   valid and must also be confirmed.

The meal-flow header avoids claiming that location is complete because the
budget screen also has a direct home shortcut. The user can safely return to
the budget screen after confirmation.

## Data and safety contract

- Hard restrictions and allergies remain conservative filters. Unknown
  evidence is never treated as safe.
- Dislikes remain soft ordering signals unless **ซ่อนอาหารที่ไม่ชอบทั้งหมด**
  is enabled.
- Saved preferences continue to use the versioned
  `muenee.food_preferences.v1` device-local document.
- Storage must succeed before confirmed Riverpod state changes. A failed save
  leaves the draft visible for retry.
- No profile migration, Firestore write, live-data mutation, account sync,
  recommendation result, nutrition calculation, or Phase 9 work is included.

## Implementation

- `/food-settings?flow=meal` activates meal-flow context without duplicating
  the existing settings model, repository, or screen.
- The budget screen enables its continuation action only when the displayed
  amount matches the confirmed budget.
- Meal-flow confirmation distinguishes an unchanged saved selection from a
  changed selection that must first be persisted.
- A visible completion card confirms readiness for the next step without
  pretending recommendations have been generated.

## Validation

- `flutter analyze --no-pub`: passed with no issues.
- `flutter test --no-pub --concurrency=1`: all 72 tests passed. Three new flow
  tests cover budget-to-preferences navigation, persisted hard filters,
  explicit empty-selection confirmation, and a 320x640 viewport at 2x text.
- The x86_64 debug APK built successfully and APK Signature Scheme v2
  verification passed with one signer.
- Android 16 / API 36 native smoke testing retained app data, confirmed an
  80-baht budget, continued to meal preferences, and explicitly confirmed the
  existing settings without changing them. The ready state was visually
  inspected in `artifacts/phase-8-food-preferences.png`.
- The app process log contained no matching fatal exception, ANR, Flutter error,
  or unhandled exception after the flow.
- No Firebase document, rule, index, authentication setting, or live data was
  read or changed for this phase.
