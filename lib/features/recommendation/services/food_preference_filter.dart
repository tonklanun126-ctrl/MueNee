import '../../profile/models/food_preferences.dart';
import '../../restaurants/models/menu_preview.dart';

class FoodPreferenceFilter {
  const FoodPreferenceFilter();

  bool isDisliked(MenuPreview menu, FoodPreferences preferences) =>
      menu.ingredients.intersection(preferences.dislikes).isNotEmpty;

  bool allows(MenuPreview menu, FoodPreferences preferences) {
    if (preferences.allergies.isNotEmpty &&
        (!menu.allergensKnown ||
            menu.allergens.intersection(preferences.allergies).isNotEmpty)) {
      return false;
    }
    final rules = preferences.restrictions;
    if (rules.contains(DietaryRestriction.halalOnly) &&
        (!menu.halalConfirmed ||
            menu.ingredients.contains(FoodIngredient.pork))) {
      return false;
    }
    if (rules.contains(DietaryRestriction.vegetarian) &&
        (!menu.vegetarianConfirmed ||
            menu.ingredients.any(
              const {
                FoodIngredient.pork,
                FoodIngredient.beef,
                FoodIngredient.chicken,
                FoodIngredient.fish,
                FoodIngredient.shellfish,
                FoodIngredient.offal,
              }.contains,
            ))) {
      return false;
    }
    if (rules.contains(DietaryRestriction.noPork) &&
        (!menu.ingredientsKnown ||
            menu.ingredients.contains(FoodIngredient.pork))) {
      return false;
    }
    if (rules.contains(DietaryRestriction.noBeef) &&
        (!menu.ingredientsKnown ||
            menu.ingredients.contains(FoodIngredient.beef))) {
      return false;
    }
    if (preferences.hideDisliked &&
        preferences.dislikes.isNotEmpty &&
        (!menu.ingredientsKnown || isDisliked(menu, preferences))) {
      return false;
    }
    return true;
  }

  List<MenuPreview> apply(
    List<MenuPreview> menus,
    FoodPreferences preferences,
  ) {
    final allowed = menus.where((menu) => allows(menu, preferences)).toList();
    // Stable partition: disliked items follow other eligible items.
    return [
      ...allowed.where((menu) => !isDisliked(menu, preferences)),
      ...allowed.where((menu) => isDisliked(menu, preferences)),
    ];
  }
}
