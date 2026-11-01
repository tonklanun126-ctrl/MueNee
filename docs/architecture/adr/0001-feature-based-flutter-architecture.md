# ADR 0001: Feature-based Flutter architecture

- Status: Accepted
- Date: 2026-09-05

## Context

MueNee needs an Android-first Flutter foundation that stays simple for the MVP
while keeping UI state and Firebase access testable.

## Decision

- Organize application code under `app`, `core`, and `features`.
- Keep feature-owned presentation, providers, models, repositories, and services
  together.
- Use Riverpod for application state and dependency injection.
- Use `go_router` for navigation and future authentication redirects.
- Keep business logic out of widgets.
- Add folders and abstractions only when a concrete feature needs them.

## Consequences

- Feature ownership is visible from the directory tree.
- Tests can replace repository providers without initializing Firebase.
- Cross-feature dependencies must remain explicit and must not form cycles.
- The project avoids a separate domain/use-case layer until MVP complexity
  demonstrates a need for one.
