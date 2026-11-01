import '../../profile/models/food_preferences.dart';

enum PriceConfidence { verified, estimated, unverified }

class MenuPrice {
  const MenuPrice({
    required this.amount,
    required this.confidence,
    this.verifiedAt,
    this.source,
  }) : assert(amount >= 0);

  final int amount;
  final PriceConfidence confidence;
  final DateTime? verifiedAt;
  final String? source;

  // Local MVP policy, not a claim about how often real restaurants change price.
  static const verificationValidity = Duration(days: 30);

  PriceConfidence effectiveConfidence(DateTime now) {
    if (confidence != PriceConfidence.verified) return confidence;
    final checked = verifiedAt;
    if (checked == null ||
        checked.isAfter(now) ||
        now.difference(checked) > verificationValidity ||
        source == null ||
        source!.trim().isEmpty) {
      return PriceConfidence.unverified;
    }
    return PriceConfidence.verified;
  }
}

class MenuPreview {
  const MenuPreview({
    required this.id,
    required this.name,
    required this.price,
    this.ingredients = const {},
    this.allergens = const {},
    this.ingredientsKnown = false,
    this.allergensKnown = false,
    this.vegetarianConfirmed = false,
    this.halalConfirmed = false,
  });

  final String id;
  final String name;
  final MenuPrice price;
  final Set<FoodIngredient> ingredients;
  // Includes declared ingredients and declared possible cross-contact.
  final Set<FoodAllergen> allergens;
  final bool ingredientsKnown;
  final bool allergensKnown;
  final bool vegetarianConfirmed;
  final bool halalConfirmed;
}
