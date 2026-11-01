# Phase 11: Google Maps

Implementation started 2026-09-09. Native map acceptance awaits local Maps
configuration. Do not mark this phase complete until real tiles and markers
have been visually verified with the configured Android key.

## Implemented

- Restaurant detail opens its nested map route and preserves Back navigation.
- Google Maps Flutter shows a restaurant marker from the selected catalog record.
- An optional blue marker shows the already-held search location. It is a stale
  search fix, not live tracking; the screen requests no additional permission.
- Address remains readable, with recenter and recreate-map actions. A missing
  key never constructs the native map. Initial controller creation times out
  visibly after 20 seconds.
- No route calculation, travel time, meal logging, Places lookup or Firestore
  mutation is added. The current catalog already supplies restaurant coordinates.

The Flutter plugin's onMapCreated callback confirms controller creation, not
successful tile authentication/download. A blank map can therefore still occur
with an invalid key or offline connection; the page keeps reload guidance and
the address visible. Verify actual tiles manually before acceptance.

## Local Android setup

1. In Google Cloud project `muenee-pj`, verify billing and enable Maps SDK for
   Android. Billing/account changes require the owner's approval.
2. Create a dedicated Android Maps API key restricted to package
   `com.muenee.app` and the SHA-1 of the signing certificate used for the build.
   Restrict its APIs to Maps SDK for Android. Use the release certificate for a
   release build; the current project still uses debug signing.
3. Copy `config/maps.example.json` to `config/maps.local.json` and enter the key
   locally as `GOOGLE_MAPS_API_KEY`. Do not paste the key into chat. The existing
   `/config/*.local.json` ignore pattern protects this file from source control.
4. `scripts/build_android.ps1 -X64` automatically loads the local Maps file in
   addition to Firebase config. For direct flutter run/drive commands, pass
   `--dart-define-from-file=config/maps.local.json` explicitly.

Gradle decodes this same Flutter define into the Android manifest metadata.
The key exists in the APK by SDK design; source-file exclusion is not a security
boundary. Android application/API restrictions protect its usage. No Firebase
key is reused and no cloud services are enabled automatically by this change.

Official references:
- https://pub.dev/packages/google_maps_flutter
- https://developers.google.com/maps/documentation/android-sdk/get-api-key
- https://developers.google.com/maps/api-security-best-practices

## Acceptance

2026-10-05: Phase 11 was accepted on the local Android API 36 x86_64 AVD
emulator-5554. A dedicated Google Cloud key named MueNee Maps Android is
restricted to com.muenee.app, the debug SHA-1 used by this checkout, and Maps
SDK for Android only. The key value remains in the ignored
config/maps.local.json file and is not recorded here.

Validation evidence:

- flutter analyze --no-pub: clean.
- flutter test --no-pub: all 123 tests passed, including map fallback and
  nested detail/map/back navigation coverage.
- scripts/build_android.ps1 -X64: succeeded.
- APK: build/app/outputs/flutter-apk/app-debug.apk, 180994767 bytes,
  SHA-256 486A0C8A10917956207F754FA8830AEA179A733A7850D01195A89F02F13AC090.
  Package com.muenee.app, version 1.0.1/code 5000, APK Signature Scheme
  v2 verified; the Maps manifest metadata is present.
- Android smoke flow: location permission -> budget -> recommendations ->
  restaurant detail -> map. The captured artifacts/phase-11-map.png shows
  Google street tiles and the restaurant marker. Filtered logcat contained no
  Maps authorization failure or app crash.

The optional search-location marker is only shown when the held search fix is
available; this smoke run verified the required street tiles and restaurant
marker. Release builds still need a release-certificate restriction and a
separate release APK smoke test before publishing.