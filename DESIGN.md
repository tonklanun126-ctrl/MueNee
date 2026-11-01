---
version: 2
name: MueNee
status: approved-campus-pop-first-screen-pass-in-progress
reference: Campus Pop; Uiverse interactions; NameThatUI patterns
platform: Flutter Android
---

# MueNee design direction

MueNee is a friendly, photo-led food marketplace. The interface should make a
meal feel inviting while helping a user decide quickly. The visual direction
takes the restraint, soft geometry, generous whitespace, and card-first rhythm
from the attached Airbnb reference, then gives MueNee its own food-focused
palette and Thai-friendly typography.

This file is a project design contract for Flutter. It is not a copy of
Airbnb's brand assets, logos, proprietary typeface, or web components.

## Design principles

- Make the next meal the visual focus.
- Use one warm primary action at a time.
- Let food photography carry visual weight; keep type calm and readable.
- Keep filters and preference states easy to scan and undo.
- Show evidence and uncertainty clearly for price and nutrition data.
- Design for one-handed mobile use and large text settings first.

## Color tokens

| Token | Value | Use |
| --- | --- | --- |
| `primary` | `#FF385C` | Brand accents, active controls, selected states |
| `primaryActive` | `#E00B41` | Filled CTA backgrounds, text actions and focused labels |
| `primarySoft` | `#FFE5EA` | Selected backgrounds and soft highlights |
| `secondary` | `#F97316` | Secondary actions and food-energy accent |
| `secondarySoft` | `#FFE8D5` | Secondary selected backgrounds |
| `accent` | `#F4B400` | Warm accent, attention, ratings |
| `accentSoft` | `#FFF0BF` | Accent background |
| `canvas` | `#FFFBF8` | App background, warm white |
| `surface` | `#FFFFFF` | Cards, fields, sheets |
| `ink` | `#242424` | Headings and primary text |
| `body` | `#4B4B4B` | Running text |
| `muted` | `#6B6B6B` | Supporting text and metadata |
| `hairline` | `#E4E4E7` | Borders and dividers |
| `success` | `#2E7D32` | Existing MueNee green for confirmed/complete state only |
| `warning` | `#B45309` | Caution and incomplete evidence |
| `error` | `#C13515` | Validation and failure state |

Coral is the MueNee primary color and is inspired by the requested Airbnb-like
food energy. Orange and yellow support hierarchy; they do not compete with the
primary CTA. Green remains a semantic status color rather than a brand color.

Use the darker coral for readable text interactions: white on `primaryActive`
has contrast 4.89:1, versus 3.52:1 on the brighter brand coral. Dark coral text
on the warm canvas has contrast 4.75:1. Keep bright coral for non-text accents.

## Typography

Use the Android platform sans fallback so Thai text renders correctly. If a
font is bundled later, prefer a Thai-capable family such as Noto Sans Thai for
body and headings. Do not bundle Airbnb Cereal or another restricted brand font.

| Role | Size | Weight | Use |
| --- | ---: | ---: | --- |
| Display | 28px | 700 | Screen headline and hero message |
| Section title | 20–22px | 600 | Group headings and menu section titles |
| Title | 16px | 600 | Cards, buttons, selected labels |
| Body | 16px | 400 | Explanations and form copy |
| Metadata | 14px | 400 | Distance, dates, price evidence |
| Caption | 12–13px | 500 | Badges and supporting labels |

Line height should stay generous for Thai text. Do not rely on uppercase-only
labels for meaning.

## Shape, spacing, and elevation

- Use a 4px base grid: 4, 8, 12, 16, 24, 32, 48px.
- Text fields and standard buttons use a 10–12px radius.
- Existing cards use a 14px radius; redesigned result cards use 20px and hero
  panels/sheets use 24px. Standard form cards can retain 14px.
- Chips and compact icon controls use a full pill/circle radius.
- Primary touch targets are at least 48×48px, including icon hit areas.
- Keep most surfaces flat; use one subtle border/shadow treatment for cards and
  floating controls.
- Prefer 16px page padding on compact screens and 24px section spacing.

## Component mapping

