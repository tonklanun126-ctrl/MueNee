enum DeviceLocationPrecision { precise, reduced, unknown }

class DeviceLocation {
  const DeviceLocation({
    required this.latitude,
    required this.longitude,
    required this.accuracyMeters,
    required this.measuredAt,
    required this.precision,
  });

  final double latitude;
  final double longitude;
  final double accuracyMeters;
  final DateTime measuredAt;
  final DeviceLocationPrecision precision;
}
