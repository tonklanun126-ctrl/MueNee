import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:muenee/app/app.dart';
import 'package:muenee/features/budget/providers/meal_budget_provider.dart';
import 'package:muenee/features/auth/auth_repository.dart';
import 'package:muenee/core/monitoring/telemetry_providers.dart';
import 'package:muenee/core/monitoring/telemetry_repository.dart';
import 'package:muenee/core/monitoring/telemetry_settings.dart';

void main() {
  testWidgets(
    'home budget shortcut stays a draft until explicit confirmation',
    (tester) async {
      await tester.pumpWidget(const ProviderScope(child: MueNeeApp()));
      final container = ProviderScope.containerOf(
        tester.element(find.text('มื้อนี้กินอะไรดี?')),
      );

      await tester.ensureVisible(find.text('฿60'));
      await tester.tap(find.text('฿60'));
      await tester.pumpAndSettle();

      expect(container.read(mealBudgetProvider), isNull);
      expect(find.text('งบมื้อนี้'), findsOneWidget);
      expect(
        tester
            .widget<TextFormField>(find.byType(TextFormField))
            .controller
            ?.text,
        '60',
      );
      await tester.tap(find.byKey(const ValueKey('confirm-meal-budget')));
      await tester.pumpAndSettle();
      expect(container.read(mealBudgetProvider)?.amountBaht, 60);

      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('ยืนยันแล้ว · ไม่เกิน ฿60'), findsOneWidget);
    },
  );

  testWidgets('shows location as the first core-flow step', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [accountProvider.overrideWith((ref) => Stream.value(null))],
        child: const MueNeeApp(),
      ),
    );

    expect(find.text('MueNee'), findsOneWidget);
    expect(find.text('มื้อนี้กินอะไรดี?'), findsOneWidget);
    expect(find.text('ใช้ตำแหน่งปัจจุบัน'), findsOneWidget);
    expect(find.text('ตั้งค่าโปรไฟล์'), findsOneWidget);
    expect(find.text('มื้อนี้'), findsOneWidget);
    expect(find.text('บันทึก'), findsOneWidget);
    expect(find.text('สแกน'), findsOneWidget);

    await tester.ensureVisible(find.text('ใช้ตำแหน่งปัจจุบัน'));
    await tester.tap(find.text('ใช้ตำแหน่งปัจจุบัน'));
    await tester.pumpAndSettle();

    expect(find.text('ตำแหน่งของคุณ'), findsOneWidget);
    expect(find.text('ยังไม่ได้ใช้ตำแหน่ง'), findsOneWidget);
  });

  testWidgets('home remains scrollable on a small screen with large text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [accountProvider.overrideWith((ref) => Stream.value(null))],
        child: const MueNeeApp(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('ข้อมูลและความเป็นส่วนตัว'));
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'bottom navigation opens private daily tracking and returns home',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            accountProvider.overrideWith((ref) => Stream.value(null)),
          ],
          child: const MueNeeApp(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('บันทึก'));
      await tester.pumpAndSettle();
      expect(find.text('บันทึกประจำวัน'), findsOneWidget);
      expect(find.text('เข้าสู่ระบบเพื่อดูบันทึก'), findsOneWidget);

      await tester.tap(find.text('มื้อนี้'));
      await tester.pumpAndSettle();
      expect(find.text('มื้อนี้กินอะไรดี?'), findsOneWidget);
    },
  );

  testWidgets('bottom navigation opens the protected food scan destination', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [accountProvider.overrideWith((ref) => Stream.value(null))],
        child: const MueNeeApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('สแกน'));
    await tester.pumpAndSettle();
    expect(find.text('สแกนอาหาร'), findsOneWidget);
    expect(find.text('เข้าสู่ระบบก่อนสแกนอาหาร'), findsOneWidget);
  });

  testWidgets('home opens the guest privacy controls', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          accountProvider.overrideWith((ref) => Stream.value(null)),
          telemetrySettingsRepositoryProvider.overrideWithValue(
            _PrivacyRepository(),
          ),
        ],
        child: const MueNeeApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('ข้อมูลและความเป็นส่วนตัว'));
    await tester.tap(find.text('ข้อมูลและความเป็นส่วนตัว'));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('analytics-consent')), findsOneWidget);
    expect(find.byKey(const ValueKey('crash-consent')), findsOneWidget);
  });
}

class _PrivacyRepository implements TelemetrySettingsRepository {
  @override
  Future<TelemetrySettings> load() async => const TelemetrySettings();

  @override
  Future<void> save(TelemetrySettings settings) async {}
}
