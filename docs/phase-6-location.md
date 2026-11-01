# Phase 6: Current location

Phase 6 implements development-priority item 7. It lets an Android user obtain
their current position as the first step of the MueNee core flow. It does not
implement budget input, restaurant ranking, Google Maps, background tracking,
or Firestore location storage.

## User flow

- Home opens `/location` from the primary `ใช้ตำแหน่งปัจจุบัน` action.
- The app explains why location is needed before any operating-system prompt.
- Permission is requested only after the user taps the action.
- A successful fix reports whether the operating system supplied precise or
  approximate location and shows the reported accuracy in metres. Exact
  latitude and longitude are not displayed.
- Disabled device services, denied permission, permanently denied permission,
  timeout, and unexpected failures each have plain-language recovery states.
- Device location settings and app-specific settings can be opened from the
  relevant recovery state. The user explicitly retries after returning.

## Privacy and Android permissions

The current fix is held only in Riverpod memory for the running app process.
Phase 6 does not write it to SharedPreferences, Firestore, logs, or another
service. The app does not subscribe to a position stream and does not request
background location.

The main Android manifest declares only:

- `ACCESS_COARSE_LOCATION`
- `ACCESS_FINE_LOCATION`

`ACCESS_BACKGROUND_LOCATION` and location foreground-service permissions are
intentionally absent. Approximate location remains usable; it is labeled as
such rather than forcing precise access.

## Implementation

- `features/location/models`: plugin-independent current-fix data.
- `features/location/services`: a small `LocationService` contract and the
  `geolocator` adapter.
- `features/location/providers`: a Riverpod controller for permission,
  acquisition, error, and settings states.
- `features/location/presentation`: the responsive Material 3 location screen.

The service boundary keeps platform calls outside widgets and allows unit and
widget tests to cover permission branches without invoking a native plugin.
Current acquisition uses high accuracy with a 15-second timeout. The operating
system may still return approximate data when the user chooses reduced access.

## Validation

Run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/check_flutter.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/build_android.ps1
```

The automated suite covers user-initiated permission requests, disabled
services, retryable denial, permanent denial and app settings, successful
in-memory fixes, home navigation, and a 320 x 640 layout at 200% text scale.

## Acceptance evidence (2026-09-06)

- `flutter analyze --no-pub`: passed with no issues.
- The full Flutter suite passed 59 tests, including eight new Phase 6 tests.
- An Android x86_64 debug APK built successfully.
- APK permission inspection found coarse and fine foreground location and no
  background-location permission.
- On the Android 16 / API 36 emulator, location permission was reset before the
  run. MueNee did not show the operating-system prompt on launch or on entering
  the location screen; it appeared only after tapping `ใช้ตำแหน่งปัจจุบัน`.
- The native dialog offered precise/approximate and foreground/one-time choices.
  After foreground precise access and a mock fix near Silpakorn University, the
  app reached `พร้อมหาร้านใกล้คุณ` and displayed the platform-reported 5 metre
  accuracy without displaying the coordinates.
- The first fix timed out while the emulator's Google Location Accuracy prompt
  was unresolved; the app showed the designed timeout/retry state. Retrying
  after enabling the emulator setting succeeded.
- The final Android log scan found no MueNee ANR, fatal exception, unhandled
  Flutter exception, or `E/flutter` entry.
