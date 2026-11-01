import 'meal_log.dart';

class DailyNutritionSummary {
  const DailyNutritionSummary({
    required this.mealCount,
    required this.calories,
    required this.proteinGrams,
    required this.carbsGrams,
    required this.fatGrams,
  });

  factory DailyNutritionSummary.fromMeals(Iterable<MealLog> meals) {
    var mealCount = 0;
    var calories = 0;
    var protein = 0.0;
    var carbs = 0.0;
    var fat = 0.0;
    for (final meal in meals) {
      mealCount++;
      calories += meal.nutrition.calories;
      protein += meal.nutrition.proteinGrams;
      carbs += meal.nutrition.carbsGrams;
      fat += meal.nutrition.fatGrams;
    }
    return DailyNutritionSummary(
      mealCount: mealCount,
      calories: calories,
      proteinGrams: protein,
      carbsGrams: carbs,
      fatGrams: fat,
    );
  }

  final int mealCount;
  final int calories;
  final double proteinGrams;
  final double carbsGrams;
  final double fatGrams;
}
