# MueNee Coding Instructions

This repository contains the MueNee application.

Codex and other coding agents must follow these instructions when working in this repository.

---

## Before Making Changes

Always read:

1. PROJECT_CONTEXT.md
2. Relevant documentation under docs/
3. Existing code related to the requested feature

Do not start implementing large changes without understanding the current architecture.

---

## Planning

Before implementing a large feature:

1. Inspect the relevant existing files.
2. Explain the implementation plan.
3. List the files that will be created or modified.
4. Identify major risks or dependencies.
5. Then implement.

Do not modify unrelated files.

---

## Technology Rules

Use the existing approved stack:

- Flutter
- Dart
- Riverpod
- go_router
- Firebase Authentication
- Cloud Firestore
- Firebase Storage
- Cloud Functions 2nd Gen
- TypeScript
- Google Maps
- Google Places API (New)
- geolocator
- Gemini through Firebase AI Logic
- image_picker

Do not introduce a new framework, database, backend platform, or state-management library without approval.

---

## Flutter Architecture

Use a feature-based structure.

Preferred structure:

lib/
├── app/
├── core/
└── features/

Feature folders may contain:

- presentation
- providers
- models
- repositories
- services

Keep widgets small and focused.

Avoid placing significant business logic directly inside widgets.

Use Riverpod for application state.

Use go_router for navigation.

---

## Firebase Rules

Cloud Firestore is the primary application database.

Firebase Storage is used for images and uploaded media.

Firebase Authentication manages user identity.

Use Cloud Functions when server-side trust or protected logic is required.

Do not create another application database unless explicitly approved.

---

## Firestore

Design queries before designing collections.

Avoid unnecessary reads.

Use timestamps for createdAt and updatedAt where appropriate.

Do not duplicate large amounts of data unless required for a clear query or performance reason.

Use explicit model serialization.

Keep schema changes documented.

---

## External APIs

Google Places is for place and restaurant information.

MueNee menu, price, nutrition, verification, and recommendation data belongs in Firestore.

Gemini should primarily be used for AI Food Scan in the MVP.

Do not use Gemini for deterministic logic that can be implemented safely in application code.

---

## Secrets and Security

Never commit:

- API secrets
- Service account files
- Private keys
- Credentials
- Production .env files

Never hardcode secret values in Dart or TypeScript source.

Use platform-appropriate configuration and environment variables.

Apply Firebase Security Rules.

Use Firebase App Check where supported.

---

## MVP Development Principle

Prefer simple and maintainable code.

Do not over-engineer.

Avoid:

- Microservices
- Unnecessary abstractions
- Premature scaling infrastructure
- Additional databases
- Complex architecture with no current MVP benefit

Solve the current requirement first.

---

## Recommendation Engine

For the MVP, recommendation ranking should be deterministic.

Possible ranking inputs:

- Budget
- Food preference
- Nutrition
- Distance
- Price confidence

Return the Top 3 menus.

Do not replace this with an AI-only recommendation system without approval.

---

## AI Food Scan

Food Scan flow:

Image
→ Gemini analysis
→ Structured nutrition estimate
→ User confirmation/edit
→ Meal log

Treat AI nutrition output as an estimate.

The user must be able to confirm or edit the result before it affects Daily Tracking.

---

## Code Quality

For Flutter changes, run:

flutter analyze

flutter test

For Cloud Functions changes, run the relevant checks such as:

npm run lint

npm test

If tests do not exist yet, clearly state that instead of pretending they passed.

---

## Error Handling

Do not silently ignore exceptions.

Use clear error states for:

- Network failures
- Firebase failures
- Permission denial
- Location failures
- Gemini failures
- Google Maps / Places failures

User-facing errors should be understandable.

Development errors should retain enough context for debugging.

---

## Git Discipline

Keep changes scoped to the requested task.

Prefer small logical commits.

Do not rewrite unrelated code.

Do not delete working code without explaining why.

Do not commit generated secrets or local environment files.

---

## Documentation

When an architectural decision changes, update the relevant documentation.

For major architectural decisions, create an ADR under:

docs/architecture/adr/

Examples:

- Database choice
- State-management choice
- Authentication approach
- Recommendation architecture

---

## Completion Summary

After implementing a task, report:

1. What changed
2. Files changed
3. Tests/checks run
4. Any remaining issues
5. Suggested next step

Do not claim a feature is complete if required checks failed.A

## Scope Guardrails

- Only work on tasks explicitly requested by the user.
- Do not implement additional features "for completeness".
- Do not change the approved tech stack without explicit approval.
- Do not refactor unrelated working code.
- Do not create new infrastructure unless required by the current task.
- If a request conflicts with PROJECT_CONTEXT.md, stop and ask for approval.
- If unsure whether a change is in scope, ask before modifying files.
- Prefer the smallest change that solves the requested task.

## Protected Decisions

The following are locked unless explicitly approved:

- Flutter / Dart
- Riverpod
- go_router
- Cloud Firestore
- Firebase Auth
- Firebase Storage
- Cloud Functions 2nd Gen + TypeScript
- Google Maps
- Google Places API (New)
- Gemini through Firebase AI Logic