import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'telemetry_repository.dart';
import 'telemetry_service.dart';
import 'telemetry_settings.dart';

final telemetryServiceProvider = Provider<TelemetryService>(
  (ref) => const NoopTelemetryService(),
);

final telemetrySettingsRepositoryProvider =
    Provider<TelemetrySettingsRepository>(
      (ref) => LocalTelemetrySettingsRepository(SharedPreferencesAsync()),
    );

final telemetrySettingsProvider =
    AsyncNotifierProvider<TelemetrySettingsController, TelemetrySettings>(
      TelemetrySettingsController.new,
    );

class TelemetrySettingsController extends AsyncNotifier<TelemetrySettings> {
  @override
  Future<TelemetrySettings> build() async {
    final settings = await ref
        .watch(telemetrySettingsRepositoryProvider)
        .load();
    await ref.watch(telemetryServiceProvider).applySettings(settings);
    return settings;
  }

  Future<void> save(TelemetrySettings next) async {
    final previous = state.requireValue;
    final repository = ref.read(telemetrySettingsRepositoryProvider);
    final service = ref.read(telemetryServiceProvider);
    try {
      await repository.save(next);
      await service.applySettings(next);
      if (ref.mounted) state = AsyncData(next);
    } catch (error, stackTrace) {
      try {
        await repository.save(previous);
        await service.applySettings(previous);
      } catch (_) {
        // Preserve the original error. The next startup reapplies stored state.
      }
      Error.throwWithStackTrace(error, stackTrace);
    }
  }
}
