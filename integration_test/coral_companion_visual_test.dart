import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:muenee/app/app.dart';
import 'package:muenee/app/theme/app_theme.dart';
import 'package:muenee/features/auth/auth_repository.dart';
import 'package:muenee/features/budget/models/meal_budget.dart';
import 'package:muenee/features/budget/presentation/budget_screen.dart';
import 'package:muenee/features/budget/providers/meal_budget_provider.dart';
import 'package:muenee/features/food_scan/models/food_scan_result.dart';
import 'package:muenee/features/food_scan/presentation/food_scan_screen.dart';
import 'package:muenee/features/food_scan/providers/food_scan_provider.dart';
import 'package:muenee/features/location/models/device_location.dart';
import 'package:muenee/features/location/providers/location_provider.dart';
import 'package:muenee/features/privacy/presentation/privacy_settings_screen.dart';
import 'package:muenee/features/profile/models/food_preferences.dart';
import 'package:muenee/features/profile/presentation/screens/food_preferences_screen.dart';
import 'package:muenee/features/recommendation/presentation/screens/recommendation_results_screen.dart';
import 'package:muenee/features/recommendation/providers/recommendation_provider.dart';
import 'package:muenee/features/recommendation/repositories/recommendation_catalog_repository.dart';
import 'package:muenee/features/restaurants/models/menu_item.dart';
import 'package:muenee/features/restaurants/models/menu_preview.dart';
import 'package:muenee/features/restaurants/models/restaurant.dart';
import 'package:muenee/features/restaurants/models/restaurant_detail_arguments.dart';
import 'package:muenee/features/restaurants/presentation/screens/restaurant_detail_screen.dart';
import 'package:muenee/features/tracking/models/meal_log.dart';
import 'package:muenee/features/tracking/presentation/daily_tracking_screen.dart';
import 'package:muenee/features/tracking/providers/daily_tracking_provider.dart';
import 'package:muenee/features/tracking/repositories/meal_log_repository.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  var surfaceConverted = false;

  Future<void> capture(WidgetTester tester, String name) async {
    expect(tester.takeException(), isNull);
    if (!surfaceConverted) {
      await binding.convertFlutterSurfaceToImage();
      surfaceConverted = true;
    }
    await tester.pumpAndSettle();
    await binding.takeScreenshot(name);
  }

  setUp(() {
    surfaceConverted = false;
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  testWidgets('home and budget visual states', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: MueNeeApp()));
    await tester.pumpAndSettle();
    expect(find.text('มื้อนี้กินอะไรดี?'), findsOneWidget);
    await capture(tester, 'coral-home');

    await tester.ensureVisible(find.text('฿60').first);
    await tester.tap(find.text('฿60').first);
    await tester.pumpAndSettle();
    expect(find.byType(BudgetScreen), findsOneWidget);
    await capture(tester, 'coral-budget');
  });

  testWidgets('preferences visual state', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.light,
          home: FoodPreferencesScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('เลือกให้ตรงกับมื้อของคุณ'), findsOneWidget);
    await capture(tester, 'coral-preferences');
  });

  testWidgets('recommendation visual state uses isolated catalog fixture', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          locationProvider.overrideWith(_ReadyLocation.new),
          mealBudgetProvider.overrideWith(_BudgetController.new),
          recommendationCatalogRepositoryProvider.overrideWithValue(
            _CatalogRepository(_catalog()),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const RecommendationResultsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('3 ตัวเลือกที่เหมาะกับมื้อนี้'), findsOneWidget);
    await capture(tester, 'coral-recommendations');
  });

  testWidgets('privacy settings visual state', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.light,
          home: PrivacySettingsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('ข้อมูลและความเป็นส่วนตัว'), findsOneWidget);
    await capture(tester, 'coral-settings');
  });

  testWidgets('restaurant detail visual state', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [accountProvider.overrideWith((ref) => Stream.value(null))],
        child: MaterialApp(
          theme: AppTheme.light,
          home: RestaurantDetailScreen(details: _details()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('ข้าวกะเพราไก่'), findsOneWidget);
    await capture(tester, 'coral-restaurant-detail');
  });

  testWidgets('tracking visual state uses local meal fixture', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          accountProvider.overrideWith(
            (ref) => Stream.value(
              const Account('visual@example.test', true, uid: 'visual-owner'),
            ),
          ),
          dailyMealLogRepositoryProvider.overrideWithValue(
            _VisualMealRepository(),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: DailyTrackingScreen(referenceNow: DateTime(2026, 9, 27, 12)),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('มื้อที่บันทึก (2)'), findsOneWidget);
    await capture(tester, 'coral-tracking');
  });

  testWidgets('AI review visual state performs no analysis or write', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          accountProvider.overrideWith(
            (ref) => Stream.value(
              const Account('visual@example.test', true, uid: 'visual-owner'),
            ),
          ),
          foodScanProvider.overrideWith(_ReviewScanController.new),
        ],
        child: MaterialApp(theme: AppTheme.light, home: const FoodScanScreen()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('ตรวจและแก้ค่าประมาณ'), 240);
    await tester.pumpAndSettle();
    expect(find.text('ตรวจและแก้ค่าประมาณ'), findsOneWidget);
    await capture(tester, 'coral-ai-review');
  });
}

