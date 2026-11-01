# MueNee Project Context

## Product Overview

MueNee is a mobile application that helps users discover nearby meals based on:

- Current location
- Budget
- Food preferences
- Estimated nutrition
- Restaurant and menu data

The main goal is to help users decide what to eat quickly while keeping spending and nutrition in mind.

---

## MVP Scope

Initial MVP area:

Silpakorn University, Nakhon Pathom, Thailand

Initial dataset:

- 10–20 real restaurants
- 3–5 menu items per restaurant

The first version should focus on completing the core user flow reliably before adding advanced features.

---

## Core User Flow

Location
→ Enter Budget
→ Select Food Preference
→ Recommend Top 3 Menus
→ View Restaurant on Map
→ Select Meal
→ Daily Tracking

---

## AI Food Scan Flow

Take or select food photo
→ Analyze image with Gemini
→ Estimate food name and nutrition
→ User confirms or edits result
→ Save meal to Daily Tracking

AI-generated nutrition values are estimates and must be confirmable/editable by the user.

---

## Tech Stack

### Frontend

- Flutter
- Dart

### State Management

- Riverpod

### Navigation

- go_router

### Authentication

- Firebase Authentication

### Database

- Cloud Firestore

Firestore is the primary application database.

Do not introduce another database unless there is a clear architectural reason and it is approved first.

### Image Storage

- Firebase Storage

Used mainly for uploaded food images and other application media.

### Backend

- Cloud Functions 2nd Gen
- TypeScript

Use Cloud Functions for trusted server-side logic, external API calls that require protection, validation, and background processing.

### Maps and Places

- Google Maps for Flutter
- Google Places API (New)

Google Places is used for restaurant/place information.

MueNee-owned menu, price, nutrition, verification, and recommendation data is stored in Firestore.

Use Google Place ID to associate MueNee restaurant records with Google Places data.

### Location

- geolocator

### AI

- Gemini through Firebase AI Logic

Primary MVP AI use case:

- AI Food Scan

Do not use AI for logic that can be implemented reliably with deterministic rules.

### Food Image Input

- image_picker

### Security

- Firebase Security Rules
- Firebase App Check

Never hardcode private secrets or unrestricted API keys in source code.

### Debugging and Monitoring

- Firebase Crashlytics
- Firebase Analytics

### Local Development

- Firebase Emulator Suite

### Source Control

- Git
- GitHub

### Development Environment

- VS Code
- Codex

---

## Architecture Principles

### 1. Mobile First

MVP is mobile-first.

Primary development target:

- Android

iOS support can follow after the main Android flow is stable.

Flutter Web is not part of the first MVP unless explicitly requested.

---

### 2. Keep the MVP Simple

Prefer the simplest solution that satisfies the current MVP.

Avoid:

- Premature microservices
- Additional databases
- Unnecessary infrastructure
- Over-engineering for hypothetical future scale

---

### 3. Feature-Based Flutter Structure

Flutter code should be organized by feature.

Expected major features:

- auth
- location
- recommendation
- restaurants
- map
- tracking
- food_scan
- profile

Separate:

- UI
- state
- models
- repositories
- services

---

## Core Firestore Data

Initial main collections:

- users
- restaurants
- menu_items
- meal_logs

### users

Stores user profile and application preferences.

Possible fields:

- displayName
- age
- gender
- height
- weight
- activityLevel
- targetCalories
- preferences
- createdAt
- updatedAt

### restaurants

Stores MueNee restaurant records.

Possible fields:

- name
- googlePlaceId
- latitude
- longitude
- address
- rating
- imageUrl
- verificationStatus
- updatedAt

### menu_items

Stores MueNee menu data.

Possible fields:

- restaurantId
- name
- price
- calories
- protein
- carbs
- fat
- tags
- imageUrl
- priceConfidence
- verifiedAt

### meal_logs

Stores meals selected or scanned by users.

Possible fields:

- userId
- menuId
- restaurantId
- source
- foodName
- calories
- protein
- carbs
- fat
- imageUrl
- createdAt

