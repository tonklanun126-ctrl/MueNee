import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:muenee/app/theme/app_theme.dart';
import 'package:muenee/features/auth/auth_repository.dart';
import 'package:muenee/features/profile/models/food_preferences.dart';
import 'package:muenee/features/restaurants/models/menu_item.dart';
import 'package:muenee/features/restaurants/models/menu_preview.dart';
import 'package:muenee/features/restaurants/models/restaurant.dart';
import 'package:muenee/features/restaurants/models/restaurant_detail_arguments.dart';
import 'package:muenee/features/restaurants/presentation/screens/restaurant_detail_screen.dart';
import 'package:muenee/features/tracking/providers/meal_selection_provider.dart';
import 'package:muenee/features/tracking/repositories/meal_log_repository.dart';

void main() {
  Widget app({
    RestaurantDetailArguments? details,
    Account? account,
    _FakeMealLogRepository? repository,
  }) => ProviderScope(
    overrides: [
      accountProvider.overrideWith((ref) => Stream.value(account)),
      mealLogRepositoryProvider.overrideWithValue(
        repository ?? _FakeMealLogRepository(),
      ),
    ],
    child: MaterialApp(
      theme: AppTheme.light,
      home: RestaurantDetailScreen(details: details ?? _details()),
    ),
  );

  testWidgets('shows restaurant, menu, distance and honest evidence', (
    tester,
  ) async {
    await tester.pumpWidget(app());

    expect(find.text('ภาพประกอบเมนู'), findsOneWidget);
    await tester.drag(find.byType(ListView), const Offset(0, -180));
    await tester.pumpAndSettle();
    expect(find.text('ข้าวไก่ทดสอบ'), findsOneWidget);
    expect(find.text('ร้านทดสอบสนามจันทร์'), findsOneWidget);
    await tester.drag(find.byType(ListView), const Offset(0, -360));
    await tester.pumpAndSettle();
    expect(find.text('80 บาท'), findsOneWidget);
    expect(find.text('ทางตรงประมาณ 350 เมตร'), findsOneWidget);
    expect(find.textContaining('4.8'), findsNothing);
    expect(find.textContaining('เปิดอยู่'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('price-evidence')));
    await tester.pumpAndSettle();
    expect(find.textContaining('https://example.com/price'), findsOneWidget);
    expect(find.text('ราคายืนยันแล้ว'), findsWidgets);
    expect(find.textContaining('ไม่ได้ยืนยันส่วนผสม'), findsOneWidget);
  });

  testWidgets(
    'keeps incomplete dietary evidence visible and explains meal action',
    (tester) async {
      await tester.pumpWidget(app());
      await tester.scrollUntilVisible(
        find.text('ข้อมูลส่วนผสมและสารก่อภูมิแพ้'),
        300,
      );

      expect(find.text('ส่วนผสมที่มีข้อมูล: ไก่'), findsOneWidget);
      expect(find.text('รายการส่วนผสมยังไม่ครบ'), findsOneWidget);
      expect(
        find.text('ข้อมูลสารก่อภูมิแพ้และการปนเปื้อนยังไม่ครบ'),
        findsOneWidget,
      );
      await tester.scrollUntilVisible(find.textContaining('สั่งอาหาร'), 200);
      expect(find.textContaining('สั่งอาหาร'), findsOneWidget);
      expect(find.text('เข้าสู่ระบบเพื่อบันทึกมื้อ'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'เปิดแผนที่'), findsNothing);
    },
  );

  testWidgets('remains scrollable at 320x640 and 200 percent text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await tester.pumpWidget(app());
    await tester.scrollUntilVisible(
      find.text('ข้อมูลส่วนผสมและสารก่อภูมิแพ้'),
      300,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('signed-in user confirms once and sees persistent success', (
    tester,
  ) async {
    final repository = _FakeMealLogRepository();
    await tester.pumpWidget(
      app(
        account: const Account('student@example.com', true, uid: 'owner'),
        repository: repository,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('select-meal')));
    await tester.pumpAndSettle();
    expect(find.textContaining('ไม่ได้สั่งหรือชำระ'), findsOneWidget);
    expect(find.textContaining('ประมาณ 520 kcal'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('confirm-meal-selection')));
    await tester.pumpAndSettle();

    expect(repository.calls, 1);
    expect(repository.userId, 'owner');
    expect(repository.menuId, 'menu-1');
    expect(find.text('บันทึกมื้อนี้แล้ว'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('ดูบันทึกวันนี้'), 240);
    expect(find.text('ดูบันทึกวันนี้'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('select-meal')));
    await tester.pump();
    expect(repository.calls, 1);
  });

  testWidgets('failed save is readable and can retry', (tester) async {
    final repository = _FakeMealLogRepository(fail: true);
    await tester.pumpWidget(
      app(
        account: const Account('student@example.com', false, uid: 'owner'),
        repository: repository,
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('select-meal')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('confirm-meal-selection')));
    await tester.pumpAndSettle();

    expect(find.text('บันทึกมื้อไม่สำเร็จ กรุณาลองอีกครั้ง'), findsOneWidget);
    expect(find.text('ลองบันทึกมื้อนี้อีกครั้ง'), findsOneWidget);
    repository.fail = false;
    await tester.tap(find.byKey(const ValueKey('select-meal')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('confirm-meal-selection')));
    await tester.pumpAndSettle();
    expect(repository.calls, 2);
    expect(find.text('บันทึกมื้อนี้แล้ว'), findsOneWidget);
  });
}

class _FakeMealLogRepository implements MealLogRepository {
  _FakeMealLogRepository({this.fail = false});

  bool fail;
  int calls = 0;
  String? userId;
  String? menuId;

  @override
  Future<String> createRecommendationMeal({
    required String userId,
    required MenuItem menu,
    String? imageUrl,
  }) async {
    calls++;
    this.userId = userId;
    menuId = menu.id;
    if (fail) throw StateError('SDK details');
    return 'meal-$calls';
  }
}

RestaurantDetailArguments _details() {
  final now = DateTime.utc(2026, 9, 8);
  final restaurant = Restaurant(
    id: 'restaurant-1',
    name: 'ร้านทดสอบสนามจันทร์',
    googlePlaceId: 'place-1',
    location: const GeoPoint(13.82, 100.0443),
    address: 'ถนนสนามจันทร์ นครปฐม',
    rating: 4.8,
    verificationStatus: RestaurantVerificationStatus.verified,
    isActive: true,
    createdAt: now,
    updatedAt: now,
  );
  final menu = MenuItem(
    id: 'menu-1',
    restaurantId: restaurant.id,
    name: 'ข้าวไก่ทดสอบ',
    price: MenuPrice(
      amount: 80,
      confidence: PriceConfidence.verified,
      source: 'https://example.com/price',
      verifiedAt: now,
    ),
    nutrition: NutritionEstimate(
      calories: 520,
      proteinGrams: 28,
      carbsGrams: 62,
      fatGrams: 16,
    ),
    tags: const ['rice'],
    ingredients: const {FoodIngredient.chicken},
    allergens: const {FoodAllergen.soy},
    ingredientsKnown: false,
    allergensKnown: false,
    vegetarianConfirmed: false,
    halalConfirmed: false,
    isActive: true,
    createdAt: now,
    updatedAt: now,
  );
  return RestaurantDetailArguments(
    restaurant: restaurant,
    menu: menu,
    distanceMeters: 350,
    rank: 1,
  );
}
