# Profile settings UX

## Entry point

The home placeholder opens `ตั้งค่าโปรไฟล์` at `/profile-settings`. The page
can be used before an account exists and keeps its confirmed values on this
device.

## Fields

| Field | Stored value | Input rule |
| --- | --- | --- |
| อายุ | Integer years | 1–120 |
| ส่วนสูง | Decimal centimetres | 50–250 cm |
| น้ำหนัก | Decimal kilograms | 10–500 kg |
| ระดับกิจกรรม | One `ActivityLevel` enum | Five choices from mostly seated to very active |

The ranges prevent obvious input mistakes and are not medical thresholds. The
form requires all four fields before saving a non-empty profile. A new install
starts with an empty profile so the user is not forced through setup. The
activity choices are descriptive labels only; Phase 1 does not calculate
calories, BMI, or health advice from them.

## Persistence and error behavior

`UserProfile` is serialized as versioned JSON under
`muenee.user_profile.v1` through a feature-owned `UserProfileRepository` and
Riverpod `userProfileProvider`. Enum names, rather than translated labels, are
stored so a future label change does not corrupt saved data.

The page shows loading and retry states, keeps the last confirmed provider state
when a save fails, reports save failures, and asks before discarding unsaved
edits. Invalid or unsupported stored JSON is surfaced as an error instead of
being silently replaced with defaults.

API 36 emulator smoke testing saved age 30, height 170 cm, weight 65 kg, and
moderate activity. All four values remained after a force-stop and relaunch.
See [Phase 1 validation](phase-1-validation.md#emulator-smoke-test-2026-09-05).

## Design baseline

The current app uses Flutter Material 3 with a warm food-focused palette: warm
white, coral-red, orange, and yellow. It is an Airbnb-inspired direction with
MueNee's own identity, rather than a copy of Airbnb brand assets. `shadcn.io`
can be used as a visual reference for spacing, cards, forms, color tokens, and
interaction patterns. Its shadcn/ui code is distributed for web framework
templates, so a Flutter implementation should translate the chosen reference
into Flutter theme tokens and widgets rather than copy JSX/Tailwind files into
the Android app. See the project [design direction](../DESIGN.md).

## Scope boundary

This page only collects and stores the requested profile inputs. Firebase Auth,
Firestore sync, recommendation ranking, nutrition calculations, and medical
guidance remain outside Phase 1.