Possible source values:

- recommendation
- food_scan
- manual

---

## Seed Data

Initial restaurant and menu data should also exist in version-controlled source files.

Suggested structure:

data/
├── restaurants.json
└── menus.json

Use scripts to validate and seed this data into Firestore.

---

## Recommendation MVP

The MVP recommendation system should be deterministic.

Possible factors:

- Budget
- Food preference
- Nutrition
- Distance
- Price confidence

Return:

Top 3 menu recommendations

Do not depend on Gemini for the core recommendation ranking unless explicitly requested.

---

## Product Constraints

- Initial dataset is small
- Real restaurant data should be verifiable
- Price and nutrition data may include confidence or verification status
- User-facing AI nutrition estimates must be editable
- Secrets must not be committed to GitHub

---

## Current Development Priority

Development order:

1. Project structure
2. Flutter foundation
3. Firebase connection
4. Authentication
5. Firestore models and schema
6. Seed restaurant/menu data
7. Location
8. Budget input
9. Food preferences
10. Recommendation engine
11. Restaurant detail
12. Google Maps
13. Meal selection
14. Daily Tracking
15. AI Food Scan
16. Crashlytics / Analytics / polish

Do not skip directly to advanced features before the foundation is stable.

## Approved Food Settings and Price UX (2026-09-05)

After Phase 1 build validation, the user requested the missing food-preference
and price-confidence UX. This scoped addition does not authorize the remaining
Firebase, authentication, location, or full recommendation implementation.

- Food settings distinguish hard exclusions, soft dislikes, and allergies.
- Hard exclusions: no pork, no beef, vegetarian (eggs/dairy allowed), halal only.
- Halal requires explicit confirmation; absence of pork is not confirmation.
- Dislikes move eligible menus to the end; an optional switch hides them.
- Supported allergy options: peanut, tree nuts, milk, egg, soy, wheat, fish,
  shellfish, and sesame. Allergies exclude matching or incomplete allergen data.
- Missing evidence must not be treated as confirmation that a restriction is met.
- Settings persist on this device as local preferences; they are not a new
  application database or a substitute for the planned Firestore user profile.
- Price UX distinguishes verified, estimated, and unverified prices. For this
  local MVP policy, verified requires a source and a non-future verification
  timestamp within 30 days. Older or incomplete verification becomes unverified.
- Price source and last verification date are visible. No production price
  verification workflow exists yet; trusted writes will be required with Firebase.
- Preview menus and all their prices, dates, and dietary evidence are fictional
  fixtures, clearly labeled in the UI. They are not real restaurant seed data.

See [food settings and price UX](docs/food-settings-and-price-ux.md) for behavior,
implementation boundaries, and validation.

## Approved Profile Settings UX (2026-09-05)

Phase 1 now includes a device-local profile form at `/profile-settings` for the
requested age, height, weight, and activity level inputs. It uses a versioned
`muenee.user_profile.v1` JSON document through `SharedPreferencesAsync` and
Riverpod. The form requires all four values when saving, while a new install
starts empty and does not force setup.

These fields are input data for future deterministic recommendation work. They
do not calculate calories, BMI, nutrition, or medical advice yet, and they are
not synced to Firebase. The existing food restrictions, allergies, dislikes,
and price-confidence UX remain unchanged.

The current visual baseline is Flutter Material 3 with a MueNee food-focused
palette: warm white, coral-red, orange, and yellow. The direction is inspired by
the attached Airbnb DESIGN.md reference while keeping MueNee's own identity.
shadcn.io may be used as a web design reference, but its React/web component
code must be translated into Flutter widgets and theme tokens. See
[MueNee design direction](DESIGN.md), [profile settings](docs/profile-settings.md)
and [ADR 0003](docs/architecture/adr/0003-local-user-profile.md).

## Phase 1 Completion (2026-09-05)

