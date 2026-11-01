import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:muenee/app/theme/app_theme.dart';
import 'package:muenee/core/monitoring/telemetry_providers.dart';
import 'package:muenee/core/monitoring/telemetry_repository.dart';
import 'package:muenee/core/monitoring/telemetry_service.dart';
import 'package:muenee/features/privacy/presentation/privacy_settings_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('privacy choices persist on Android and remain reversible', (
    tester,
  ) async {
    final storage = SharedPreferencesAsync();
    final previous = await storage.getString(
      LocalTelemetrySettingsRepository.storageKey,
    );
    await storage.remove(LocalTelemetrySettingsRepository.storageKey);
    addTearDown(() async {
      if (previous == null) {
        await storage.remove(LocalTelemetrySettingsRepository.storageKey);
      } else {
        await storage.setString(
          LocalTelemetrySettingsRepository.storageKey,
          previous,
        );
      }
    });

    Future<void> mount() => tester.pumpWidget(
      ProviderScope(
        overrides: [
          telemetryServiceProvider.overrideWithValue(
            const NoopTelemetryService(),
          ),
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          home: const PrivacySettingsScreen(),
        ),
      ),
    );

    await mount();
    await tester.pumpAndSettle();
    expect(_switch(tester, 'analytics-consent').value, isFalse);
    expect(_switch(tester, 'crash-consent').value, isFalse);

    await tester.tap(find.byKey(const ValueKey('analytics-consent')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('crash-consent')));
    await tester.pump();
    await tester.ensureVisible(
      find.byKey(const ValueKey('save-privacy-settings')),
    );
    await tester.tap(find.byKey(const ValueKey('save-privacy-settings')));
    await tester.pumpAndSettle();

    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(0, 1200),
    );
    await tester.pumpAndSettle();

    await binding.convertFlutterSurfaceToImage();
    await tester.pumpAndSettle();
    await binding.takeScreenshot('privacy-settings-enabled');

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    await mount();
    await tester.pumpAndSettle();
    expect(_switch(tester, 'analytics-consent').value, isTrue);
    expect(_switch(tester, 'crash-consent').value, isTrue);

    await tester.tap(find.byKey(const ValueKey('analytics-consent')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('crash-consent')));
    await tester.pump();
    await tester.ensureVisible(
      find.byKey(const ValueKey('save-privacy-settings')),
    );
    await tester.tap(find.byKey(const ValueKey('save-privacy-settings')));
    await tester.pumpAndSettle();
    expect(_switch(tester, 'analytics-consent').value, isFalse);
    expect(_switch(tester, 'crash-consent').value, isFalse);
    expect(tester.takeException(), isNull);
  });
}

SwitchListTile _switch(WidgetTester tester, String key) =>
    tester.widget<SwitchListTile>(find.byKey(ValueKey(key)));
