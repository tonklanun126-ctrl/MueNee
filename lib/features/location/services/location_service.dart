import 'package:geolocator/geolocator.dart';

import '../models/device_location.dart';

enum DeviceLocationPermission { denied, deniedForever, whileInUse, always }

abstract interface class LocationService {
  Future<bool> isServiceEnabled();
  Future<DeviceLocationPermission> checkPermission();
  Future<DeviceLocationPermission> requestPermission();
  Future<DeviceLocation> getCurrentLocation();
  Future<bool> openAppSettings();
  Future<bool> openLocationSettings();
}

class GeolocatorLocationService implements LocationService {
  const GeolocatorLocationService();

  @override
  Future<bool> isServiceEnabled() => Geolocator.isLocationServiceEnabled();

  @override
  Future<DeviceLocationPermission> checkPermission() async =>
      _mapPermission(await Geolocator.checkPermission());

  @override
  Future<DeviceLocationPermission> requestPermission() async =>
      _mapPermission(await Geolocator.requestPermission());

  @override
  Future<DeviceLocation> getCurrentLocation() async {
    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 15),
      ),
    );
    final accuracy = await Geolocator.getLocationAccuracy();
    return DeviceLocation(
      latitude: position.latitude,
      longitude: position.longitude,
      accuracyMeters: position.accuracy,
      measuredAt: position.timestamp,
      precision: switch (accuracy) {
        LocationAccuracyStatus.precise => DeviceLocationPrecision.precise,
        LocationAccuracyStatus.reduced => DeviceLocationPrecision.reduced,
        LocationAccuracyStatus.unknown => DeviceLocationPrecision.unknown,
      },
    );
  }

  @override
  Future<bool> openAppSettings() => Geolocator.openAppSettings();

  @override
  Future<bool> openLocationSettings() => Geolocator.openLocationSettings();

  static DeviceLocationPermission _mapPermission(LocationPermission value) =>
      switch (value) {
        LocationPermission.denied => DeviceLocationPermission.denied,
        LocationPermission.deniedForever =>
          DeviceLocationPermission.deniedForever,
        LocationPermission.whileInUse => DeviceLocationPermission.whileInUse,
        LocationPermission.always => DeviceLocationPermission.always,
        LocationPermission.unableToDetermine => DeviceLocationPermission.denied,
      };
}