Phase 1 is complete. Flutter analyze, 25 automated tests, the universal Android
debug build, APK metadata/signature checks, and an Android 16 / API 36 emulator
smoke test passed. The emulator run covered launch, visual review, profile and
food-preference persistence after force-stop/relaunch, filtered fictional menu
preview, and price-confidence evidence. The status bar was corrected to use
dark icons on the warm light canvas during visual QA.

At the Phase 1 checkpoint, no Firebase connection, authentication, Firestore
schema, location, maps, production restaurant data, recommendation ranking,
tracking, or AI Food Scan work had started. Phase 2 was subsequently authorized
and is recorded below.

## Phase 2 Firebase Connection (authorized 2026-09-06)

The user authorized Phase 2 and selected Firebase project `muenee-pj`.
The Android app `com.muenee.app` is registered as `MueNee Android` with Firebase
App ID `1:229088552669:android:a2dc1af6116c797030dd34`.

Phase 2 implements development-priority item 3: Firebase connection. It adds
Firebase Core, Cloud Firestore dependency injection, App Check initialization,
visible startup failure/retry, ignored local build configuration, and isolated
Firestore/Storage Emulator rules tests. Live mode requires the actual client
configuration; debug emulator mode always uses `demo-muenee-pj`. Firestore and
Storage rules deny all access until account/schema-specific rules are added.

The live Android client configuration is now validated and stored only in
ignored local files. Cloud Firestore `(default)` is provisioned as Standard/
Native in Singapore (`asia-southeast1`) with delete protection enabled, and the
deny-all Firestore rules plus empty indexes are deployed. A guarded deployment
script refuses any live database outside that location. A read-only live REST
probe received the expected `PERMISSION_DENIED`, and a normal live-config APK
reached the existing home screen without a Firebase startup error. No live
document write was attempted. App Check enforcement remains off until Play
Integrity attestation is verified on a suitable device.

Profile and food settings remain device-local; no data migration, authentication
UI, application collections, real restaurant data, location, maps, ranking,
tracking, uploads, or AI/Cloud Functions have been implemented.

The Phase 1 baseline rerun contained 25 tests (the earlier documentation's 26
count was incorrect). The connection-layer additions bring the Flutter suite
to 35 passing tests; Android and server verification are recorded separately in
[Phase 2 setup and validation](docs/phase-2-firebase.md). The document separates
SDK startup, emulator coverage, deployed live rules, and the read-only live
backend probe so none is overstated as proof of another layer.

See [ADR 0004](docs/architecture/adr/0004-firebase-connection.md). Authentication
remains development-priority item 4 after the connection acceptance checks.

## Phase 3 Authentication (authorized 2026-09-06)

Email/password authentication is implemented at `/account`, reachable from the
home account icon. It includes registration, sign-in, password reset, explicit
verification email, verification reload and sign-out, with Riverpod state and
Firebase SDK session persistence. Local preferences remain shared device data.
Live provider enablement and account acceptance are complete for Phase 3. See
docs/phase-3-auth.md and ADR 0005.

The Phase 3 UI/UX continuation fixed form email preservation, sign-out routing,
keyboard actions, multiline validation, and missing-session error handling.
Text-bearing buttons/actions use the existing darker coral for improved contrast.
Flutter analyze and 45 Flutter tests pass, including 320 x 640 at 200% text scale.
One native Android/API 36 integration test passed against isolated Auth Emulator:
registration, verification, reset, old-password rejection, new-password sign-in,
and test-account cleanup. Debug HTTP is restricted to local emulator hosts.
Live Email/Password is enabled after explicit action-time approval; email-link
sign-in remains disabled. The authorized test account was created and live
create/sign-out/password-sign-in succeeded. Firebase accepted verification and
password-reset email requests, and the user confirmed completing both mailbox
links. Android process-restart session persistence passed with app data retained;
the generated emulator account was deleted afterward.
Phase 3 authentication acceptance is complete.
Phase 4 was subsequently authorized and is recorded below.

## Phase 4 Firestore Models and Schema (authorized 2026-09-06)

