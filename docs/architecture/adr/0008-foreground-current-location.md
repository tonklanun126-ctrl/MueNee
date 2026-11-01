# ADR 0008: Foreground, user-initiated current location

- Status: Accepted
- Date: 2026-09-06

## Context

MueNee needs a current position before later phases can rank nearby meals. The
MVP is Android-first and does not require continuous navigation or background
tracking. Location permission is sensitive and the core flow must remain clear
when services or permission are unavailable.

## Decision

Use the approved `geolocator` package behind a feature-local service contract.
Request location only after an explicit user action, accept either approximate
or precise foreground access, retrieve one current fix with a bounded timeout,
and retain it only in Riverpod process memory during Phase 6.

Declare coarse and fine foreground Android permissions. Do not declare
background or foreground-service location permissions. Represent disabled
services, denied permission, permanent denial, timeout, and unexpected failure
as explicit UI states with appropriate recovery actions.

## Consequences

- Widget and controller tests can use fakes without a native method channel.
- Restarting the app intentionally clears the current fix.
- Later recommendation work can consume the in-memory position, but persistence
  or transmission requires a separate privacy and product decision.
- Phase 6 does not calculate restaurant distance, rank menus, or open a map.
