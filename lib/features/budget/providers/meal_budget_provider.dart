import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/meal_budget.dart';

final mealBudgetProvider = NotifierProvider<MealBudgetController, MealBudget?>(
  MealBudgetController.new,
);

class MealBudgetController extends Notifier<MealBudget?> {
  @override
  MealBudget? build() => null;

  BudgetParseResult confirmInput(String input) {
    final result = MealBudget.parseUserInput(input);
    final confirmed = result.budget;
    if (confirmed != null) state = confirmed;
    return result;
  }

  void clear() => state = null;
}
