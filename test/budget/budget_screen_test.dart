import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:muenee/app/app.dart';
import 'package:muenee/features/budget/providers/meal_budget_provider.dart';
import 'package:muenee/features/location/models/device_location.dart';
import 'package:muenee/features/location/providers/location_provider.dart';

void main() {
  testWidgets(
    'ready location continues to budget without another location request',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [locationProvider.overrideWith(_ReadyLocation.new)],
          child: const MueNeeApp(),
        ),
      );
      await tester.ensureVisible(find.text('ตำแหน่งพร้อมแล้ว'));
      await tester.tap(find.text('ตำแหน่งพร้อมแล้ว'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('ต่อไป: กำหนดงบ'));
      await tester.tap(find.text('ต่อไป: กำหนดงบ'));
      await tester.pumpAndSettle();
      expect(find.text('งบมื้อนี้'), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('ตำแหน่งของคุณ'), findsOneWidget);
    },
  );
  Future<void> open(WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: MueNeeApp()));
    final appBarAction = find.byTooltip('กำหนดงบมื้อนี้');
    if (appBarAction.evaluate().isNotEmpty) {
      await tester.tap(appBarAction);
    } else {
      final budgetAction = find.byTooltip('กำหนดงบอื่น');
      await tester.ensureVisible(budgetAction);
      await tester.tap(budgetAction);
    }
    await tester.pumpAndSettle();
  }

  testWidgets(
    'preset is draft until confirmation; confirmed budget survives reopening',
    (tester) async {
      await open(tester);
      final container = ProviderScope.containerOf(
        tester.element(find.text('งบมื้อนี้')),
      );
      await tester.tap(find.text('฿80').last);
      await tester.pump();
      expect(container.read(mealBudgetProvider), isNull);
      await tester.tap(find.byKey(const ValueKey('confirm-meal-budget')));
      await tester.pumpAndSettle();
      expect(container.read(mealBudgetProvider)?.amountBaht, 80);
      expect(find.text('ยืนยันแล้ว: ไม่เกิน 80 บาท'), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('กำหนดงบอื่น'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<TextFormField>(find.byType(TextFormField))
            .controller
            ?.text,
        '80',
      );
    },
  );

  testWidgets(
    'Thai input submits with keyboard; invalid edit preserves confirmed amount',
    (tester) async {
      await open(tester);
      await tester.enterText(find.byType(TextFormField), '๒๕๐');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(find.text('ยืนยันแล้ว: ไม่เกิน 250 บาท'), findsOneWidget);
      await tester.enterText(find.byType(TextFormField), '80.5');
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('confirm-meal-budget')));
      await tester.pumpAndSettle();
      expect(find.text('กรอกจำนวนเต็ม เช่น 80 หรือ 1,000 บาท'), findsOneWidget);
      expect(find.text('งบที่ยืนยันไว้: ไม่เกิน 250 บาท'), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('ยังไม่ได้ยืนยันงบใหม่'), findsOneWidget);
      await tester.tap(find.text('แก้ไขต่อ'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<TextFormField>(find.byType(TextFormField))
            .controller
            ?.text,
        '80.5',
      );
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.tap(find.text('ทิ้งการแก้ไข'));
      await tester.pumpAndSettle();
      expect(find.text('MueNee'), findsOneWidget);
    },
  );

  testWidgets(
    'small screen at 200 percent text keeps validation and confirm reachable',
    (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await open(tester);
      await tester.tap(find.byKey(const ValueKey('confirm-meal-budget')));
      await tester.pumpAndSettle();
      expect(find.text('กรุณาระบุงบมื้อนี้'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.enterText(find.byType(TextFormField), '1,000');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(find.text('ยืนยันแล้ว: ไม่เกิน 1000 บาท'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}

class _ReadyLocation extends LocationController {
  @override
  LocationState build() => LocationState.ready(
    DeviceLocation(
      latitude: 13.8199,
      longitude: 100.0443,
      accuracyMeters: 5,
      measuredAt: DateTime.utc(2026, 9, 7),
      precision: DeviceLocationPrecision.precise,
    ),
  );
}