Development-priority item 5 defines version 1 typed models for `users`,
`restaurants`, `menu_items`, and `meal_logs`, with explicit Firestore timestamp,
enum, GeoPoint, nested nutrition, price-evidence, and dietary-evidence
serialization. Query contracts were designed first and the required composite
indexes are checked in.

Firestore rules allow public reads only for active restaurant/menu catalog
documents and deny all catalog writes from mobile clients. User documents and
meal logs are accessible only to the matching authenticated owner, with strict
field/value validation and immutable ownership/creation fields. Storage remains
deny-all because uploads are outside this phase.

Device-local profile and food settings are not silently migrated or overwritten;
the remote user model preserves their version 1 contracts for a future explicit
sync decision. No real seed data, location, recommendation, tracking UI, upload,
or AI feature is part of Phase 4. See `docs/phase-4-firestore-schema.md` and ADR
0006.

Flutter analyze, 51 Flutter tests, and five Emulator rules test groups pass. A
read-only pre-deployment probe confirmed the live Phase 2 deny-all baseline with
HTTP 403 and no write attempt. After explicit user approval, the guarded deploy
verified `muenee-pj` Firestore Native `(default)` in `asia-southeast1`, compiled
and released the Phase 4 rules, and deployed the two indexes then defined. No
Firestore document was created or changed. Phase 4 acceptance is complete.

## Phase 5 Seed Restaurant/Menu Data (authorized 2026-09-06)

Development-priority item 6 is implemented in version-controlled source files:
10 real restaurants around Silpakorn University, Sanam Chandra Campus, and 30
menu items (three per restaurant). Restaurant records include Google Place IDs,
coordinates, address/rating snapshots, provenance URL, and check time. Menu
records preserve the Phase 4 price, nutrition, and conservative dietary-evidence
contracts. All nutrition values are generic estimates. Unknown recipes and
cross-contact evidence remain unknown; no menu is inferred halal or vegetarian.

The validator enforces counts, foreign keys, unique IDs/Place IDs, the 3 km MVP
area, enums/ranges, HTTPS sources, timestamps, and the verified-price policy.
Dry-run makes no connection. The trusted seed path uses an atomic create-only
batch: it never updates or deletes, refuses the entire seed when any target path
already exists, and reads all created documents back. The Firestore Emulator
created and verified all 40 documents, and a repeated seed was safely refused.
Flutter analyze, all 51 Flutter tests, and all five existing Firestore/Storage
Emulator rules groups also pass.

After explicit action-time confirmation, Google Cloud CLI and user Application
Default Credentials were configured without a service-account key. The guarded
production seed rechecked `muenee-pj`, Firestore Native `(default)`, and
`asia-southeast1`, then atomically created and read back all 40 target documents.
No document was updated or deleted. Phase 5 acceptance is complete. Location
was subsequently authorized and is recorded below. See
`docs/phase-5-seed-data.md` and ADR 0007.

The first live public-client query revealed that active restaurants ordered by
name require a composite `isActive`/`name` index. The earlier Phase 4 assumption
that automatic single-field indexes covered this query was incorrect. The index
contract and documentation were corrected during Phase 5 and the guarded index
deployment was rerun. After the index reached `READY`, unauthenticated live
client queries read exactly the 10 active restaurants and 30 active menus in the
version-controlled seed.

## Phase 6 Location (authorized 2026-09-06)

Development-priority item 7 adds a user-initiated Android current-location flow
at `/location` using the approved `geolocator` package. The app explains its
purpose before requesting permission and handles approximate/precise access,
disabled services, retryable and permanent denial, timeouts, and unexpected
failures with explicit recovery actions.

Only foreground coarse/fine Android permissions are declared. A single current
fix is held in Riverpod process memory and is not persisted, written to
Firestore, displayed as raw coordinates, or tracked in the background. Budget
input, distance calculation, recommendation ranking, Places, and Maps remain
outside Phase 6. See `docs/phase-6-location.md` and ADR 0008.

