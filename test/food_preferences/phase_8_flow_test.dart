import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:muenee/app/app.dart';
import 'package:muenee/features/profile/models/food_preferences.dart';
import 'package:muenee/features/profile/providers/food_preferences_provider.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  Future<void> openMealPreferences(WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: MueNeeApp()));
    await tester.ensureVisible(find.text('฿80').first);
    await tester.tap(find.text('฿80').first);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('confirm-meal-budget')));
    await tester.pumpAndSettle();
    final next = find.byKey(const ValueKey('continue-to-food-preferences'));
    await tester.ensureVisible(next);
    await tester.tap(next);
    await tester.pumpAndSettle();
  }

  testWidgets('confirmed budget continues to meal preference step', (
    tester,
  ) async {
    await openMealPreferences(tester);
    expect(find.text('การตั้งค่าอาหาร'), findsOneWidget);
    expect(find.text('ตั้งค่าสำหรับมื้อนี้'), findsOneWidget);
    expect(
      find.text('ข้อจำกัดและอาหารที่แพ้จะใช้เป็นตัวกรองแบบเคร่งครัด'),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('confirm-food-for-meal')), findsOneWidget);
  });

  testWidgets('meal preference confirmation persists saved hard filters', (
    tester,
  ) async {
    await openMealPreferences(tester);
    await tester.ensureVisible(
      find.byKey(const ValueKey('restriction-noPork')),
    );
    await tester.tap(find.byKey(const ValueKey('restriction-noPork')));
    await tester.tap(find.byKey(const ValueKey('confirm-food-for-meal')));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('พร้อมแล้ว การตั้งค่านี้จะใช้ค้นหาเมนูในขั้นตอนถัดไป'),
      300,
    );
    expect(
      find.text('พร้อมแล้ว การตั้งค่านี้จะใช้ค้นหาเมนูในขั้นตอนถัดไป'),
      findsOneWidget,
    );
    final container = ProviderScope.containerOf(
      tester.element(find.text('การตั้งค่าอาหาร')),
    );
    expect(
      container
          .read(foodPreferencesProvider)
          .requireValue
          .restrictions
          .contains(DietaryRestriction.noPork),
      isTrue,
    );

    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('ตั้งค่าอาหารที่กิน'));
    await tester.tap(find.text('ตั้งค่าอาหารที่กิน'));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<CheckboxListTile>(
            find.byKey(const ValueKey('restriction-noPork')),
          )
          .value,
      isTrue,
    );
  });

  testWidgets(
    'empty preferences can be explicitly confirmed on a small screen',
    (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      await openMealPreferences(tester);
      final confirm = find.byKey(const ValueKey('confirm-food-for-meal'));
      await tester.tap(confirm);
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('พร้อมแล้ว การตั้งค่านี้จะใช้ค้นหาเมนูในขั้นตอนถัดไป'),
        300,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('confirmed meal preferences continue to recommendations', (
    tester,
  ) async {
    await openMealPreferences(tester);
    final confirm = find.byKey(const ValueKey('confirm-food-for-meal'));
    await tester.tap(confirm);
    await tester.pumpAndSettle();
    await tester.tap(confirm);
    await tester.pumpAndSettle();

    expect(find.text('เมนูแนะนำ'), findsOneWidget);
    expect(find.text('ต้องมีตำแหน่งก่อน'), findsOneWidget);
  });
}
