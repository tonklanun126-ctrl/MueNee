import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:muenee/app/router/app_router.dart';
import 'package:muenee/app/theme/app_theme.dart';
import 'package:muenee/features/auth/auth_repository.dart';
import 'package:muenee/features/budget/models/meal_budget.dart';
import 'package:muenee/features/budget/providers/meal_budget_provider.dart';
import 'package:muenee/features/location/models/device_location.dart';
import 'package:muenee/features/location/providers/location_provider.dart';
import 'package:muenee/features/profile/models/food_preferences.dart';
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

  testWidgets(
    'opens restaurant detail and returns to the same recommendation',
    (tester) async {
      final container = ProviderContainer(
        overrides: [
          accountProvider.overrideWith((ref) => Stream.value(null)),
          locationProvider.overrideWith(_ReadyLocation.new),
          mealBudgetProvider.overrideWith(_BudgetController.new),
          recommendationCatalogRepositoryProvider.overrideWithValue(
            _CatalogRepository(_catalog()),
          ),
        ],
      );
      addTearDown(container.dispose);
      final router = container.read(appRouterProvider);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            theme: AppTheme.light,
            routerConfig: router,
          ),
        ),
      );
      router.go('/recommendations');
      await tester.pumpAndSettle();

      await tester.drag(find.byType(ListView), const Offset(0, -460));
      await tester.pumpAndSettle();
      await tester.tap(find.text('ดูร้าน'));
      await tester.pumpAndSettle();

      expect(find.text('รายละเอียดร้าน'), findsOneWidget);
      await tester.drag(find.byType(ListView), const Offset(0, -180));
      await tester.pumpAndSettle();
      expect(find.text('ข้าวไก่ทดสอบ'), findsOneWidget);
      await tester.drag(find.byType(ListView), const Offset(0, -360));
      await tester.pumpAndSettle();
      expect(find.text('ถนนสนามจันทร์ นครปฐม'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('open-restaurant-map')),
        200,
      );
      await tester.tap(find.byKey(const ValueKey('open-restaurant-map')));
      await tester.pumpAndSettle();
      expect(find.text('แผนที่ร้าน'), findsOneWidget);
      expect(find.text('แผนที่ยังไม่พร้อมใช้งาน'), findsOneWidget);
      expect(find.text('ถนนสนามจันทร์ นครปฐม'), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('รายละเอียดร้าน'), findsOneWidget);

      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('เมนูแนะนำ'), findsOneWidget);
      expect(find.text('ดูร้าน'), findsOneWidget);
    },
  );

  testWidgets('direct detail URL without selected result fails safely', (
    tester,
  ) async {
    final container = ProviderContainer(
      overrides: [accountProvider.overrideWith((ref) => Stream.value(null))],
    );
    addTearDown(container.dispose);
    final router = container.read(appRouterProvider);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
      ),
    );
    router.go('/restaurant/unknown/menu/unknown');
    await tester.pumpAndSettle();

    expect(find.text('เปิดรายละเอียดร้านไม่ได้'), findsOneWidget);
    expect(
      find.textContaining('ข้อมูลร้านตรงกับผลแนะนำล่าสุด'),
      findsOneWidget,
    );
  });
}

RecommendationCatalog _catalog() {
  final now = DateTime.now().toUtc();
  final restaurant = Restaurant(
    id: 'restaurant-1',
    name: 'ร้านทดสอบสนามจันทร์',
    googlePlaceId: 'place-1',
    location: const GeoPoint(13.82, 100.0443),
    address: 'ถนนสนามจันทร์ นครปฐม',
    verificationStatus: RestaurantVerificationStatus.verified,
    isActive: true,
    createdAt: now,
    updatedAt: now,
  );
  return RecommendationCatalog(
    restaurants: [restaurant],
    menus: [
      MenuItem(
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
          calories: 500,
          proteinGrams: 28,
          carbsGrams: 60,
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
      ),
    ],
  );
}

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
      latitude: 13.82,
      longitude: 100.0443,
      accuracyMeters: 8,
      measuredAt: DateTime.now().toUtc(),
      precision: DeviceLocationPrecision.precise,
    ),
  );
}

class _BudgetController extends MealBudgetController {
  @override
  MealBudget? build() => MealBudget(100);
}
