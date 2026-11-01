import 'package:flutter_test/flutter_test.dart';
import 'package:muenee/features/profile/models/food_preferences.dart';
import 'package:muenee/features/recommendation/services/food_preference_filter.dart';
import 'package:muenee/features/restaurants/models/menu_preview.dart';
import 'package:muenee/features/restaurants/models/sample_menus.dart';

void main() {
  final now = DateTime.utc(2026, 9, 5, 12);
  final menus = sampleMenus(now);
  const filter = FoodPreferenceFilter();

  test('no pork and no beef exclude matches and unknown ingredients', () {
    final result = filter.apply(
      menus,
      FoodPreferences(
        restrictions: {DietaryRestriction.noPork, DietaryRestriction.noBeef},
      ),
    );
    expect(result.map((m) => m.id), [
      'sample-vegetarian',
      'sample-chicken',
      'sample-egg',
    ]);
  });

  test('vegetarian allows egg but not fish, meat or unconfirmed dishes', () {
    expect(
      filter
          .apply(
            menus,
            FoodPreferences(restrictions: {DietaryRestriction.vegetarian}),
          )
          .map((m) => m.id),
      ['sample-vegetarian', 'sample-egg'],
    );
    const contradictory = MenuPreview(
      id: 'fish',
      name: 'fish',
      price: MenuPrice(amount: 1, confidence: PriceConfidence.unverified),
      vegetarianConfirmed: true,
      ingredients: {FoodIngredient.fish},
    );
    expect(
      filter.allows(
        contradictory,
        FoodPreferences(restrictions: {DietaryRestriction.vegetarian}),
      ),
      isFalse,
    );
  });

  test('no pork is not evidence of halal', () {
    expect(
      filter
          .apply(
            menus,
            FoodPreferences(restrictions: {DietaryRestriction.halalOnly}),
          )
          .map((m) => m.id),
      ['sample-chicken'],
    );
  });

  test('allergies exclude declared allergens and incomplete metadata', () {
    final result = filter.apply(
      menus,
      FoodPreferences(allergies: {FoodAllergen.egg, FoodAllergen.soy}),
    );
    expect(result, isEmpty);
    // An empty result never relaxes dietary constraints.
    expect(
      filter.apply(
        menus,
        FoodPreferences(
          restrictions: {
            DietaryRestriction.vegetarian,
            DietaryRestriction.halalOnly,
          },
        ),
      ),
      isEmpty,
    );
  });

  test('dislikes go last, or are excluded when hide is enabled', () {
    final preferences = FoodPreferences(dislikes: {FoodIngredient.mushroom});
    expect(filter.apply(menus, preferences).last.id, 'sample-vegetarian');
    expect(
      filter
          .apply(menus, preferences.copyWith(hideDisliked: true))
          .map((m) => m.id),
      ['sample-pork', 'sample-chicken', 'sample-beef', 'sample-egg'],
    );
    expect(filter.apply(menus, FoodPreferences(hideDisliked: true)).length, 6);
  });

  test('verified price expires after 30 days, with an inclusive boundary', () {
    MenuPrice priceAt(Duration age) => MenuPrice(
      amount: 50,
      confidence: PriceConfidence.verified,
      verifiedAt: now.subtract(age),
      source: 'test receipt',
    );
    expect(
      priceAt(const Duration(days: 30)).effectiveConfidence(now),
      PriceConfidence.verified,
    );
    expect(
      priceAt(const Duration(days: 30, seconds: 1)).effectiveConfidence(now),
      PriceConfidence.unverified,
    );
  });

  test('missing proof and future timestamps cannot appear verified', () {
    for (final price in [
      const MenuPrice(amount: 50, confidence: PriceConfidence.verified),
      MenuPrice(
        amount: 50,
        confidence: PriceConfidence.verified,
        verifiedAt: now,
      ),
      MenuPrice(
        amount: 50,
        confidence: PriceConfidence.verified,
        verifiedAt: now.add(const Duration(seconds: 1)),
        source: 'test',
      ),
    ]) {
      expect(price.effectiveConfidence(now), PriceConfidence.unverified);
    }
    expect(
      const MenuPrice(
        amount: 50,
        confidence: PriceConfidence.estimated,
      ).effectiveConfidence(now),
      PriceConfidence.estimated,
    );
  });
}
