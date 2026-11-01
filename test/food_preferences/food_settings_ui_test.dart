import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:muenee/app/app.dart';
import 'package:muenee/features/profile/models/food_preferences.dart';
import 'package:muenee/features/profile/providers/food_preferences_provider.dart';
import 'package:muenee/features/profile/repositories/food_preferences_repository.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  Future<void> openSettings(WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: MueNeeApp()));
    final entry = find.text('ตั้งค่าอาหารที่กิน');
    await tester.ensureVisible(entry);
    await tester.tap(entry);
    await tester.pumpAndSettle();
  }

  testWidgets('save, reopen settings and apply filtering to preview', (
    tester,
  ) async {
    await openSettings(tester);
    await tester.tap(find.byKey(const ValueKey('restriction-noPork')));
    final allergy = find.byKey(const ValueKey('allergy-egg'));
    await tester.scrollUntilVisible(allergy, 250);
    await tester.drag(find.byType(ListView).last, const Offset(0, -120));
    await tester.pumpAndSettle();
    await tester.tap(allergy);
    await tester.pump();
    await tester.tap(find.text('บันทึกการตั้งค่า'));
    await tester.pumpAndSettle();
    expect(find.text('บันทึกการตั้งค่าอาหารแล้ว'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('ดูตัวอย่างเมนูและสถานะราคา'));
    await tester.tap(find.text('ดูตัวอย่างเมนูและสถานะราคา'));
    await tester.pumpAndSettle();
    expect(find.text('แสดง 3 จาก 6 เมนูตัวอย่าง'), findsOneWidget);
    expect(find.byKey(const ValueKey('sample-pork')), findsNothing);
    await tester.tap(find.text('แก้ไขการตั้งค่าอาหาร'));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<CheckboxListTile>(
            find.byKey(const ValueKey('restriction-noPork')),
          )
          .value,
      isTrue,
    );
    await tester.scrollUntilVisible(allergy, 250);
    expect(tester.widget<FilterChip>(allergy).selected, isTrue);
  });

  testWidgets('back confirms unsaved draft and discard keeps saved settings', (
    tester,
  ) async {
    await openSettings(tester);
    await tester.tap(find.byKey(const ValueKey('restriction-noPork')));
    await tester.pump();
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('ยังไม่ได้บันทึกการเปลี่ยนแปลง'), findsOneWidget);
    await tester.tap(find.text('ทิ้งการเปลี่ยนแปลง'));
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
      isFalse,
    );
  });

  testWidgets('price sheet explains evidence and labels example data', (
    tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: MueNeeApp()));
    await tester.ensureVisible(find.text('ดูตัวอย่างเมนูและสถานะราคา'));
    await tester.tap(find.text('ดูตัวอย่างเมนูและสถานะราคา'));
    await tester.pumpAndSettle();
    final badge = find.text('ยืนยันแล้ว').first;
    await tester.ensureVisible(badge);
    await tester.tap(badge);
    await tester.pumpAndSettle();
    expect(find.text('ข้อมูลราคา: ยืนยันแล้ว'), findsOneWidget);
    expect(find.textContaining('แหล่งข้อมูล: ใบเมนูจำลอง'), findsOneWidget);
    expect(find.textContaining('ภายใน 30 วัน'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'small screen and large text remain scrollable without overflow',
    (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 1.5;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await openSettings(tester);
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('hide-disliked')),
        300,
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('บันทึกการตั้งค่า'), findsOneWidget);
    },
  );

  testWidgets('failed save keeps the draft and supports retry', (tester) async {
    final repository = _RetryRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          foodPreferencesRepositoryProvider.overrideWithValue(repository),
        ],
        child: const MueNeeApp(),
      ),
    );
    await tester.ensureVisible(find.text('ตั้งค่าอาหารที่กิน'));
    await tester.tap(find.text('ตั้งค่าอาหารที่กิน'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('restriction-noPork')));
    await tester.pump();
    await tester.tap(find.text('บันทึกการตั้งค่า'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isA<StateError>());
    expect(find.text('บันทึกไม่สำเร็จ กรุณาลองอีกครั้ง'), findsOneWidget);
    expect(repository.saved.restrictions, isEmpty);
    expect(
      tester
          .widget<CheckboxListTile>(
            find.byKey(const ValueKey('restriction-noPork')),
          )
          .value,
      isTrue,
    );
    repository.fail = false;
    await tester.tap(find.text('บันทึกการตั้งค่า'));
    await tester.pumpAndSettle();
    expect(repository.saved.restrictions, {DietaryRestriction.noPork});
  });

  testWidgets('load failure blocks preview and provides a retry', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          foodPreferencesRepositoryProvider.overrideWithValue(
            _UnavailableRepository(),
          ),
        ],
        child: const MueNeeApp(),
      ),
    );
    await tester.ensureVisible(find.text('ดูตัวอย่างเมนูและสถานะราคา'));
    await tester.tap(find.text('ดูตัวอย่างเมนูและสถานะราคา'));
    await tester.pumpAndSettle();
    expect(
      find.text('โหลดการตั้งค่าไม่สำเร็จ จึงยังไม่แสดงเมนู'),
      findsOneWidget,
    );
    expect(find.text('ลองอีกครั้ง'), findsOneWidget);
    expect(find.byKey(const ValueKey('sample-pork')), findsNothing);
  });
}

class _UnavailableRepository implements FoodPreferencesRepository {
  @override
  Future<FoodPreferences> load() async =>
      throw StateError('storage unavailable');
  @override
  Future<void> save(FoodPreferences preferences) async {}
}

class _RetryRepository implements FoodPreferencesRepository {
  bool fail = true;
  FoodPreferences saved = FoodPreferences();
  @override
  Future<FoodPreferences> load() async => saved;
  @override
  Future<void> save(FoodPreferences preferences) async {
    if (fail) throw StateError('storage unavailable');
    saved = preferences;
  }
}
