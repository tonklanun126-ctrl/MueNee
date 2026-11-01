import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'telemetry_settings.dart';

abstract interface class TelemetrySettingsRepository {
  Future<TelemetrySettings> load();
  Future<void> save(TelemetrySettings settings);
}

class LocalTelemetrySettingsRepository implements TelemetrySettingsRepository {
  LocalTelemetrySettingsRepository(this._storage);

  static const storageKey = 'muenee.telemetry_settings.v1';

  final SharedPreferencesAsync _storage;

  @override
  Future<TelemetrySettings> load() async {
    final raw = await _storage.getString(storageKey);
    if (raw == null) return const TelemetrySettings();
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Invalid telemetry settings document');
    }
    return TelemetrySettings.fromJson(decoded);
  }

  @override
  Future<void> save(TelemetrySettings settings) =>
      _storage.setString(storageKey, jsonEncode(settings.toJson()));
}
