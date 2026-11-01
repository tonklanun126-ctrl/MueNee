import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../models/device_location.dart';
import '../services/location_service.dart';

enum LocationStatus {
  idle,
  loading,
  ready,
  serviceDisabled,
  permissionDenied,
  permissionDeniedForever,
  timedOut,
  unavailable,
}

class LocationState {
  const LocationState._(this.status, [this.location]);

  const LocationState.idle() : this._(LocationStatus.idle);
  const LocationState.loading() : this._(LocationStatus.loading);
  const LocationState.serviceDisabled()
    : this._(LocationStatus.serviceDisabled);
  const LocationState.permissionDenied()
    : this._(LocationStatus.permissionDenied);
  const LocationState.permissionDeniedForever()
    : this._(LocationStatus.permissionDeniedForever);
  const LocationState.timedOut() : this._(LocationStatus.timedOut);
  const LocationState.unavailable() : this._(LocationStatus.unavailable);
  const LocationState.ready(DeviceLocation location)
    : this._(LocationStatus.ready, location);

  final LocationStatus status;
  final DeviceLocation? location;
}

final locationServiceProvider = Provider<LocationService>(
  (ref) => const GeolocatorLocationService(),
);

final locationProvider = NotifierProvider<LocationController, LocationState>(
  LocationController.new,
);

class LocationController extends Notifier<LocationState> {
  @override
  LocationState build() => const LocationState.idle();

  Future<void> locate() async {
    if (state.status == LocationStatus.loading) return;
    state = const LocationState.loading();
    final service = ref.read(locationServiceProvider);

    try {
      if (!await service.isServiceEnabled()) {
        state = const LocationState.serviceDisabled();
        return;
      }

      var permission = await service.checkPermission();
      if (permission == DeviceLocationPermission.denied) {
        permission = await service.requestPermission();
      }
      if (permission == DeviceLocationPermission.denied) {
        state = const LocationState.permissionDenied();
        return;
      }
      if (permission == DeviceLocationPermission.deniedForever) {
        state = const LocationState.permissionDeniedForever();
        return;
      }

      final location = await service.getCurrentLocation();
      state = LocationState.ready(location);
    } on TimeoutException {
      state = const LocationState.timedOut();
    } on LocationServiceDisabledException catch (_) {
      state = const LocationState.serviceDisabled();
    } catch (error, stack) {
      _report(error, stack);
      state = const LocationState.unavailable();
    }
  }

  Future<bool> openAppSettings() async {
    try {
      return await ref.read(locationServiceProvider).openAppSettings();
    } catch (error, stack) {
      _report(error, stack);
      return false;
    }
  }

  Future<bool> openLocationSettings() async {
    try {
      return await ref.read(locationServiceProvider).openLocationSettings();
    } catch (error, stack) {
      _report(error, stack);
      return false;
    }
  }

  void _report(Object error, StackTrace stack) {
    FlutterError.reportError(
      FlutterErrorDetails(
        exception: error,
        stack: stack,
        library: 'MueNee location',
        context: ErrorDescription('while acquiring the current location'),
      ),
    );
  }
}