Flutter analyze, 59 Flutter tests, an x86_64 debug APK build, APK permission
inspection, and an Android 16 / API 36 native smoke test pass. Native acceptance
confirmed that the system prompt appears only after the user action, the
timeout/retry state recovers, and a mock current fix reaches the precise-ready
state without exposing coordinates. Phase 6 acceptance is complete. Budget
input was subsequently authorized and is recorded below.

## Phase 7 Budget Input (authorized 2026-09-07)

The non-visual budget foundation defines a validated whole-baht `MealBudget`
from 1 through 10,000 and a Riverpod controller that holds the last confirmed
value in process memory. Parsing accepts plain digits, valid comma grouping,
and Thai digits while returning distinct empty, format, minimum, and maximum
errors. Invalid input does not overwrite an earlier valid budget.

No value is persisted locally or written to Firebase. The user subsequently
authorized the deferred UI/UX: `/budget` now offers quick amounts, custom Thai
input, inline errors, explicit confirmation, and unsaved-edit protection. It is
reachable from the home wallet action and ready Location state. Food-preference
flow integration and recommendation logic remain outside this work. See
`docs/phase-7-budget.md` and ADR 0009.

Flutter analyze and all 65 Flutter tests pass, including six new tests for the
budget parser, invariant, and Riverpod state. No Android build is claimed for
this initial non-visual increment. Subsequent UI validation is recorded in the
Phase 7 document.

Phase 7 UI acceptance subsequently passed: analyzer clean, all 69 Flutter tests
passing, debug x64 APK built, and API 36 emulator wallet-to-budget selection
and confirmation smoke-tested. The confirmed 80-baht screen was visually
inspected. No live Firebase data changed; Phase 8 was subsequently authorized.

## Phase 8 Food Preferences (authorized 2026-09-07)

Development-priority item 9 connects the existing device-local food preference
contract to the meal flow after a confirmed budget. The same hard restrictions,
conservative allergy handling, soft dislikes, and optional hide-disliked rule
remain in force. Meal-flow mode requires explicit confirmation even when the
saved selection is empty and shows a clear ready state after successful save.

The budget continuation is unavailable while its visible draft differs from the
confirmed value. Phase 8 does not migrate local settings, write Firebase data,
calculate nutrition, or implement recommendation ranking. See
`docs/phase-8-food-preferences.md` and updated ADR 0002.

Phase 8 acceptance passed with a clean analyzer and all 72 Flutter tests. The
x86_64 debug APK built and passed v2 signature verification. An Android 16 /
API 36 native smoke test retained existing app data, confirmed an 80-baht
budget, entered meal-flow food settings, and explicitly confirmed the current
selection. Visual inspection and process logs found no blocking layout issue,
fatal exception, ANR, Flutter error, or unhandled exception. No Firebase state
changed. Phase 9 recommendation work was subsequently authorized.

## Phase 9 Recommendation Engine (authorized 2026-09-08)

Development-priority item 10 adds a deterministic, client-side Top 3 engine.
The app reads bounded active restaurant/menu candidate sets from Firestore,
strictly filters budget, inactive/orphaned data, dietary restrictions, and
allergies, then ranks eligible menus by distance, affordability, current price
confidence, and soft dislikes. Disliked eligible menus always remain behind
other eligible menus, regardless of their score. Stable tie-breakers make the
result repeatable.

The result screen handles missing inputs, loading, retryable failures, strict
empty results, and pull-to-refresh. Cards expose price confidence, distance,
and estimated calories/protein without presenting nutrition as a health score.
No Gemini, Firestore write, rule/index deployment, restaurant detail, Maps,
meal selection, or tracking is included. See `docs/phase-9-recommendations.md`
and ADR 0010.

