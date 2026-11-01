import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:muenee/core/monitoring/telemetry_providers.dart';
import 'package:muenee/core/monitoring/telemetry_repository.dart';
import 'package:muenee/core/monitoring/telemetry_service.dart';
import 'package:muenee/core/monitoring/telemetry_settings.dart';
import 'package:muenee/features/privacy/presentation/privacy_settings_screen.dart';

void main() {
  Widget app(_MemoryRepository repository, _FakeTelemetryService telemetry) =>
      ProviderScope(
        overrides: [
          telemetrySettingsRepositoryProvider.overrideWithValue(repository),
          telemetryServiceProvider.overrideWithValue(telemetry),
        ],
        child: const MaterialApp(home: PrivacySettingsScreen()),
      );

  testWidgets('starts opted out and saves each explicit choice', (
    tester,
  ) async {
    final repository = _MemoryRepository();
    final telemetry = _FakeTelemetryService();
    await tester.pumpWidget(app(repository, telemetry));
    await tester.pumpAndSettle();

    expect(
      tester
          .widget<SwitchListTile>(
            find.byKey(const ValueKey('analytics-consent')),
          )
          .value,
      isFalse,
    );
    expect(
      tester
          .widget<SwitchListTile>(find.byKey(const ValueKey('crash-consent')))
          .value,
      isFalse,
    );

    await tester.tap(find.byKey(const ValueKey('analytics-consent')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('crash-consent')));
    await tester.ensureVisible(
      find.byKey(const ValueKey('save-privacy-settings')),
    );
    await tester.tap(find.byKey(const ValueKey('save-privacy-settings')));
    await tester.pumpAndSettle();

    expect(
      repository.value,
      const TelemetrySettings(
        analyticsEnabled: true,
        crashReportsEnabled: true,
      ),
    );
    expect(telemetry.applied.last, repository.value);
    expect(find.text('บันทึกการตั้งค่าความเป็นส่วนตัวแล้ว'), findsOneWidget);
  });

  testWidgets('failed save keeps the previous consent', (tester) async {
    final repository = _MemoryRepository()..failNextSave = true;
    final telemetry = _FakeTelemetryService();
    await tester.pumpWidget(app(repository, telemetry));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('analytics-consent')));
    await tester.pump();
    await tester.ensureVisible(
      find.byKey(const ValueKey('save-privacy-settings')),
    );
    await tester.tap(find.byKey(const ValueKey('save-privacy-settings')));
    await tester.pumpAndSettle();

    expect(repository.value, const TelemetrySettings());
    expect(
      find.textContaining('ค่าก่อนหน้ายังถูกใช้อยู่', skipOffstage: false),
      findsOneWidget,
    );
  });

  testWidgets('remains scrollable at 320x640 and 200 percent text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await tester.pumpWidget(app(_MemoryRepository(), _FakeTelemetryService()));
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(const ValueKey('save-privacy-settings')),
    );
    expect(tester.takeException(), isNull);
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
