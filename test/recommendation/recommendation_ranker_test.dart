import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:muenee/features/budget/models/meal_budget.dart';
import 'package:muenee/features/location/models/device_location.dart';
import 'package:muenee/features/profile/models/food_preferences.dart';
import 'package:muenee/features/recommendation/repositories/recommendation_catalog_repository.dart';
import 'package:muenee/features/recommendation/services/recommendation_ranker.dart';
import 'package:muenee/features/restaurants/models/menu_item.dart';
import 'package:muenee/features/restaurants/models/menu_preview.dart';
import 'package:muenee/features/restaurants/models/restaurant.dart';

void main() {
  final now = DateTime.utc(2026, 9, 7);
  final location = DeviceLocation(
    latitude: 13.8199,
    longitude: 100.0443,
    accuracyMeters: 5,
    measuredAt: now,
    precision: DeviceLocationPrecision.precise,
  );
  const ranker = RecommendationRanker();

  test(
    'hard filters budget, inactive records, and orphan menus before Top 3',
    () {
      final catalog = RecommendationCatalog(
        restaurants: [
          _restaurant('near', 13.8200, 100.0443, now),
          _restaurant('inactive', 13.8201, 100.0443, now, active: false),
        ],
        menus: [
          _menu('a', 'near', 40, now),
          _menu('b', 'near', 50, now),
          _menu('c', 'near', 60, now),
          _menu('d', 'near', 70, now),
          _menu('over-budget', 'near', 81, now),
          _menu('inactive-menu', 'near', 20, now, active: false),
          _menu('inactive-restaurant', 'inactive', 20, now),
          _menu('orphan', 'missing', 20, now),
        ],
      );

      final results = ranker.rank(
        catalog: catalog,
        userLocation: location,
        budget: MealBudget(80),
        preferences: FoodPreferences(),
        now: now,
      );

      expect(results, hasLength(3));
      expect(
        results.map((item) => item.menu.id),
        everyElement(isIn(['a', 'b', 'c', 'd'])),
      );
      expect(results.every((item) => item.menu.price.amount <= 80), isTrue);
    },
  );

  test('allergy and unknown evidence are never relaxed to fill results', () {
    final results = ranker.rank(
      catalog: RecommendationCatalog(
        restaurants: [_restaurant('shop', 13.82, 100.0443, now)],
        menus: [
          _menu('declared-egg', 'shop', 50, now, allergens: {FoodAllergen.egg}),
          _menu('unknown', 'shop', 50, now, allergensKnown: false),
        ],
      ),
      userLocation: location,
      budget: MealBudget(100),
      preferences: FoodPreferences(allergies: {FoodAllergen.egg}),
      now: now,
    );

    expect(results, isEmpty);
  });

  test('disliked eligible menus always follow non-disliked menus', () {
    final results = ranker.rank(
      catalog: RecommendationCatalog(
        restaurants: [
          _restaurant('near', 13.81991, 100.0443, now),
          _restaurant('far', 13.84, 100.0443, now),
        ],
        menus: [
          _menu(
            'near-disliked',
            'near',
            40,
            now,
            ingredients: {FoodIngredient.mushroom},
          ),
          _menu('far-liked', 'far', 90, now),
        ],
      ),
      userLocation: location,
      budget: MealBudget(100),
      preferences: FoodPreferences(dislikes: {FoodIngredient.mushroom}),
      now: now,
    );

    expect(results.map((item) => item.menu.id), ['far-liked', 'near-disliked']);
    expect(results.last.isDisliked, isTrue);
  });

  test(
    'fresh verified price outranks unverified price when other inputs tie',
    () {
      final results = ranker.rank(
        catalog: RecommendationCatalog(
          restaurants: [_restaurant('shop', 13.82, 100.0443, now)],
          menus: [
            _menu('unverified', 'shop', 60, now),
            _menu(
              'verified',
              'shop',
              60,
              now,
              confidence: PriceConfidence.verified,
            ),
          ],
        ),
        userLocation: location,
        budget: MealBudget(100),
        preferences: FoodPreferences(),
        now: now,
      );

      expect(results.first.menu.id, 'verified');
    },
  );

  test(
    'distance calculation is deterministic and geographically plausible',
    () {
      final meters = RecommendationRanker.distanceMeters(0, 0, 0, 0.001);
      expect(meters, closeTo(111.2, 0.5));
    },
  );

  test(
    'diversifies shops, remains stable, and keeps dislikes behind repeats',
    () {
      final menus = [
        _menu('a-1', 'a', 40, now),
        _menu('a-2', 'a', 41, now),
        _menu('a-3', 'a', 42, now),
        _menu('b-1', 'b', 60, now),
        _menu('c-1', 'c', 70, now, ingredients: {FoodIngredient.mushroom}),
      ];
      final shops = [
        _restaurant('a', 13.8200, 100.0443, now),
        _restaurant('b', 13.8210, 100.0443, now),
        _restaurant('c', 13.8220, 100.0443, now),
      ];
      List<String> run(List<MenuItem> input, FoodPreferences preferences) =>
          ranker
              .rank(
                catalog: RecommendationCatalog(
                  restaurants: shops,
                  menus: input,
                ),
                userLocation: location,
                budget: MealBudget(100),
                preferences: preferences,
                now: now,
              )
              .map((item) => item.menu.id)
              .toList();
      expect(run(menus, FoodPreferences()), ['a-1', 'b-1', 'c-1']);
      expect(run(menus.reversed.toList(), FoodPreferences()), [
        'a-1',
        'b-1',
        'c-1',
      ]);
      expect(run(menus, FoodPreferences(dislikes: {FoodIngredient.mushroom})), [
        'a-1',
        'b-1',
        'a-2',
      ]);
    },
  );
}

Restaurant _restaurant(
  String id,
  double latitude,
  double longitude,
  DateTime now, {
  bool active = true,
}) => Restaurant(
  id: id,
  name: 'ร้าน $id',
  googlePlaceId: 'place-$id',
  location: GeoPoint(latitude, longitude),
  address: 'นครปฐม',
  verificationStatus: RestaurantVerificationStatus.verified,
  isActive: active,
  createdAt: now,
  updatedAt: now,
);

MenuItem _menu(
  String id,
  String restaurantId,
  int price,
  DateTime now, {
  bool active = true,
  bool allergensKnown = true,
  Set<FoodAllergen> allergens = const {},
  Set<FoodIngredient> ingredients = const {},
  PriceConfidence confidence = PriceConfidence.unverified,
}) => MenuItem(
  id: id,
  restaurantId: restaurantId,
  name: 'เมนู $id',
  price: MenuPrice(
    amount: price,
    confidence: confidence,
    source: confidence == PriceConfidence.verified
        ? 'https://example.com/menu'
        : null,
    verifiedAt: confidence == PriceConfidence.verified ? now : null,
  ),
  nutrition: NutritionEstimate(
    calories: 500,
    proteinGrams: 20,
    carbsGrams: 60,
    fatGrams: 15,
  ),
  tags: const ['thai'],
  ingredients: ingredients,
  allergens: allergens,
  ingredientsKnown: true,
  allergensKnown: allergensKnown,
  vegetarianConfirmed: false,
  halalConfirmed: false,
  isActive: active,
  createdAt: now,
  updatedAt: now,
);