Phase 9 acceptance passed on 2026-09-08: analyzer clean, all 85 Flutter tests,
x86_64 debug APK build and v2 signature check. Public read-only verification
confirmed 10 active restaurants and 30 active menus in `muenee-pj`. An API 36
native smoke run used a simulated campus location and 100-baht budget; the
final Top 3 showed three distinct restaurants with price-confidence and
nutrition-estimate labels. Final top/bottom screenshots were inspected.
Within each preference tier, selection favors distinct restaurants before
repeats. Catalog reads require the server, time out after 20 seconds, and fail
visibly if the 50-restaurant/100-menu bound is exceeded. No live data changed.
Phase 10 restaurant detail remains unstarted.

## Existing-screen UI refresh — 2026-09-08

The first approved Design v2 implementation refreshes Home, Budget, food
preferences, recommendation cards/explanation, shared card geometry, account
and location copy, and the Android splash. Existing filtering, local persistence,
authentication, and recommendation ranking remain unchanged. Analyzer and all
86 Flutter tests pass; the updated x86_64 debug APK builds successfully.
See `docs/ui-refresh.md` for scope, evidence, and outstanding design work.
This is an existing-screen increment, not the start of Phase 10. No live
Firebase writes, rules/index deployment, or analytics were performed.

## Phase 10 Restaurant Detail (authorized 2026-09-08)

Top 3 recommendation cards now open a dedicated restaurant/menu detail route.
The screen preserves the selected recommendation snapshot and shows the menu,
restaurant, address, approximate straight-line distance, effective price status
and evidence, estimated nutrition, catalog verification recency, and incomplete
ingredient/allergen evidence without inventing ratings freshness or opening
hours. Missing/broken catalog images use a labelled illustration.

The detail route performs no additional Firestore read or write and fails safely
when opened without a selected recommendation snapshot. Android Back returns to
the existing recommendation page. Maps, ordering, meal selection, tracking,
Gemini, and monitoring remain unstarted. See
`docs/phase-10-restaurant-detail.md` and ADR 0011.

Phase 10 Flutter acceptance passed on 2026-09-08: analyzer clean and all 91
Flutter tests passed, including navigation/back, evidence, incomplete dietary
metadata, safe direct-route recovery, and 320x640 at 200% text. Native build and
visual evidence are tracked separately and must pass before Phase 10 is called
fully complete. No live Firebase data, rules, indexes, or account state changed.

## Phase 11 Google Maps (authorized 2026-09-09)

Implementation adds a nested restaurant map route, Google Maps Android plugin,
restaurant/search-fix markers, recenter/reload controls, and missing-config
recovery with the address still accessible. The existing selected restaurant
snapshot supplies coordinates, without additional Firestore reads or location
permission requests. Build configuration loads an ignored maps.local.json file.

Phase 11 was accepted on 2026-10-05 after creating a dedicated Android Maps key
restricted to com.muenee.app, the checkout debug certificate, and Maps SDK for
Android. The value is kept only in ignored config/maps.local.json; the Firebase
Auth key was not modified. Analyzer and all 123 Flutter tests passed, the
x86_64 debug APK was built and v2-verified, and the local Android API 36 AVD
smoke flow reached the restaurant map with real Google street tiles and a
restaurant marker. Evidence is recorded in docs/phase-11-google-maps.md and
artifacts/phase-11-map.png. A release-certificate restriction and release APK
smoke test remain required before publishing.
## Phase 12 Meal Selection (authorized 2026-09-10)

The restaurant detail screen now has a persistent meal-selection action. Signed-
out users are directed to the existing account screen. Signed-in users review a
confirmation sheet that identifies the menu, restaurant and estimated calories,
and explicitly states that the action records a meal rather than placing or
paying for an order.

After confirmation, the app creates one owner-scoped `meal_logs` document with
`source: recommendation`, the selected menu/restaurant IDs, the catalog nutrition
estimate and a Firestore server timestamp. Riverpod exposes saving, success and
retryable failure states and prevents a second tap from duplicating the same
selection while the detail screen remains open. Existing Phase 4 rules already
cover this schema, so no live rules or index deployment was needed.

