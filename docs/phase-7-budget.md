# Phase 7: Meal budget

Phase 7 implements development-priority item 8. The user subsequently authorized
the previously deferred UI/UX. `/budget` now exposes the existing budget core.

## Budget contract

- The value is the maximum budget for one meal in Thai baht.
- Only whole-baht amounts from 1 through 10,000 are accepted.
- Plain digits, correctly grouped thousands separators, and Thai digits are
  accepted. Examples: `80`, `1,000`, and `๒๕๐`.
- Decimals, negative values, text, embedded spaces, and malformed separators
  are rejected rather than silently rounded or altered.
- Empty, invalid-format, below-minimum, and above-maximum inputs remain distinct
  errors so the later UI can show a useful message beside the field.
- Invalid input never overwrites the last confirmed budget.

The upper bound is an MVP guard against accidental input, not a claim about
restaurant prices. It can be changed with a product decision before the UI is
finalized.

## State and privacy

`MealBudgetController` stores only a validated `MealBudget` in Riverpod process
memory. The value is not persisted to SharedPreferences, synced to a user
document, or written to Firestore. Restarting the app clears it, matching the
session-only location state used by the current core-flow foundation.

## Implementation

- `features/budget/models/meal_budget.dart`: invariant, parser, normalization,
  and structured validation errors.
- `features/budget/providers/meal_budget_provider.dart`: confirmed in-memory
  state, validation-aware confirmation, and clear behavior.
- `test/budget/meal_budget_test.dart`: parsing, range, invariant, state
  preservation, and clearing coverage.

## UI and interaction

- Open from the wallet action in the home app bar or the ready Location screen.
- The warm-coral amount panel explains the maximum per-meal budget and units.
- Choose 60, 80, 100, or 150 baht, or enter a custom amount. No default is selected.
- Presets update only the draft; confirmation or the keyboard Done action commits.
- Invalid input shows Thai field errors and focuses the amount field.
- A separate confirmation card shows the actual saved amount while editing.
- Back with an unsaved change offers keep editing or discard; the confirmed
  amount survives navigating away and reopening within the running app.
- Content scrolls, including the action, for keyboard and large-text layouts.
- Budget entry itself does not require a location permission or account.

No food-preference flow integration or recommendation filtering/ranking is part
of this work.

## Validation evidence (2026-09-07)

- `flutter analyze --no-pub`: passed with no issues.
- Six budget model/controller tests passed.
- The complete Flutter suite passed all 65 tests.
- No dependency, platform permission, Firebase rule, schema, or live data
  change was required.
- These 65 tests describe the initial core checkpoint. UI validation is recorded
  separately below; it is not evidence of a native device run.

### UI acceptance (2026-09-07)

- `flutter analyze --no-pub`: no issues; full Flutter suite: 69 tests passed.
- Four widget tests cover Location navigation, draft versus confirmation,
  reopening, Thai input, invalid edits, discard protection, and a 320x640
  viewport at 2x text scale.
- Debug x64 APK built successfully after a network-restricted dependency
  resolution attempt was retried with network access.
- Installed on Android API 36 emulator without clearing app data. Native
  smoke test opened the home wallet action, selected 80 baht, and confirmed
  the visible saved-budget message. Settled screenshot visually inspected:
  `artifacts/phase-7-budget.png`.
- No live Firebase mutation or Phase 8 recommendation implementation.
