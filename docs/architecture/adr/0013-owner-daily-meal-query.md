# ADR 0013: Owner-scoped daily meal query and estimated totals

- Status: Accepted
- Date: 2026-09-10

## Context

Phase 12 writes private recommendation meal logs, but users need a trustworthy
daily view. The view must respect the user's calendar day, avoid unbounded reads,
not expose another account's data, and not turn nutrition estimates into implied
medical goals.

## Decision

Read at most 50 meal logs using the authenticated UID, a half-open local-day
range converted to UTC, and descending `createdAt`. Reuse the deployed Phase 4
composite index and owner rules. Require a server-backed snapshot with a 20-second
timeout, while Riverpod provides lifecycle, refresh and retry handling. Calculate
totals deterministically from decoded meal snapshots and label them as estimates.

Expose only the working “มื้อนี้” and “บันทึก” primary destinations. Do not add a
Scan destination, nutrition target, edit, delete, or manual-entry control until
its own behavior is implemented and authorized.

## Consequences

- Calendar grouping follows the device timezone at query time; travel can make a
  meal appear under a different local date, which is preferable to assuming a
  fixed global timezone without a user setting.
- Offline cache is not presented as confirmed-current tracking data; users see a
  retryable error if the server cannot answer.
- Malformed documents make the day fail visibly instead of corrupting totals.
- Days above 50 entries are intentionally truncated and labelled.
- The screen is read-only; corrections and deletion remain future scoped work.
