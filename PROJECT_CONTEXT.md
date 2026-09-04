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