import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:muenee/features/budget/models/meal_budget.dart';
import 'package:muenee/features/budget/providers/meal_budget_provider.dart';

void main() {
  group('MealBudget', () {
    test('accepts whole baht, thousands separators, and Thai digits', () {
      expect(MealBudget.parseUserInput('80').budget?.amountBaht, 80);
      expect(MealBudget.parseUserInput('1,000').budget?.amountBaht, 1000);
      expect(MealBudget.parseUserInput('๒๕๐').budget?.amountBaht, 250);
      expect(MealBudget.parseUserInput(' ๙๙ ').budget?.amountBaht, 99);
    });

    test('rejects decimals, text, and malformed thousands separators', () {
      for (final input in ['80.5', 'แปดสิบ', '1,00', '10 0', '-50']) {
        final result = MealBudget.parseUserInput(input);
        expect(result.isValid, isFalse, reason: input);
        expect(result.error, BudgetInputError.invalidFormat, reason: input);
      }
    });

    test('distinguishes empty, below-minimum, and above-maximum values', () {
      expect(MealBudget.parseUserInput('').error, BudgetInputError.empty);
      expect(
        MealBudget.parseUserInput('0').error,
        BudgetInputError.belowMinimum,
      );
      expect(
        MealBudget.parseUserInput('10,001').error,
        BudgetInputError.aboveMaximum,
      );
    });

    test('constructor enforces the same range invariant', () {
      expect(MealBudget(1).amountBaht, 1);
      expect(MealBudget(10000).amountBaht, 10000);
      expect(() => MealBudget(0), throwsRangeError);
      expect(() => MealBudget(10001), throwsRangeError);
    });
  });

  group('MealBudgetController', () {
    test('keeps the last confirmed budget when later input is invalid', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final controller = container.read(mealBudgetProvider.notifier);

      final accepted = controller.confirmInput('150');
      final rejected = controller.confirmInput('150.5');

      expect(accepted.isValid, isTrue);
      expect(rejected.error, BudgetInputError.invalidFormat);
      expect(container.read(mealBudgetProvider)?.amountBaht, 150);
    });

    test('clear removes only the in-memory confirmed budget', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final controller = container.read(mealBudgetProvider.notifier);

      controller.confirmInput('300');
      controller.clear();

      expect(container.read(mealBudgetProvider), isNull);
    });
  });
}
