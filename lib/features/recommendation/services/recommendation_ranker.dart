import 'dart:math' as math;

import '../../budget/models/meal_budget.dart';
import '../../location/models/device_location.dart';
import '../../profile/models/food_preferences.dart';
import '../../restaurants/models/menu_item.dart';
import '../../restaurants/models/menu_preview.dart';
import '../models/ranked_menu_recommendation.dart';
import '../repositories/recommendation_catalog_repository.dart';
import 'food_preference_filter.dart';

class RecommendationRanker {
  const RecommendationRanker({
    this.preferenceFilter = const FoodPreferenceFilter(),
  });

  final FoodPreferenceFilter preferenceFilter;

  List<RankedMenuRecommendation> rank({
    required RecommendationCatalog catalog,
    required DeviceLocation userLocation,
    required MealBudget budget,
    required FoodPreferences preferences,
    required DateTime now,
    int limit = 3,
  }) {
    if (limit < 0) throw ArgumentError.value(limit, 'limit');
    final restaurants = {
      for (final restaurant in catalog.restaurants)
        if (restaurant.isActive) restaurant.id: restaurant,
    };
    final candidates = <RankedMenuRecommendation>[];

    for (final menu in catalog.menus) {
      final restaurant = restaurants[menu.restaurantId];
      if (!menu.isActive ||
          restaurant == null ||
          menu.price.amount > budget.amountBaht) {
        continue;
      }
      final preview = _asPreview(menu);
      if (!preferenceFilter.allows(preview, preferences)) continue;

      final distance = distanceMeters(
        userLocation.latitude,
        userLocation.longitude,
        restaurant.location.latitude,
        restaurant.location.longitude,
      );
      final disliked = preferenceFilter.isDisliked(preview, preferences);
      candidates.add(
        RankedMenuRecommendation(
          menu: menu,
          restaurant: restaurant,
          distanceMeters: distance,
          isDisliked: disliked,
          score: RecommendationScore(
            distance: 45 * (1 - math.min(distance / 5000, 1)),
            affordability: 20 * (1 - (menu.price.amount / budget.amountBaht)),
            priceConfidence: switch (menu.price.effectiveConfidence(now)) {
              PriceConfidence.verified => 25,
              PriceConfidence.estimated => 12,
              PriceConfidence.unverified => 0,
            },
            preference: disliked ? 0 : 10,
          ),
        ),
      );
    }

    candidates.sort((left, right) {
      // Preserve the approved soft-preference rule: disliked items always
      // follow every otherwise-eligible non-disliked item.
      final byDislike = _boolValue(left.isDisliked)
          .compareTo(_boolValue(right.isDisliked));
      if (byDislike != 0) return byDislike;
      final byScore = right.score.total.compareTo(left.score.total);
      if (byScore != 0) return byScore;
      final byDistance = left.distanceMeters.compareTo(right.distanceMeters);
      if (byDistance != 0) return byDistance;
      final byPrice = left.menu.price.amount.compareTo(right.menu.price.amount);
      if (byPrice != 0) return byPrice;
      final byName = left.menu.name.compareTo(right.menu.name);
      return byName != 0 ? byName : left.menu.id.compareTo(right.menu.id);
    });
    final selected = <RankedMenuRecommendation>[];
    final selectedIds = <String>{};
    final usedRestaurants = <String>{};
    for (final disliked in [false, true]) {
      final tier = candidates.where((item) => item.isDisliked == disliked);
      for (final item in tier) {
        if (selected.length == limit) break;
        if (usedRestaurants.add(item.restaurant.id)) {
          selected.add(item);
          selectedIds.add(item.menu.id);
        }
      }
      for (final item in tier) {
        if (selected.length == limit) break;
        if (selectedIds.add(item.menu.id)) selected.add(item);
      }
      if (selected.length == limit) break;
    }
    return List.unmodifiable(selected);
  }

  static int _boolValue(bool value) => value ? 1 : 0;

  static MenuPreview _asPreview(MenuItem menu) => MenuPreview(
    id: menu.id,
    name: menu.name,
    price: menu.price,
    ingredients: menu.ingredients,
    allergens: menu.allergens,
    ingredientsKnown: menu.ingredientsKnown,
    allergensKnown: menu.allergensKnown,
    vegetarianConfirmed: menu.vegetarianConfirmed,
    halalConfirmed: menu.halalConfirmed,
  );

  static double distanceMeters(
    double fromLatitude,
    double fromLongitude,
    double toLatitude,
    double toLongitude,
  ) {
    const earthRadiusMeters = 6371000.0;
    final latitudeDelta = _radians(toLatitude - fromLatitude);
    final longitudeDelta = _radians(toLongitude - fromLongitude);
    final a =
        math.sin(latitudeDelta / 2) * math.sin(latitudeDelta / 2) +
        math.cos(_radians(fromLatitude)) *
            math.cos(_radians(toLatitude)) *
            math.sin(longitudeDelta / 2) *
            math.sin(longitudeDelta / 2);
    final normalized = a.clamp(0.0, 1.0);
    return earthRadiusMeters *
        2 *
        math.atan2(math.sqrt(normalized), math.sqrt(1 - normalized));
  }

  static double _radians(double degrees) => degrees * math.pi / 180;
}
