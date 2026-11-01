# ADR 0009: Validated session-only meal budget

- Status: Accepted; UI subsequently authorized
- Date: 2026-09-07

## Context

The deterministic recommendation flow will need a maximum per-meal budget.
Phase 7 was authorized, while UI/UX work was explicitly deferred. The existing
current-location value is session-only and there is no approved requirement to
sync the active search budget across launches or accounts.

## Decision

Represent the confirmed value with a `MealBudget` object constrained to whole
baht from 1 through 10,000. Parse user-oriented text in the domain layer,
including Thai digits and valid comma grouping, and return structured errors.
Keep the last valid value when later input fails validation.

Store the confirmed budget only in a Riverpod notifier for the app process. Do
not add SharedPreferences, Firestore writes, schema changes, or a second state
management mechanism.

## Consequences

- Later UI can map stable error values to accessible Thai field messages.
- Recommendation code will receive only validated integer-baht values.
- Restarting the process clears the active budget.
- Persistence, account sync, and recommendation behavior require their own
  authorized work and are not implied by this decision.

The authorized budget UI now consumes this contract without changing persistence.
