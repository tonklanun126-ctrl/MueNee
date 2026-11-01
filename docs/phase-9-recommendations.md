# Phase 9: Deterministic Top 3 recommendations

Phase 9 implements development-priority item 10. After location, budget, and
food preferences are ready, MueNee reads the active Firestore catalog and shows
up to three deterministic menu recommendations.

## Query contract

| Data | Query | Bound |
| --- | --- | ---: |
| Restaurants | `isActive == true`, order by `name` | 50 |
| Menus | `isActive == true` | 100 |

Both queries are public read-only under the deployed Phase 4 rules. The menu
candidate query uses the automatic single-field `isActive` index; no rules or
composite-index change is needed. Decoding remains strict: malformed version 1
documents fail visibly rather than being silently ignored.

Reads explicitly require the server and have a 20-second provider timeout with
manual retry. Each query requests one extra document to detect a catalog beyond
the supported bound; overflow fails visibly instead of ranking a partial set.

## Ranking contract

The engine first excludes inactive/orphaned menus, prices above the confirmed
whole-baht budget, and anything rejected by the existing conservative food
filter. Allergies and hard restrictions are never relaxed.

Remaining candidates receive distance, affordability, price-confidence, and
preference points as specified in ADR 0010. Disliked menus always follow all
other eligible menus. Stable tie-breakers ensure repeatable Top 3 results.
Within each preference tier, selection favors different restaurants before
repeating one. Diversity can select a lower-scoring restaurant, but never puts
a disliked menu ahead of an eligible non-disliked menu. Distances are estimated
straight-line distances, not walking or driving routes.
Nutrition is shown as an estimate but is not presented as medical advice or a
health score.

## UI behavior

- Phase 8 confirmation continues to `/recommendations`.
- Missing location or budget blocks loading and offers the correct recovery.
- Loading, retryable catalog failure, results, pull-to-refresh, and strict empty
  states are explicit.
- Cards show rank, menu, restaurant, price/confidence, distance, calories, and
  protein. They do not link to restaurant detail or Maps in this phase.
- SDK errors and raw coordinates are never displayed.

## Scope boundary

This phase adds only public Firestore reads. It does not write live data, change
rules/indexes, sync local preferences, use Gemini, log meal selections, open a
restaurant detail page, or start Phase 10.

## Validation

Verified 2026-09-08:

- Analyzer passed with no issues; all 85 Flutter tests passed, including
  deterministic diversity and preservation of dislike priority, safety filters,
  flow navigation, missing inputs, error/empty states, and 320x640 at 200% text.
- x86_64 debug APK built successfully; APK Signature Scheme v2 verified.
- Public live-client verification read 10 active restaurants and 30 active
  menus from `muenee-pj` without writes.
- API 36 Android smoke test with a simulated campus location and 100-baht
  budget loaded real catalog data through the final server-only repository.
  The final Top 3 contained menus from three distinct restaurants. Existing
  device preferences were confirmed without changing them.
- Final top/bottom screenshots visually inspected:
  `artifacts/phase-9-recommendations-final.png` and
  `artifacts/phase-9-recommendations-bottom.png`.
- Sampled app-process logs contained no matching fatal exception, ANR,
  FlutterError, unhandled exception, or recommendation-load error.
- No rules, indexes, live documents, or account settings were changed.

Current limitations: the catalog supports at most 50 restaurants/100 menus;
nutrition is informational, distances are straight-line estimates, and the
seed lacks complete dietary evidence, so strict restrictions may return none.