| MueNee surface | Direction |
| --- | --- |
| Home recommendation | Warm canvas, short headline, one coral CTA, search/filter entry |
| Menu card | Food thumbnail, rounded 20px surface, name, price, distance, confidence tag |
| Food settings | Grouped cards/sections, coral selected chips, clear reset/save action |
| Profile settings | White fields on warm canvas, visible units, one clear save CTA |
| Price confidence | Green only for verified, amber/orange for estimated, muted for unverified |
| Empty/error state | Friendly copy, one recovery action, no decorative overload |

## Mobile behavior

- Stack cards one-up below 744px.
- Keep the primary action reachable near the bottom without covering content.
- Use scrollable forms and preserve a 48px touch target through 2× text scale.
- Use bottom sheets for evidence/details instead of desktop side rails.
- Keep the navigation simple; location, recommendation, settings, and tracking
  should be reachable without a desktop-style product nav.

## Accessibility and content

- Check foreground/background contrast for every semantic color combination.
- Never use color alone to communicate halal, allergy, or price confidence;
  pair color with text and an icon.
- Keep validation text next to the field and preserve focus after an error.
- Use Thai labels with familiar units (`ปี`, `ซม.`, `กก.`, `บาท`).
- Keep fictional preview data clearly labeled until real verified data exists.

## Implemented baseline through Phase 9

This section records the existing implementation. The approved version 2
specification below supersedes its visual choices as screens are updated;
approval of the specification is not evidence that those updates have shipped.

Phase 3 extends this visual direction to the optional account screen: a soft
coral welcome panel, readable stacked email/password fields, one primary action,
inline status feedback, and scrollable forms. Authentication behavior and
validation are documented in docs/phase-3-auth.md.

The original Phase 1 contract covered the foundation, profile settings, food
preferences, and fictional menu/price preview. Subsequent implementation
milestones are recorded here and in PROJECT_CONTEXT.md.

Phase 6 extends the same system to the current-location step: one coral primary
action, a soft-coral purpose panel, status cards that pair icons with text, and
explicit recovery actions. Exact coordinates stay hidden from the consumer UI;
the screen shows useful accuracy and approximate/precise context instead.

Phase 7 uses a warm-coral amount panel with prominent numerals and explicit baht
units, wrapping quick-budget chips, and one confirmation action. Saved budget
feedback is distinct from the editable draft. All content remains scrollable
with large Thai text and keyboard insets. Leaving a changed draft requires an
explicit discard choice.

Phase 8 reuses the full food-settings surface instead of creating a duplicate
form. A coral-soft context panel explains strict filtering, the bottom action
requires explicit confirmation for the current meal, and a green semantic card
appears only after confirmation. It does not display a step count because the
budget shortcut can be used before location.

Phase 9 recommendation cards keep rank, meal, restaurant, and price in a clear
top hierarchy. Evidence is grouped in wrapping pills so 200% Thai text remains
readable on compact screens. Price confidence uses semantic color plus text;
empty and error states always include recovery actions. Cards are intentionally
non-interactive until restaurant detail is authorized.

## Approved redesign: Warm Campus Energy (2026-09-08)

The user approved the full UI/UX proposal and its documentation in this file.
This is the implementation specification for the redesign, with implementation
pending. PROJECT_CONTEXT.md remains the primary authority for product scope,
architecture, data policy, and feature readiness. No PROJECT.md was present at
the time of the audit. Future feature designs are implemented with their
corresponding product phases rather than exposing unfinished destinations.

### Product intent and audience

Help people around Silpakorn University, Sanam Chandra Campus, choose a nearby
meal quickly within their budget and food constraints. Students and younger
users are the design focus of this refresh; specific behavioral assumptions
must be validated with users rather than treated as established research.

The experience should feel warm, appetizing, lively, and dependable. Preserve
the existing coral/orange/warm-white identity and express personality through
food imagery, useful feedback, concise Thai language, and clear hierarchy.
The small initial catalog favors a focused Top 3 experience over a large feed,
endless carousels, or elaborate discovery navigation.

### Reference interpretation