Phase 12 acceptance passed with a clean analyzer, all 94 Flutter tests, five
Firestore/Storage Rules groups, an Android API 36 test against isolated Auth and
Firestore Emulators, and a signed x86_64 debug APK. The native test creates and
removes only its own emulator account and meal log. No document was written to
live `muenee-pj`. See `docs/phase-12-meal-selection.md` and ADR 0012. Phase 13
Daily Tracking has not started. Phase 11 still awaits its restricted Maps key
and real-tile acceptance.

## Phase 13 Daily Tracking (authorized 2026-09-10)

The authenticated `/tracking` screen now reads owner-only `meal_logs` for one
local calendar day at a time. Users can move backward through earlier dates and
forward only as far as today. The query converts the selected device-local day
boundaries to UTC, filters the signed-in UID, orders newest first, limits the
result to 50, ignores cache-only snapshots, and exposes a retryable timeout or
server error rather than presenting an offline empty cache as current data.

The screen shows meal count, approximate calorie/protein/carbohydrate/fat totals,
individual meal time/source and nutrition, with neutral wording that these are
estimates rather than goals or medical advice. Signed-out, session, loading,
empty, failure and refresh states are explicit. A two-destination bottom bar now
links the working “มื้อนี้” and “บันทึก” surfaces; Scan stays hidden until Phase
14. Phase 12 success also links directly to today's log.

Phase 13 acceptance passed with a clean analyzer, all 100 Flutter tests, five
Firestore/Storage Rules groups, an Android API 36 Auth/Firestore Emulator flow,
and visual inspection of the captured Daily Tracking screen. The live-config
x86_64 debug APK built and verified with APK Signature Scheme v2. Emulator data
was created and removed only inside `demo-muenee-pj`; no live document, rule or
index changed. See `docs/phase-13-daily-tracking.md` and ADR 0013. Phase 14 AI
Food Scan has not started, and Phase 11 still awaits live Maps acceptance.

## Phase 14 AI Food Scan (authorized 2026-09-10)

The authenticated `/food-scan` flow now takes or selects one image, keeps its
bytes in memory, and sends it inline to Gemini through Firebase AI Logic only
after the user explicitly requests analysis. The model response is constrained
to structured JSON and decoded into a Thai food name, estimated calories,
protein, carbohydrate, fat, and a portion-assumption note. Unsupported images,
non-food results, malformed fields and values outside the existing nutrition
schema fail visibly without creating a meal.

Every estimated field is editable. Selecting an image and completing AI analysis
both leave Firestore untouched; only “ยืนยันและบันทึกมื้อนี้” calls the owner-
scoped repository. That write uses `source: food_scan`, the edited values and a
server timestamp, and deliberately has no retained `imageUrl`. The UI discloses
that the image is sent to the AI service and not stored by MueNee. The working
bottom navigation now exposes “มื้อนี้ / บันทึก / สแกน”; “ฉัน” remains hidden
until it becomes a complete destination.

Local acceptance passed a clean analyzer, all 109 Flutter tests, five Rules
Emulator groups, and an Android API 36 Auth/Firestore Emulator flow that proved
zero pre-confirmation writes and one cleaned-up owner `food_scan` write after an
edited confirmation. No live `muenee-pj` model request, document write, service
enablement, rules/index deployment or Storage upload occurred. Phase 14 live AI
acceptance remains pending Firebase AI Logic/Gemini provisioning, billing/quota
review and an authorized real-device request. See
`docs/phase-14-ai-food-scan.md` and ADR 0014. Phase 15 was subsequently
authorized and is recorded below; Phase 11 still separately awaits
restricted-key real-map acceptance.

## Coral Companion visual refresh (2026-09-27)

The user authorized a whole-app visual and interaction refresh, not a new
numbered phase. The existing Phase 1–15 business rules and service-acceptance
boundaries remain in force. The brand uses a shared coral/cream design system,
Prompt and Noto Sans Thai fonts, and a consistent fork/spoon/smile mark across
the launcher, splash, and in-app header. Home now foregrounds “มื้อนี้กินอะไรดี?”,
budget shortcuts, location, and the existing confirmed recommendation flow.
Budget shortcuts remain drafts until explicit confirmation. See `DESIGN.md` and
`docs/coral-companion-redesign.md` for visual scope and validation evidence.

