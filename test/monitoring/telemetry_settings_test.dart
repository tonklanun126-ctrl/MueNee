import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:muenee/core/monitoring/telemetry_providers.dart';
import 'package:muenee/core/monitoring/telemetry_repository.dart';
import 'package:muenee/core/monitoring/telemetry_service.dart';
import 'package:muenee/core/monitoring/telemetry_settings.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  test(
    'telemetry is opt-in and round-trips through versioned local JSON',
    () async {
      const defaults = TelemetrySettings();
      expect(defaults.analyticsEnabled, isFalse);
      expect(defaults.crashReportsEnabled, isFalse);

      final repository = LocalTelemetrySettingsRepository(
        SharedPreferencesAsync(),
      );
      const enabled = TelemetrySettings(
        analyticsEnabled: true,
        crashReportsEnabled: true,
      );
      await repository.save(enabled);
      expect(await repository.load(), enabled);
    },
  );

  test('malformed preferences are not silently treated as consent', () async {
    final storage = SharedPreferencesAsync();
    final repository = LocalTelemetrySettingsRepository(storage);
    for (final raw in [
      'broken',
      '[]',
      jsonEncode({
        'version': 2,
        'analyticsEnabled': true,
        'crashReportsEnabled': true,
      }),
    ]) {
      await storage.setString(LocalTelemetrySettingsRepository.storageKey, raw);
      await expectLater(repository.load(), throwsFormatException);
    }
  });

  test(
    'provider applies saved choice and rolls back a failed change',
    () async {
      final repository = _MemoryRepository();
      final telemetry = _FakeTelemetryService();
      final container = ProviderContainer(
        overrides: [
          telemetrySettingsRepositoryProvider.overrideWithValue(repository),
          telemetryServiceProvider.overrideWithValue(telemetry),
        ],
      );
      addTearDown(container.dispose);

      expect(
        await container.read(telemetrySettingsProvider.future),
        const TelemetrySettings(),
      );
      expect(telemetry.applied, [const TelemetrySettings()]);

      repository.failNextSave = true;
      await expectLater(
        container
            .read(telemetrySettingsProvider.notifier)
            .save(const TelemetrySettings(analyticsEnabled: true)),
        throwsStateError,
      );
      expect(
        container.read(telemetrySettingsProvider).requireValue,
        const TelemetrySettings(),
      );
      expect(repository.value, const TelemetrySettings());
    },
  );

  test('analytics event allowlist contains no user-content fields', () {
    expect(MueNeeAnalyticsEvent.values.map((event) => event.eventName), [
      'meal_flow_started',
      'budget_confirmed',
      'preferences_confirmed',
      'recommendation_meal_recorded',
      'food_scan_analysis_completed',
      'food_scan_meal_recorded',
    ]);
  });
}

class _MemoryRepository implements TelemetrySettingsRepository {
  TelemetrySettings value = const TelemetrySettings();
  bool failNextSave = false;

  @override
  Future<TelemetrySettings> load() async => value;

  @override
  Future<void> save(TelemetrySettings settings) async {
    if (failNextSave) {
      failNextSave = false;
      throw StateError('disk failure');
    }
    value = settings;
  }
}

class _FakeTelemetryService implements TelemetryService {
  final applied = <TelemetrySettings>[];

  @override
  NavigatorObserver get navigatorObserver => NavigatorObserver();

  @override
  Future<void> applySettings(TelemetrySettings settings) async {
    applied.add(settings);
  }

  @override
  void installGlobalErrorHandlers() {}

  @override
  Future<void> logEvent(MueNeeAnalyticsEvent event) async {}

  @override
  Future<void> recordNonFatal(String code, StackTrace stackTrace) async {}

  @override
  void uninstallGlobalErrorHandlers() {}
}
