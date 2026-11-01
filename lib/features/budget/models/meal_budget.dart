enum BudgetInputError { empty, invalidFormat, belowMinimum, aboveMaximum }

class BudgetParseResult {
  const BudgetParseResult.valid(this.budget) : error = null;
  const BudgetParseResult.invalid(this.error) : budget = null;

  final MealBudget? budget;
  final BudgetInputError? error;

  bool get isValid => budget != null;
}

class MealBudget {
  const MealBudget._(this.amountBaht);

  static const minBaht = 1;
  static const maxBaht = 10000;

  final int amountBaht;

  factory MealBudget(int amountBaht) {
    if (amountBaht < minBaht || amountBaht > maxBaht) {
      throw RangeError.range(amountBaht, minBaht, maxBaht, 'amountBaht');
    }
    return MealBudget._(amountBaht);
  }

  static BudgetParseResult parseUserInput(String input) {
    final normalized = _normalizeThaiDigits(input.trim());
    if (normalized.isEmpty) {
      return const BudgetParseResult.invalid(BudgetInputError.empty);
    }
    if (!RegExp(r'^(?:\d+|\d{1,3}(?:,\d{3})+)$').hasMatch(normalized)) {
      return const BudgetParseResult.invalid(BudgetInputError.invalidFormat);
    }

    final amount = int.tryParse(normalized.replaceAll(',', ''));
    if (amount == null) {
      return const BudgetParseResult.invalid(BudgetInputError.invalidFormat);
    }
    if (amount < minBaht) {
      return const BudgetParseResult.invalid(BudgetInputError.belowMinimum);
    }
    if (amount > maxBaht) {
      return const BudgetParseResult.invalid(BudgetInputError.aboveMaximum);
    }
    return BudgetParseResult.valid(MealBudget._(amount));
  }

  static String _normalizeThaiDigits(String value) {
    const thaiDigits = '๐๑๒๓๔๕๖๗๘๙';
    return value.split('').map((character) {
      final index = thaiDigits.indexOf(character);
      return index == -1 ? character : index.toString();
    }).join();
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MealBudget && other.amountBaht == amountBaht;

  @override
  int get hashCode => amountBaht.hashCode;
}