## Phase 15 Crashlytics / Analytics / polish (authorized 2026-09-12)

Phase 15 adds Firebase Analytics and Crashlytics behind a privacy-first
`TelemetryService` boundary. Android native collection defaults to disabled and
the isolated `demo-muenee-pj` path always uses a no-op service. Two independent,
versioned device-local choices control usage Analytics and crash diagnostics;
opening the app or signing in is never treated as consent. Guests can review,
save and reverse both choices at `/privacy-settings` from Home. Invalid local
settings fail visibly instead of being interpreted as opt-in.

Analytics uses stable named routes and six parameter-free allowlisted events:
meal-flow start, budget confirmation, food-preference confirmation,
recommendation meal recording, completed food-scan analysis and food-scan meal
recording. MueNee adds no coordinates/address, budget value, dietary setting,
nutrition, food/image content, email, Firebase UID, user property or free text.
Expected monitored failures use fixed codes rather than original exception
messages. Crash reporting can include ordinary device/app/stack diagnostics,
which the UI explains, but MueNee attaches no custom user or food/location data.

Live-config Android builds conditionally apply Google Services and Crashlytics
Gradle plugins and require the validated ignored
`android/app/google-services.json`. Emulator builds skip those plugins to
preserve explicit demo-project initialization. Successful confirmations use a
light platform haptic; shared short motion tokens include an immediate
reduced-motion path. The new screen is scrollable at 320x640 and 200% text.

Local acceptance passed a clean analyzer, all 117 Flutter tests, an Android 16 /
API 36 reversible preference-persistence flow, screenshot inspection, a
live-config x86_64 APK build, APK v2 signature verification and packaged-manifest
inspection proving both collection defaults are false. The APK is 127,853,870
bytes with SHA-256
`A168327F2BFB23BDDD4CA09E74F3FCB3974C5AEA8204EA9B5C42C03C31C28F02`.
See `docs/phase-15-monitoring-and-polish.md` and ADR 0015.

No live Analytics setting, event, Crashlytics report, forced crash, Firestore
write, rules/index deployment or Firebase integration toggle has been
performed. Live monitoring acceptance requires separate approval and Firebase
Console verification. Representative student evaluation remains planned
research, not a completed result. Phase 11 still separately awaits
restricted-key real-map acceptance.

## Campus Pop selection and logo refinement (2026-10-03)

The user selected design proposal 02 Campus Pop, then requested correcting
the fork/spoon/smile logo first. This increment replaces the uneven five-tine,
off-center mark with deterministic four-tine vector geometry. The canonical
SVG generates the in-app painter, Android launcher/splash vectors and legacy
PNG icons; original affected brand files are preserved under
`artifacts/brand-refinement/2026-10-03/before/`.

The first Campus Pop screen pass is now implemented: shared cream/coral/butter-
yellow/lilac tokens, a budget-and-preference-led Home with a deterministic food
doodle, a featured first Top 3 recommendation with compact comparison cards,
and editable 2×2 nutrition tiles
in Food Scan review. Unverified catalog photos remain clearly labeled as
illustrations. Existing budget confirmation, preference/allergy filtering,
recommendation ranking, scan review-before-save, privacy and phase contracts
are unchanged. This is an existing-screen UI increment, not a new numbered
phase. The rest of the app still needs its visual pass. Analyzer and all 123
Flutter tests pass, but emulator acceptance is pending: ADB in the current
Windows runner returns `Cannot mkdir '\\.android': Permission denied` because
it cannot resolve the Windows profile directory. Per the user's request, no
APK was generated. See
`DESIGN.md`, `docs/design-proposals/2026-10-03/README.md`, and
`docs/brand-refinement-2026-10-03.md`.