| Reference | Adopt for MueNee | Translation and limits |
| --- | --- | --- |
| [Uiverse](https://uiverse.io/) | Distinct control states, tactile buttons, expressive selection feedback, purposeful loading and transitions | Build native Flutter widgets using shared tokens; avoid mixing unrelated component styles or copying web code |
| [Uiverse motion guidance](https://uiverse.io/blog/the-future-of-motion-ui-5-inspiring-techniques-you-should-use-now) | Short motion that confirms an action or connects two states | Support reduced motion; avoid continuous decorative animation, hover-only behavior, neon/glow overload, and heavy 3D effects |
| [NameThatUI](https://namethatui.com/) | Choose components by their purpose and use consistent names across design and code | Translate behavior and accessibility into Flutter rather than importing desktop/macOS or web conventions |
| [Badge, Chip, Pill, Tag](https://namethatui.com/web/badge-chip-pill) | Visually distinguish interactive selections from read-only metadata | Filters are interactive chips; price status and nutrition facts are read-only tags/text |
| [Dialog, Drawer, Sheet](https://namethatui.com/web/dialog-drawer-sheet) | Bottom sheets for compact contextual details; dialogs for focused decisions | Evidence sheets have a visible close action, accessible focus handling, and scrollable content |
| [Skeleton and Spinner](https://namethatui.com/web/skeleton-spinner) | Skeletons for known result layouts; spinner for indeterminate location lookup | Replace either with success/error promptly; never fake progress or imply results already exist |
| [Accordion](https://namethatui.com/web/accordion) | Progressive disclosure for secondary preferences | Keep selected values visible in collapsed summaries; safety sections stay expanded |
| [Empty State](https://namethatui.com/web/empty-state) | Explain missing content and offer a useful recovery action | Distinguish no matching menus from network failure; preserve hard filters |

### Visual system evolution

- Retain the color tokens above. Use coralActive for filled text buttons and
  readable text actions; use brighter coral for decorative emphasis.
- Restrict coral-to-orange gradients to a small hero accent or illustration.
  Put text on a solid readable surface unless the entire gradient contrast is
  verified. Green remains a confirmed-status color.
- Use white cards on warm canvas, restrained borders, and at most one subtle
  elevation treatment. Avoid giving every fact a colored container.
- Keep 16px compact-screen gutters, the 4px spacing grid, and generous Thai
  line height. Typography values are logical Flutter sizes, not device pixels.
- Prefer Noto Sans Thai when a font is bundled, including its license and a
  working fallback. Current Android fallback remains valid until then.
- Develop a consistent spoon/fork/smile motif for empty states and small brand
  illustrations. Treat the Thai nickname “มูนี่” as proposed display copy;
  retain MueNee as the established product name.
- Use real, correctly associated food photos with permitted use and recorded
  provenance. If unavailable, show a local category illustration clearly
  labeled “ภาพประกอบ”; never pass a generated or unrelated stock image off as
  the actual dish. Missing/broken images must preserve card geometry.

### Shared meal context and navigation

Show a compact, wrapping context strip for location, confirmed budget, and
confirmed food preferences. Each item opens its existing editor and states
whether it is ready, missing, or requires confirmation. For example:

`ตำแหน่งพร้อมแล้ว ✓ · งบ 100 บาท ✓ · อาหารที่กินได้: ยืนยันแล้ว ✓`

Derive the strip from existing application state, never a separate completion
counter. An empty saved preference selection still requires explicit meal-flow
confirmation. Draft changes must not be presented as confirmed inputs.

Do not use a numbered linear stepper: the budget shortcut permits a different
entry order. Route the primary CTA to the earliest missing prerequisite, then
to Top 3 when all prerequisites are valid. Preserve drafts, back navigation,
unsaved-edit protection, and the current persistence boundaries.

### Home

Replace the centered launcher layout with a purposeful meal-start surface:

1. Compact MueNee header and account/settings entry.
2. Location/status pill. Show a human-readable area only when supported by
   available data; otherwise use “ตำแหน่งพร้อมแล้ว”. Never infer an address
   from a raw fix or expose coordinates.
3. Headline “มื้อนี้ให้ MueNee ช่วยเลือก” and short support text:
   “บอกงบและสิ่งที่กินได้ แล้วเราจะคัดให้สูงสุด 3 เมนู”.
4. Small food illustration and editable context strip.
5. One primary action: “หาเมนูให้ฉัน”, or a prerequisite-specific action such
   as “เปิดตำแหน่งเพื่อเริ่มค้นหา”. The action clearly describes its next step.

Place profile/food settings under the account/settings area, preserving guest
access. Move fictional preview navigation out of the main meal decision path
while keeping the existing preview accessible and explicitly labeled.
Do not add empty categories, fake popularity, or unfinished tracking controls.

### Location

Keep permission requests user-initiated and explain nearby-meal relevance
before requesting access. Preserve every existing recovery state and distinguish
approximate from precise location. Use a restrained location illustration and
spinner while finding a fix; do not invent progress percentages.

Replace internal wording such as “Phase นี้” and “Firebase” with useful copy:
“ใช้ตำแหน่งชั่วคราวขณะเปิดแอป ไม่บันทึกตำแหน่งและไม่ติดตามเบื้องหลัง”.
Ready state presents one continuation action and a secondary refresh action.

### Budget

- Lead with quick amounts: 60, 80, 100, and 150 baht. Selected chips show a
  checkmark plus a visible state change.
- Keep a clearly labeled custom amount field and numeric keyboard. Support
  the existing whole-baht 1–10,000 range, Thai digits, parsing, and validation.
- Do not introduce a slider as the primary control: this range needs precise
  numeric entry. Reduce the oversized decorative amount panel.
- Put the primary action in a safe bottom area: “ใช้งบ 100 บาท”. Use a generic
  “ยืนยันงบมื้อนี้” when the visible input is not valid.
- Confirm only after validation succeeds. A short Snackbar may acknowledge
  success; the persistent context strip must still show the confirmed amount
  after that message disappears. Offer a clear continuation to preferences.
- Editing the draft invalidates readiness until confirmed again. A quick-chip
  tap selects a draft value; it does not silently submit or navigate.
- Keep a concise price-change note and temporary-storage explanation without
  making backend details part of the consumer flow.

### Food preferences

Separate safety constraints from soft preferences while keeping the existing
single shared settings model and screen:

- Show selected counts by category and confirmation state at the top.
- Keep hard exclusions and allergies expanded, with plain labels and large
  checkbox/list-row targets. State the filtering effect close to the controls.
- Preserve halal evidence requirements, vegetarian meaning, supported allergens,
  and conservative exclusion when relevant evidence is incomplete.
- Use selectable chips for dislikes. Keep the optional hide-disliked switch
  and its explanation of incomplete ingredient data.
- Allow the secondary dislikes section to collapse. Its summary must expose
  selected values/count and whether hiding is enabled. Do not hide active
  safety constraints behind an accordion.
- Keep reset visually secondary, retain draft/save semantics, and make its
  consequences clear. Do not erase saved preferences merely by opening a screen.
- Use a safe bottom confirmation CTA. After successful confirmation, show a
  concise persistent ready summary and an actionable “ดูเมนูแนะนำ” continuation,
  rather than leaving only a disabled confirmation button.
- Empty selection means no selected constraints, not a guarantee of safety.
  Keep the reminder to confirm ingredients/allergens with the restaurant.

### Top 3 recommendations

Use a compact vertical list with the same information order on every card:

1. Approximately 96×96 logical-pixel food thumbnail or labeled illustration.
2. Small rank badge, menu name, and restaurant name.
3. Prominent price, with “ประมาณ” where required by confidence policy.
4. Compact distance and nutrition metadata; wrap naturally on narrow screens.
5. Price-confidence tag and a clear “ทำไมถึงแนะนำเมนูนี้?” detail action.
6. “ดูร้าน” once restaurant detail is implemented in Phase 10.

Prefer “อันดับ 1 ตามเงื่อนไขนี้” to an absolute best-quality claim. Distance
must remain labeled as approximate straight-line distance until route data
exists. Nutrition must retain an adjacent “ค่าประมาณ” label, including when
calories and protein share a row; never turn it into a health score.

At large text sizes, move the thumbnail above the text or reduce its prominence
and wrap metadata instead of clipping labels. Keep the price and confidence
visible without opening a sheet. Avoid a large rank circle competing with food
and price, or identical coral pills around every read-only fact.

The explanation sheet shows reasons derived from actual ranking inputs:
budget eligibility, approximate distance, effective price confidence, relevant
preference tier, and restaurant diversity where applicable. It must not invent
a personalized nutrition rationale or claim allergen-free certification.
Include the price source/date/status and estimated-nutrition explanation, with
clear separation between price verification and dietary evidence.

Show the actual number of results, including one or two. Use matching card
skeletons during the initial read. Refresh means “อัปเดตข้อมูล”; it is not a
randomizer, and unchanged inputs/data may produce identical results.
Keep missing-input, network-error, and no-match states distinct. Never loosen
allergy/restriction filters automatically to fill the list. Offer budget editing
or settings review as recovery without encouraging unsafe changes.

### Restaurant detail, Maps, and meal selection

When their respective phases are implemented, continue the same card identity
into the restaurant screen with a real photo or honest fallback, restaurant and
menu names, price evidence, estimated nutrition, address, and available source
information. Show hours, ratings, or open/closed status only when supported by
data, including recency where material.

Keep price evidence in a contextual sheet. Add map preview and map failure/
retry states with the Maps phase; straight-line distance is not walking time.
Add a reachable meal-selection action with the meal-selection phase, and make
clear that recording a meal is not placing an order with the restaurant.
Preserve context and scroll position when returning to the recommendations.

### Later navigation, tracking, and scan

Introduce bottom navigation when its destinations work. The target labels are
“มื้อนี้ / บันทึก / สแกน / ฉัน”; hide unavailable destinations instead of shipping
dead tabs. Validate whether scan belongs as a destination or a prominent action
when its actual workflow is built.

Tracking uses clear units and neutral language, without shame or unsupported
health judgments. Food Scan explicitly labels estimates and requires user
confirmation/edit before a result affects the daily log, as specified in
PROJECT_CONTEXT.md. Preserve optional authentication until a feature actually
requires the user's account.

### Motion and feedback tokens

| Token | Target duration | Use |
| --- | --- | --- |
| press | 120–160ms | Subtle button press/release |
| selection | 180–220ms | Chip checkmark and selected state |
| sheet | 240–300ms | Contextual sheet open/close |
| content | 180–250ms | Skeleton-to-result fade and small state transitions |

Use a small shared easing set with gentle deceleration. Avoid long bounces,
looping decoration, forced delays, text scrambling, and automatic carousels.
Reduced-motion settings remove travel/scale and shimmer while preserving
immediate state feedback. Optional light haptics acknowledge explicit selections
or confirmation, respect device settings, and never fire during passive reads.
Prefer built-in Flutter animation tools before adding a new dependency.

Snackbars acknowledge transient success without blocking the task. Validation,
critical errors, and current confirmation state remain visible in the screen.
Sheets support Android Back, visible dismissal, keyboard insets, screen-reader
focus, and enough height/scrolling for enlarged Thai text.

### Copy and accessibility acceptance

- Use short, direct Thai labels and familiar units. Remove internal phase,
  database, and framework vocabulary from consumer screens.
- Preserve 48×48 logical-pixel interactive targets, text/icon state cues, and
  contrast checks for every selected, disabled, error, and gradient state.
- Validate compact 320×640 layouts at normal and 200% text scale, with keyboard
  open, long menu/restaurant names, and multiple selected constraints.
- Make chip selection, section expansion, loading, and successful confirmation
  understandable to TalkBack. Decorative illustrations must not duplicate
  spoken content.
- Do not hide price uncertainty, safety notes, or current filter selections
  through truncation or transient feedback alone.
- Bottom actions must respect SafeArea and keyboard insets, leave enough scroll
  padding, and never cover the final field or error message.

### Implementation sequence and verification

The phase names below follow the completed Phase 1–9 timeline. The numbered
development-priority list in PROJECT_CONTEXT.md has separate Project Structure
and Flutter Foundation entries; it must not be used as a phase number directly.

| Increment | Deliverables | Readiness/dependency |
| --- | --- | --- |
| Existing-screen redesign | Shared tokens/components, Home, context strip, Location copy, Budget, Preferences, Top 3, evidence/explanation sheet, loading/error states | First increment implemented; see docs/ui-refresh.md for verified scope and remaining design work. Phase 1–9 behavior remains the baseline |
| Phase 10: Restaurant detail | Restaurant/menu detail, evidence presentation, card-to-detail continuity | Implemented; Maps and meal selection remain gated |
| Phase 11: Google Maps | Map preview, location context, map recovery states | Implementation in progress; native map route added, restricted key and live-tile acceptance pending |
| Phase 12: Meal selection | Clear record-meal action and confirmation | Implemented; authenticated recommendation meals are written only after confirmation |
| Phase 13: Daily Tracking | Daily log surfaces and relevant navigation | Implemented; private day browsing, estimated totals, meal list, and tracking navigation |
| Phase 14: AI Food Scan | Capture, estimate review/edit, confirmation, completed navigation | Implemented locally; third working navigation destination and emulator-confirmed write, live Gemini acceptance pending |
| Phase 15: Crashlytics / Analytics / polish | Opt-in monitoring, privacy controls, motion/haptics refinement, observation and user validation plan | Implemented locally; live Firebase Console event/report acceptance and representative student sessions remain pending |

For each implementation increment, inspect existing edits, update relevant
phase documentation, run flutter analyze and flutter test for Flutter changes,
and visually inspect affected screens/states on Android. Preserve existing
filtering, budget validation, persistence, authentication, and navigation tests;
add meaningful behavior coverage for newly introduced interactions. Document
what is implemented separately from what remains a design specification.

Evaluate the redesign with representative student users completing three tasks:
find eligible meals within a stated budget, change that budget without losing
food settings, and explain a result's price/nutrition uncertainty. Observe
completion, time to first useful result, navigation mistakes, and comprehension.
These are proposed evaluation measures, not claimed research results. Establish
a baseline before setting improvement targets; integrate event collection only
when the Analytics work is implemented with appropriate data handling.

## Coral Companion brand refresh (2026-09-27)

This is a visual and interaction refresh across the existing Phase 1–15 app, not
a new phase or a change to the meal-filtering, privacy, authentication, or
Firestore contracts. The implementation record and acceptance limits are in
[`docs/coral-companion-redesign.md`](docs/coral-companion-redesign.md).

The brand uses a coral fork/spoon/smile mark, `#D82E50` primary coral,
`#B51F40` active coral, `#FBE5E8` selected tint, `#FFFAF6` canvas,
`#29221F` primary ink, `#776960` secondary ink, and `#EDE3DC` borders.
Prompt is reserved for brand, headings, emphasized numbers, and primary
actions; Noto Sans Thai carries explanatory copy and form content. Cards have
20–24 px corners and modest or no shadow; controls stay at least 48 px high.
Coral marks the primary action and selection rather than every surface.

Home leads with “มื้อนี้กินอะไรดี?”, a visible confirmed meal budget, three
budget shortcuts, the existing location step, and “หาเมนูให้หน่อย”. Shortcut
selection opens Budget as a draft, and only explicit confirmation updates the
saved budget. Results, detail, nutrition estimates, and food-safety caveats
keep their existing meaning. Home does not present fabricated catalog results
as real nearby recommendations.

## Campus Pop selected; logo refinement first (2026-10-03)

The user selected concept 02 Campus Pop from
`docs/design-proposals/2026-10-03/README.md`, and requested correcting the logo
before further screen redesign. This selects the visual direction; it does
not mean the mockup screens have been implemented or deployed.

The production mark must use deterministic vector geometry, not a generated
image as its source. `assets/brand/muenee_launcher.svg` is the canonical source.
It has exactly four equally spaced fork tines, a symmetric spoon with a straight
handle, equal handle endpoints, a symmetric smile, a uniform 6-unit rounded
stroke, and centered ink bounds in its 108-unit viewport. Background corner
radius is 27 units. Coral color, wordmark and existing fonts are retained.

`scripts/generate_brand_assets.ps1` generates Flutter geometry, Android
foreground/monochrome and splash vectors, plus PNG exports from that source.
Do not independently redraw the mark inside generated mockups or platform
files. The generator's `-Check` mode detects drift. The refinement record,
original backups and before/after preview are documented in
`docs/brand-refinement-2026-10-03.md`.

The first Campus Pop screen pass now applies the selected cream/coral/butter-
yellow/lilac tokens across the shared theme. Home foregrounds the confirmed
budget and meal preferences, with a small deterministic food doodle instead of
an unverified dish photo, without changing the existing draft/confirmation
flow. Top 3 gives rank one a featured illustration panel and keeps ranks two
and three compact for comparison; image placeholders remain explicitly labeled
because this catalog has no verified menu photos. Food Scan groups editable
nutrition into four colored estimate fields and keeps the review-before-save
step explicit. Existing recommendation, allergy, price-evidence, privacy,
authentication and phase contracts are unchanged.

This is the first screen increment, not final whole-app acceptance. Restaurant
detail, tracking, account, settings and the remaining states still need a
Campus Pop visual pass. `flutter analyze --no-pub` reports no issues, and all
123 Flutter tests pass, including compact/large-text layout checks. Emulator
visual acceptance is pending because ADB in the current Windows runner cannot
resolve its user profile for `.android`. The user asked not to create an APK
yet, so no APK was built.
