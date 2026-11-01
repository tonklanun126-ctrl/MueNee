import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:muenee/features/location/models/device_location.dart';
import 'package:muenee/features/location/providers/location_provider.dart';
import 'package:muenee/features/location/services/location_service.dart';

void main() {
  test(
    'does not request permission when device location is disabled',
    () async {
      final service = FakeLocationService(serviceEnabled: false);
      final container = ProviderContainer(
        overrides: [locationServiceProvider.overrideWithValue(service)],
      );
      addTearDown(container.dispose);

      await container.read(locationProvider.notifier).locate();

      expect(
        container.read(locationProvider).status,
        LocationStatus.serviceDisabled,
      );
      expect(service.permissionRequests, 0);
      expect(service.locationRequests, 0);
    },
  );

  test(
    'requests foreground permission and keeps a successful fix in memory',
    () async {
      final service = FakeLocationService(
        checkedPermission: DeviceLocationPermission.denied,
        requestedPermission: DeviceLocationPermission.whileInUse,
      );
      final container = ProviderContainer(
        overrides: [locationServiceProvider.overrideWithValue(service)],
      );
      addTearDown(container.dispose);

      await container.read(locationProvider.notifier).locate();

      final state = container.read(locationProvider);
      expect(state.status, LocationStatus.ready);
      expect(state.location?.latitude, 13.8199);
      expect(state.location?.precision, DeviceLocationPrecision.precise);
      expect(service.permissionRequests, 1);
      expect(service.locationRequests, 1);
    },
  );

  test('shows a retryable state after permission is denied', () async {
    final service = FakeLocationService(
      checkedPermission: DeviceLocationPermission.denied,
      requestedPermission: DeviceLocationPermission.denied,
    );
    final container = ProviderContainer(
      overrides: [locationServiceProvider.overrideWithValue(service)],
    );
    addTearDown(container.dispose);

    await container.read(locationProvider.notifier).locate();

    expect(
      container.read(locationProvider).status,
      LocationStatus.permissionDenied,
    );
    expect(service.locationRequests, 0);
  });

  test('requires app settings after permission is denied forever', () async {
    final service = FakeLocationService(
      checkedPermission: DeviceLocationPermission.deniedForever,
    );
    final container = ProviderContainer(
      overrides: [locationServiceProvider.overrideWithValue(service)],
    );
    addTearDown(container.dispose);

    await container.read(locationProvider.notifier).locate();
    final opened = await container
        .read(locationProvider.notifier)
        .openAppSettings();

    expect(
      container.read(locationProvider).status,
      LocationStatus.permissionDeniedForever,
    );
    expect(opened, isTrue);
    expect(service.appSettingsRequests, 1);
  });

  test('turns a slow current fix into a recoverable timeout state', () async {
    final service = FakeLocationService(timeout: true);
    final container = ProviderContainer(
      overrides: [locationServiceProvider.overrideWithValue(service)],
    );
    addTearDown(container.dispose);

    await container.read(locationProvider.notifier).locate();

    expect(container.read(locationProvider).status, LocationStatus.timedOut);
  });
}

class FakeLocationService implements LocationService {
  FakeLocationService({
    this.serviceEnabled = true,
    this.checkedPermission = DeviceLocationPermission.whileInUse,
    this.requestedPermission = DeviceLocationPermission.whileInUse,
    this.timeout = false,
  });

  final bool serviceEnabled;
  final DeviceLocationPermission checkedPermission;
  final DeviceLocationPermission requestedPermission;
  final bool timeout;
  int permissionRequests = 0;
  int locationRequests = 0;
  int appSettingsRequests = 0;

  @override
  Future<DeviceLocationPermission> checkPermission() async => checkedPermission;

  @override
  Future<DeviceLocation> getCurrentLocation() async {
    locationRequests += 1;
    if (timeout) throw TimeoutException('test timeout');
    return DeviceLocation(
      latitude: 13.8199,
      longitude: 100.0443,
      accuracyMeters: 12.4,
      measuredAt: DateTime.utc(2026, 9, 6),
      precision: DeviceLocationPrecision.precise,
    );
  }

  @override
  Future<bool> isServiceEnabled() async => serviceEnabled;

  @override
  Future<bool> openAppSettings() async {
    appSettingsRequests += 1;
    return true;
  }

  @override
  Future<bool> openLocationSettings() async => true;

  @override
  Future<DeviceLocationPermission> requestPermission() async {
    permissionRequests += 1;
    return requestedPermission;
  }
}