RestaurantDetailArguments _details() {
  final now = DateTime.now().toUtc();
  final restaurant = Restaurant(
    id: 'visual-restaurant',
    name: 'ร้านตัวอย่างสำหรับตรวจหน้าจอ',
    googlePlaceId: 'visual-only',
    location: const GeoPoint(13.82, 100.0443),
    address: 'นครปฐม',
    verificationStatus: RestaurantVerificationStatus.verified,
    isActive: true,
    createdAt: now,
    updatedAt: now,
  );
  return RestaurantDetailArguments(
    restaurant: restaurant,
    menu: MenuItem(
      id: 'visual-detail-menu',
      restaurantId: restaurant.id,
      name: 'ข้าวกะเพราไก่',
      price: MenuPrice(
        amount: 60,
        confidence: PriceConfidence.estimated,
        source: 'ข้อมูลจำลองสำหรับตรวจ UI',
      ),
      nutrition: NutritionEstimate(
        calories: 540,
        proteinGrams: 28,
        carbsGrams: 65,
        fatGrams: 18,
      ),
      tags: const ['thai'],
      ingredients: const {FoodIngredient.chicken},
      allergens: const {},
      ingredientsKnown: false,
      allergensKnown: false,
      vegetarianConfirmed: false,
      halalConfirmed: false,
      isActive: true,
      createdAt: now,
      updatedAt: now,
    ),
    distanceMeters: 620,
    rank: 1,
  );
}

class _VisualMealRepository implements DailyMealLogRepository {
  @override
  Stream<List<MealLog>> watchMealsForDay({
    required String userId,
    required DateTime localDay,
    int limit = 50,
  }) => Stream.value([
    MealLog(
      id: 'visual-meal-1',
      userId: userId,
      source: MealSource.recommendation,
      foodName: 'ข้าวกะเพราไก่',
      nutrition: NutritionEstimate(
        calories: 540,
        proteinGrams: 28,
        carbsGrams: 65,
        fatGrams: 18,
      ),
      createdAt: DateTime(2026, 9, 27, 12, 30).toUtc(),
    ),
    MealLog(
      id: 'visual-meal-2',
      userId: userId,
      source: MealSource.foodScan,
      foodName: 'ต้มจืดเต้าหู้',
      nutrition: NutritionEstimate(
        calories: 310,
        proteinGrams: 15,
        carbsGrams: 44,
        fatGrams: 8,
      ),
      createdAt: DateTime(2026, 9, 27, 18, 15).toUtc(),
    ),
  ]);
}

class _ReviewScanController extends FoodScanController {
  @override
  FoodScanState build() => FoodScanState(
    status: FoodScanStatus.review,
    image: FoodScanImage(
      bytes: Uint8List.fromList(
        base64Decode(
          'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',
        ),
      ),
      mimeType: 'image/png',
      displayName: 'visual-fixture.png',
    ),
    result: FoodScanResult(
      foodName: 'ข้าวกะเพราไก่',
      nutrition: NutritionEstimate(
        calories: 540,
        proteinGrams: 28,
        carbsGrams: 65,
        fatGrams: 18,
      ),
      assumption: 'ข้อมูลจำลองสำหรับตรวจหน้าจอเท่านั้น',
    ),
  );
}

RecommendationCatalog _catalog() {
  final now = DateTime.now().toUtc();
  final restaurant = Restaurant(
    id: 'visual-shop',
    name: 'ร้านตัวอย่างสำหรับตรวจหน้าจอ',
    googlePlaceId: 'visual-only',
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
    menus: [
      for (var index = 1; index <= 3; index++)
        MenuItem(
          id: 'visual-menu-$index',
          restaurantId: restaurant.id,
          name: ['ข้าวกะเพราไก่', 'ข้าวไข่เจียว', 'ก๋วยเตี๋ยวหมู'][index - 1],
          price: MenuPrice(
            amount: 40 + 10 * index,
            confidence: PriceConfidence.verified,
            source: 'ภาพเมนูจำลองสำหรับตรวจ UI',
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
      latitude: 13.8199,
      longitude: 100.0443,
      accuracyMeters: 5,
      measuredAt: DateTime.now().toUtc(),
      precision: DeviceLocationPrecision.precise,
    ),
  );
}

class _BudgetController extends MealBudgetController {
  @override
  MealBudget? build() => MealBudget(100);
}
