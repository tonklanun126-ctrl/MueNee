import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:muenee/features/budget/models/meal_budget.dart';
import 'package:muenee/features/budget/providers/meal_budget_provider.dart';
import 'package:muenee/features/location/models/device_location.dart';
import 'package:muenee/features/location/providers/location_provider.dart';
import 'package:muenee/features/recommendation/presentation/screens/recommendation_results_screen.dart';
import 'package:muenee/features/recommendation/providers/recommendation_provider.dart';
import 'package:muenee/features/recommendation/repositories/recommendation_catalog_repository.dart';
import 'package:muenee/features/restaurants/models/menu_item.dart';
import 'package:muenee/features/restaurants/models/menu_preview.dart';
import 'package:muenee/features/restaurants/models/restaurant.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  Widget app({bool empty = false, bool failure = false}) => ProviderScope(
    overrides: [
      locationProvider.overrideWith(_ReadyLocation.new),
      mealBudgetProvider.overrideWith(_BudgetController.new),
      recommendationCatalogRepositoryProvider.overrideWithValue(
        _CatalogRepository(_catalog()),
      ),
      if (empty) recommendationProvider.overrideWith((ref) async => const []),
      if (failure)
        recommendationProvider.overrideWith(
          (ref) => Future.error(StateError('sensitive SDK details')),
        ),
    ],
    child: const MaterialApp(home: RecommendationResultsScreen()),
  );

  testWidgets('shows only deterministic Top 3 with evidence and estimates', (
    tester,
  ) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    expect(find.text('3 เมนูสำหรับมื้อนี้'), findsOneWidget);
    expect(find.byKey(const ValueKey('recommendation-menu-1')), findsOneWidget);
    await tester.drag(find.byType(ListView), const Offset(0, -420));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('restaurant-menu-1')), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('recommendation-menu-3')),
      300,
    );
    expect(find.byKey(const ValueKey('recommendation-menu-3')), findsOneWidget);
    expect(find.byKey(const ValueKey('recommendation-menu-4')), findsNothing);
    expect(find.textContaining('ประมาณ 500 kcal'), findsWidgets);
    expect(find.textContaining('ราคา'), findsWidgets);
  });

  testWidgets(
    'missing location blocks catalog loading with a recovery action',
    (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: RecommendationResultsScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('ต้องมีตำแหน่งก่อน'), findsOneWidget);
      expect(find.text('ไปตั้งค่าตำแหน่ง'), findsOneWidget);
    },
  );

  testWidgets('explanation opens source evidence and closes back to results', (
    tester,
  ) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    final action = find.byKey(const ValueKey('explain-menu-1'));
    await tester.ensureVisible(action);
    await tester.tap(action);
    await tester.pumpAndSettle();
    expect(find.textContaining('https://example.com/menu'), findsOneWidget);
    expect(find.textContaining('ไม่ได้ยืนยันส่วนผสม'), findsOneWidget);
    await tester.ensureVisible(find.text('ปิด'));
    await tester.tap(find.text('ปิด'));
    await tester.pumpAndSettle();
    expect(find.textContaining('https://example.com/menu'), findsNothing);
    expect(find.byType(RecommendationResultsScreen), findsOneWidget);
  });

  testWidgets(
    'ready location without budget shows the budget recovery action',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [locationProvider.overrideWith(_ReadyLocation.new)],
          child: const MaterialApp(home: RecommendationResultsScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('ต้องกำหนดงบก่อน'), findsOneWidget);
      expect(find.text('ไปกำหนดงบ'), findsOneWidget);
    },
  );

  testWidgets('empty state never relaxes safety filters', (tester) async {
    await tester.pumpWidget(app(empty: true));
    await tester.pumpAndSettle();

    expect(find.text('ยังไม่พบเมนูที่ตรงครบทุกเงื่อนไข'), findsOneWidget);
    expect(find.textContaining('ไม่ลดข้อจำกัด'), findsOneWidget);
  });

  testWidgets('catalog failure is readable and hides technical details', (
    tester,
  ) async {
    await tester.pumpWidget(app(failure: true));
    await tester.pumpAndSettle();

    expect(
      find.text('โหลดเมนูไม่สำเร็จ ข้อมูลเดิมไม่ได้ถูกแก้ไข'),
      findsOneWidget,
    );
    expect(find.textContaining('sensitive SDK details'), findsNothing);
    expect(find.text('ลองอีกครั้ง'), findsOneWidget);
  });

  testWidgets('results remain scrollable at 320x640 and 200 percent text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('recommendation-menu-3')),
      300,
    );
    expect(tester.takeException(), isNull);
  });
}

RecommendationCatalog _catalog() {
  final now = DateTime.utc(2026, 9, 7);
  final restaurant = Restaurant(
    id: 'shop',
    name: 'ร้านทดสอบ',
    googlePlaceId: 'place-shop',
    location: const GeoPoint(13.8200, 100.0443),
    address: 'นครปฐม',
    rating: 4.5,
    verificationStatus: RestaurantVerificationStatus.verified,
    isActive: true,
    createdAt: now,
    updatedAt: now,
  );
  return RecommendationCatalog(
    restaurants: [restaurant],
    menus: [for (var index = 1; index <= 4; index++) _menu(index, now)],
  );
}

MenuItem _menu(int index, DateTime now) => MenuItem(
  id: 'menu-$index',
  restaurantId: 'shop',
  name: 'เมนู $index',
  price: MenuPrice(
    amount: 30 + index,
    confidence: PriceConfidence.verified,
    source: 'https://example.com/menu',
    verifiedAt: now,
  ),
  nutrition: NutritionEstimate(
    calories: 500,
    proteinGrams: 20,
    carbsGrams: 60,
    fatGrams: 15,
  ),
  tags: const ['thai'],
  ingredients: const {},
  allergens: const {},
  ingredientsKnown: true,
  allergensKnown: true,
  vegetarianConfirmed: false,
  halalConfirmed: false,
  isActive: true,
  createdAt: now,
  updatedAt: now,
);

class _CatalogRepository implements RecommendationCatalogRepository {
  const _CatalogRepository(this.catalog);

  final RecommendationCatalog catalog;

  @override
  Future<RecommendationCatalog> loadActiveCatalog() async => catalog;
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

class _BudgetController extends MealBudgetController {
  @override
  MealBudget? build() => MealBudget(100);
}
