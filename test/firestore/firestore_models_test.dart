import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:muenee/features/profile/models/food_preferences.dart';
import 'package:muenee/features/profile/models/user_document.dart';
import 'package:muenee/features/profile/models/user_profile.dart';
import 'package:muenee/features/restaurants/models/menu_item.dart';
import 'package:muenee/features/restaurants/models/menu_preview.dart';
import 'package:muenee/features/restaurants/models/restaurant.dart';
import 'package:muenee/features/tracking/models/meal_log.dart';

void main() {
  final createdAt = DateTime.utc(2026, 9, 6, 2, 30);
  final updatedAt = createdAt.add(const Duration(minutes: 10));

  test(
    'user document preserves local profile and food preference contracts',
    () {
      final user = UserDocument(
        id: 'user-1',
        displayName: 'ต้นกล้า',
        profile: UserProfile(
          age: 21,
          heightCm: 172.5,
          weightKg: 68,
          activityLevel: ActivityLevel.moderatelyActive,
        ),
        preferences: FoodPreferences(
          restrictions: {DietaryRestriction.halalOnly},
          dislikes: {FoodIngredient.coriander},
          allergies: {FoodAllergen.peanut},
          hideDisliked: true,
        ),
        targetCalories: 2200,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

      final decoded = UserDocument.fromFirestore('user-1', user.toFirestore());

      expect(decoded.toFirestore(), user.toFirestore());
      expect(decoded.profile.activityLevel, ActivityLevel.moderatelyActive);
      expect(decoded.preferences.allergies, {FoodAllergen.peanut});
    },
  );

  test('restaurant round-trips GeoPoint and verification state', () {
    final restaurant = Restaurant(
      id: 'restaurant-1',
      name: 'ร้านทดสอบ',
      googlePlaceId: 'place-1',
      location: const GeoPoint(13.8199, 100.0443),
      address: 'นครปฐม',
      rating: 4.5,
      verificationStatus: RestaurantVerificationStatus.verified,
      isActive: true,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );

    final decoded = Restaurant.fromFirestore(
      restaurant.id,
      restaurant.toFirestore(),
    );

    expect(decoded.toFirestore(), restaurant.toFirestore());
  });

  test('menu item round-trips dietary evidence and price proof', () {
    final menu = MenuItem(
      id: 'menu-1',
      restaurantId: 'restaurant-1',
      name: 'ข้าวกะเพราไก่',
      price: MenuPrice(
        amount: 55,
        confidence: PriceConfidence.verified,
        source: 'หน้าร้าน',
        verifiedAt: updatedAt,
      ),
      nutrition: NutritionEstimate(
        calories: 520,
        proteinGrams: 24,
        carbsGrams: 62,
        fatGrams: 18,
      ),
      tags: const ['rice', 'thai'],
      ingredients: {FoodIngredient.chicken},
      allergens: {FoodAllergen.soy},
      ingredientsKnown: true,
      allergensKnown: true,
      vegetarianConfirmed: false,
      halalConfirmed: true,
      isActive: true,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );

    final decoded = MenuItem.fromFirestore(menu.id, menu.toFirestore());

    expect(decoded.toFirestore(), menu.toFirestore());
    expect(decoded.ingredients, {FoodIngredient.chicken});
    expect(decoded.allergens, {FoodAllergen.soy});
  });

  test('meal log maps food_scan without changing its persisted value', () {
    final meal = MealLog(
      id: 'meal-1',
      userId: 'user-1',
      source: MealSource.foodScan,
      foodName: 'ข้าวผัด',
      nutrition: NutritionEstimate(
        calories: 450,
        proteinGrams: 16,
        carbsGrams: 68,
        fatGrams: 12,
      ),
      imageUrl: 'https://example.test/meal.jpg',
      createdAt: createdAt,
    );

    final encoded = meal.toFirestore();
    final decoded = MealLog.fromFirestore(meal.id, encoded);

    expect(encoded['source'], 'food_scan');
    expect(decoded.toFirestore(), encoded);
  });

  test('models reject unsupported versions and malformed enum values', () {
    expect(
      () => UserDocument.fromFirestore('user-1', {'schemaVersion': 2}),
      throwsFormatException,
    );
    expect(
      () => MealLog.fromFirestore('meal-1', {
        'schemaVersion': 1,
        'userId': 'user-1',
        'source': 'unknown',
        'foodName': 'test',
        'nutrition': {
          'calories': 1,
          'proteinGrams': 1,
          'carbsGrams': 1,
          'fatGrams': 1,
        },
        'createdAt': Timestamp.fromDate(createdAt),
      }),
      throwsFormatException,
    );
  });

  test('persisted verified prices require current source evidence', () {
    MenuItem build(MenuPrice price) => MenuItem(
      id: 'menu-1',
      restaurantId: 'restaurant-1',
      name: 'Test menu',
      price: price,
      nutrition: NutritionEstimate(
        calories: 1,
        proteinGrams: 1,
        carbsGrams: 1,
        fatGrams: 1,
      ),
      tags: const [],
      ingredients: const {},
      allergens: const {},
      ingredientsKnown: false,
      allergensKnown: false,
      vegetarianConfirmed: false,
      halalConfirmed: false,
      isActive: true,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );

    expect(
      () => build(
        const MenuPrice(amount: 50, confidence: PriceConfidence.verified),
      ),
      throwsFormatException,
    );
    expect(
      () => build(
        MenuPrice(
          amount: 50,
          confidence: PriceConfidence.verified,
          source: 'old receipt',
          verifiedAt: updatedAt.subtract(const Duration(days: 31)),
        ),
      ),
      throwsFormatException,
    );
  });
}
