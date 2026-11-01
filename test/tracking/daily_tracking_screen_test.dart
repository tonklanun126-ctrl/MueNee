import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:muenee/app/theme/app_theme.dart';
import 'package:muenee/features/auth/auth_repository.dart';
import 'package:muenee/features/restaurants/models/menu_item.dart';
import 'package:muenee/features/tracking/models/meal_log.dart';
import 'package:muenee/features/tracking/presentation/daily_tracking_screen.dart';
import 'package:muenee/features/tracking/providers/daily_tracking_provider.dart';
import 'package:muenee/features/tracking/repositories/meal_log_repository.dart';

void main() {
  final today = DateTime(2026, 9, 10);

  Widget app({
    Account? account = const Account('student@example.com', true, uid: 'owner'),
    required _FakeDailyMealLogRepository repository,
  }) => ProviderScope(
    overrides: [
      accountProvider.overrideWith((ref) => Stream.value(account)),
      dailyMealLogRepositoryProvider.overrideWithValue(repository),
    ],
    child: MaterialApp(
      theme: AppTheme.light,
      home: DailyTrackingScreen(initialDay: today, referenceNow: today),
    ),
  );

  testWidgets('signed-out state protects private tracking data', (
    tester,
  ) async {
    final repository = _FakeDailyMealLogRepository();
    await tester.pumpWidget(app(account: null, repository: repository));
    await tester.pumpAndSettle();

    expect(find.text('เข้าสู่ระบบเพื่อดูบันทึก'), findsOneWidget);
    expect(find.textContaining('ข้อมูลส่วนตัว'), findsOneWidget);
    expect(find.text('เข้าสู่ระบบ'), findsOneWidget);
    expect(repository.requests, isEmpty);
  });

  testWidgets('summarizes and lists meals with neutral estimate copy', (
    tester,
  ) async {
    final repository = _FakeDailyMealLogRepository(
      mealsByDay: {
        _dayKey(today): [
          _meal('meal-2', 'ข้าวไก่', 520, 28, 62, 16, 12, 30),
          _meal('meal-1', 'โจ๊กหมู', 310, 15, 44, 8, 8, 15),
        ],
      },
    );
    await tester.pumpWidget(app(repository: repository));
    await tester.pumpAndSettle();

    expect(find.text('วันนี้'), findsOneWidget);
    expect(find.text('10 ก.ย. 2569'), findsOneWidget);
    expect(find.text('ประมาณ 830 kcal'), findsOneWidget);
    expect(find.text('โปรตีน 43 กรัม'), findsOneWidget);
    expect(find.text('คาร์บ 106 กรัม'), findsOneWidget);
    expect(find.text('ไขมัน 24 กรัม'), findsOneWidget);
    expect(
      find.textContaining('ไม่ใช่เป้าหมายหรือคำแนะนำทางการแพทย์'),
      findsOneWidget,
    );
    expect(find.text('มื้อที่บันทึก (2)'), findsOneWidget);
    expect(find.text('ข้าวไก่'), findsOneWidget);
    expect(find.text('โจ๊กหมู'), findsOneWidget);
    expect(find.textContaining('จากเมนูแนะนำ'), findsNWidgets(2));
    expect(repository.requests.single.userId, 'owner');
  });

  testWidgets('moves to an earlier day and never enables a future day', (
    tester,
  ) async {
    final repository = _FakeDailyMealLogRepository();
    await tester.pumpWidget(app(repository: repository));
    await tester.pumpAndSettle();

    final next = tester.widget<IconButton>(
      find.byKey(const ValueKey('next-tracking-day')),
    );
    expect(next.onPressed, isNull);
    await tester.tap(find.byKey(const ValueKey('previous-tracking-day')));
    await tester.pumpAndSettle();

    expect(find.text('วันพุธ'), findsOneWidget);
    expect(find.text('9 ก.ย. 2569'), findsOneWidget);
    expect(repository.requests, hasLength(2));
    expect(repository.requests.last.localDay, DateTime(2026, 9, 9));
    expect(
      tester
          .widget<IconButton>(find.byKey(const ValueKey('next-tracking-day')))
          .onPressed,
      isNotNull,
    );
  });

  testWidgets('empty and failed states remain actionable', (tester) async {
    final repository = _FakeDailyMealLogRepository(failuresRemaining: 1);
    await tester.pumpWidget(app(repository: repository));
    await tester.pumpAndSettle();

    expect(find.text('โหลดบันทึกไม่สำเร็จ'), findsOneWidget);
    expect(find.textContaining('ข้อมูลเดิมไม่ถูกลบ'), findsOneWidget);
    await tester.tap(find.text('ลองโหลดอีกครั้ง'));
    await tester.pumpAndSettle();

    expect(repository.requests, hasLength(2));
    expect(find.text('ยังไม่มีมื้อที่บันทึกในวันนี้'), findsOneWidget);
    expect(find.text('ให้ MueNee ช่วยเลือกมื้อ'), findsOneWidget);
  });

  testWidgets('small screen with 200 percent text remains usable', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final repository = _FakeDailyMealLogRepository(
      mealsByDay: {
        _dayKey(today): [
          _meal(
            'meal-long',
            'ข้าวไก่ทดสอบชื่อยาวสำหรับตรวจการตัดบรรทัด',
            520,
            28.5,
            62.5,
            16.5,
            12,
            30,
          ),
        ],
      },
    );

    await tester.pumpWidget(app(repository: repository));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('ข้าวไก่ทดสอบชื่อยาวสำหรับตรวจการตัดบรรทัด'),
      160,
    );

    expect(
      find.text('ข้าวไก่ทดสอบชื่อยาวสำหรับตรวจการตัดบรรทัด'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}

class _FakeDailyMealLogRepository implements DailyMealLogRepository {
  _FakeDailyMealLogRepository({
    this.mealsByDay = const {},
    this.failuresRemaining = 0,
  });

  final Map<String, List<MealLog>> mealsByDay;
  int failuresRemaining;
  final List<DailyMealRequest> requests = [];

  @override
  Stream<List<MealLog>> watchMealsForDay({
    required String userId,
    required DateTime localDay,
    int limit = 50,
  }) {
    requests.add(DailyMealRequest(userId: userId, localDay: localDay));
    if (failuresRemaining > 0) {
      failuresRemaining--;
      return Stream.error(StateError('SDK details'));
    }
    return Stream.value(mealsByDay[_dayKey(localDay)] ?? const []);
  }
}

MealLog _meal(
  String id,
  String name,
  int calories,
  double protein,
  double carbs,
  double fat,
  int hour,
  int minute,
) => MealLog(
  id: id,
  userId: 'owner',
  source: MealSource.recommendation,
  foodName: name,
  nutrition: NutritionEstimate(
    calories: calories,
    proteinGrams: protein,
    carbsGrams: carbs,
    fatGrams: fat,
  ),
  menuId: 'menu-$id',
  restaurantId: 'restaurant-$id',
  createdAt: DateTime(2026, 9, 10, hour, minute).toUtc(),
);

String _dayKey(DateTime value) => '${value.year}-${value.month}-${value.day}';
