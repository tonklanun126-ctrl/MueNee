# Phase 10: Restaurant and menu detail

Phase 10 implements the restaurant-detail step after deterministic Top 3
recommendations. Each recommendation now exposes a `ดูร้าน` action and carries
the exact restaurant/menu snapshot, rank, and straight-line distance already
shown on the results screen into a dedicated detail route.

## User experience

- The detail page continues the menu and restaurant identity from the selected
  recommendation and keeps Android Back behavior intact.
- Price amount, effective confidence, source, and verification date are visible;
  verification expires under the existing 30-day policy.
- Nutrition includes calories, protein, carbohydrates, and fat, all explicitly
  presented as estimates rather than a health score or medical result.
- Address, straight-line distance, catalog verification status, and catalog
  update date are shown. Rating and opening status are intentionally omitted
  because the current Firestore schema does not retain their source freshness.
- Ingredient and allergen evidence distinguish known values from incomplete
  recipe/cross-contact data. Price verification never implies dietary safety.
- Catalog image URLs are used when supplied. Missing or failed images retain
  layout with an honestly labelled local illustration.

## Navigation and data boundary

The route is `/restaurant/:restaurantId/menu/:menuId`. Normal navigation passes
an immutable `RestaurantDetailArguments` snapshot from the selected result.
This avoids an unnecessary second Firestore read and prevents the detail page
from disagreeing with the recommendation card during the same visit. A direct
or restored URL without that selected snapshot fails safely and asks the user
to return to recommendations; IDs or SDK errors are not exposed.

This phase performs no Firestore writes and changes no rules or indexes. It does
not add Maps, travel-time claims, opening hours, ordering, meal selection,
tracking, Gemini, Analytics, or Crashlytics. Those remain later phases.

## Validation

Verified 2026-09-08:

- Flutter analyzer passed with no issues and all 91 Flutter tests passed.
- Phase-specific tests cover detail content, evidence sheet, incomplete dietary
  evidence, absence of future actions, actual router navigation/back behavior,
  safe direct-route failure, and 320x640 at 200% text scale.

Android APK build/signature and visual smoke evidence are recorded separately
after they complete; Flutter tests alone are not native acceptance evidence.
