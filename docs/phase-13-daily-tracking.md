# Phase 13: Daily Tracking

Phase 13 completes the last step of the current recommendation flow by making
confirmed meal logs visible to their signed-in owner. It does not implement AI
Food Scan, manual meal entry, editing, deletion, targets, or health advice.

## User experience

`/tracking` is reachable from the working “บันทึก” bottom destination and from
the successful Phase 12 selection card. At Phase 13 acceptance the navigation
exposed only “มื้อนี้” and “บันทึก”. Phase 14 subsequently activated the working
“สแกน” destination; account/profile remain available from the home actions.

The screen provides:

- today by default, with previous/next day controls that never move into future;
- a meal count and approximate calorie, protein, carbohydrate, and fat totals;
- newest-first meal cards with local time, origin, and estimated nutrition;
- explicit account loading, signed-out, incomplete-session, loading, empty,
  server failure, retry and pull-to-refresh states;
- an empty-today action back to the meal recommendation flow; and
- responsive scrolling at 320 x 640 with 200% text scaling.

The wording is intentionally neutral. Totals are sums of the stored estimates,
not a score, a calorie target, or medical advice. A validated synchronized target
does not exist yet, so the UI does not invent a progress ring or “remaining” value.

## Query contract

`FirestoreMealLogRepository.watchMealsForDay` constructs midnight-to-midnight
boundaries in the device's local timezone, converts both boundaries to UTC, and
queries:

```text
meal_logs
where userId == auth.uid
where createdAt >= local-day-start-as-UTC
where createdAt < next-local-day-start-as-UTC
orderBy createdAt desc
limit 50
```

The existing `userId ASC + createdAt DESC` composite index supports the query.
Existing Phase 4 rules require the matching authenticated owner. Cache-only
snapshots are withheld; if no server result arrives within 20 seconds, the UI
shows a retryable failure rather than claiming the day is empty. Malformed
documents fail explicit model decoding instead of being silently skipped.

No schema, Security Rules, or index change was required or deployed. The 50-item
bound avoids an unbounded daily read and is disclosed if reached.

## Architecture

- `DailyMealLogRepository` separates read behavior from Phase 12 create behavior.
- `DailyMealRequest` gives the Riverpod family a normalized local-day identity.
- `dailyMealsProvider` owns the server stream lifecycle and is auto-disposed.
- `DailyNutritionSummary` performs deterministic totals outside the widgets.
- `MainNavigationBar` exposes only currently working primary destinations.

See [ADR 0013](architecture/adr/0013-owner-daily-meal-query.md).

## Validation

Verified 2026-09-10:

- `flutter analyze --no-pub`: clean;
- all 100 Flutter tests: passed, including account privacy, totals, date movement,
  empty/error retry, navigation, Phase 12 continuity, and 200% text scaling;
- all five Firestore/Storage Rules Emulator groups: passed with the exact bounded
  owner/date-range query and existing denied cross-owner/anonymous cases;
- Android 16 / API 36 Auth + Firestore Emulator acceptance: passed with two
  generated recommendation meals, an 830 kcal summary, owner read and cleanup;
- visual screenshot inspected without clipping or overflow:
  `artifacts/phase-13-daily-tracking/daily-tracking.png`;
- live-config x86_64 debug APK: 116,916,559 bytes, APK Signature Scheme v2
  verified, SHA-256
  `4C801424745A0463B56AD726A90942C719C4E651AD66CD78DE846A74788278FC`.

The native test generated and removed only its own Auth/Firestore Emulator data
inside `demo-muenee-pj`. No live `muenee-pj` read/write, rule/index deployment,
or account mutation was performed.

## Remaining boundary

At Phase 13 acceptance, Phase 14 AI Food Scan and all meal
edit/delete/manual-entry behavior were still unstarted. Phase 14 was
subsequently implemented; its live Gemini acceptance remains pending. Phase 11
remains separately pending until a restricted Maps key and real tiles/markers
are visually accepted.
