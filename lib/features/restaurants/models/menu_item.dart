import '../../../core/firestore/firestore_serialization.dart';
import '../../profile/models/food_preferences.dart';
import 'menu_preview.dart';

class NutritionEstimate {
  NutritionEstimate({
    required this.calories,
    required this.proteinGrams,
    required this.carbsGrams,
    required this.fatGrams,
  }) {
    if (calories < 0 ||
        calories > 10000 ||
        proteinGrams < 0 ||
        proteinGrams > 1000 ||
        carbsGrams < 0 ||
        carbsGrams > 1000 ||
        fatGrams < 0 ||
        fatGrams > 1000) {
      throw const FormatException('Nutrition values are outside the schema');
    }
  }

  final int calories;
  final double proteinGrams;
  final double carbsGrams;
  final double fatGrams;

  Map<String, Object> toFirestore() => {
    'calories': calories,
    'proteinGrams': proteinGrams,
    'carbsGrams': carbsGrams,
    'fatGrams': fatGrams,
  };

  factory NutritionEstimate.fromFirestore(Map<String, dynamic> data) =>
      NutritionEstimate(
        calories: readInt(data, 'calories'),
        proteinGrams: readDouble(data, 'proteinGrams'),
        carbsGrams: readDouble(data, 'carbsGrams'),
        fatGrams: readDouble(data, 'fatGrams'),
      );
}

class MenuItem {
  MenuItem({
    required this.id,
    required this.restaurantId,
    required this.name,
    required this.price,
    required this.nutrition,
    required this.tags,
    required this.ingredients,
    required this.allergens,
    required this.ingredientsKnown,
    required this.allergensKnown,
    required this.vegetarianConfirmed,
    required this.halalConfirmed,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.imageUrl,
  }) {
    final verifiedPriceHasProof =
        price.confidence != PriceConfidence.verified ||
        (price.source != null &&
            price.source!.trim().isNotEmpty &&
            price.verifiedAt != null &&
            !price.verifiedAt!.isAfter(updatedAt) &&
            updatedAt.difference(price.verifiedAt!) <=
                MenuPrice.verificationValidity);
    if (id.isEmpty ||
        restaurantId.isEmpty ||
        name.trim().isEmpty ||
        price.amount < 0 ||
        tags.any((tag) => tag.trim().isEmpty) ||
        (imageUrl != null && imageUrl!.trim().isEmpty) ||
        updatedAt.isBefore(createdAt) ||
        !verifiedPriceHasProof) {
      throw const FormatException('Invalid menu item document');
    }
  }

  static const schemaVersion = 1;

  final String id;
  final String restaurantId;
  final String name;
  final MenuPrice price;
  final NutritionEstimate nutrition;
  final List<String> tags;
  final Set<FoodIngredient> ingredients;
  final Set<FoodAllergen> allergens;
  final bool ingredientsKnown;
  final bool allergensKnown;
  final bool vegetarianConfirmed;
  final bool halalConfirmed;
  final bool isActive;
  final String? imageUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  Map<String, Object?> toFirestore() => {
    'schemaVersion': schemaVersion,
    'restaurantId': restaurantId,
    'name': name.trim(),
    'price': {
      'amount': price.amount,
      'confidence': price.confidence.name,
      if (price.source != null) 'source': price.source!.trim(),
      if (price.verifiedAt != null)
        'verifiedAt': firestoreTimestamp(price.verifiedAt!),
    },
    'nutrition': nutrition.toFirestore(),
    'tags': List<String>.unmodifiable(tags),
    'ingredients': [for (final value in ingredients) value.name],
    'allergens': [for (final value in allergens) value.name],
    'ingredientsKnown': ingredientsKnown,
    'allergensKnown': allergensKnown,
    'vegetarianConfirmed': vegetarianConfirmed,
    'halalConfirmed': halalConfirmed,
    'isActive': isActive,
    if (imageUrl != null) 'imageUrl': imageUrl!.trim(),
    'createdAt': firestoreTimestamp(createdAt),
    'updatedAt': firestoreTimestamp(updatedAt),
  };

  factory MenuItem.fromFirestore(String id, Map<String, dynamic> data) {
    requireSchemaVersion(data, schemaVersion);
    final priceData = readMap(data, 'price');
    final ingredients = readStringList(data, 'ingredients');
    final allergens = readStringList(data, 'allergens');
    return MenuItem(
      id: id,
      restaurantId: readRequiredString(data, 'restaurantId'),
      name: readRequiredString(data, 'name'),
      price: MenuPrice(
        amount: readInt(priceData, 'amount'),
        confidence: readEnum(priceData, 'confidence', PriceConfidence.values),
        source: readOptionalString(priceData, 'source'),
        verifiedAt: readOptionalTimestamp(priceData, 'verifiedAt'),
      ),
      nutrition: NutritionEstimate.fromFirestore(readMap(data, 'nutrition')),
      tags: readStringList(data, 'tags'),
      ingredients: _readEnumSet(
        ingredients,
        FoodIngredient.values,
        'ingredients',
      ),
      allergens: _readEnumSet(allergens, FoodAllergen.values, 'allergens'),
      ingredientsKnown: readBool(data, 'ingredientsKnown'),
      allergensKnown: readBool(data, 'allergensKnown'),
      vegetarianConfirmed: readBool(data, 'vegetarianConfirmed'),
      halalConfirmed: readBool(data, 'halalConfirmed'),
      isActive: readBool(data, 'isActive'),
      imageUrl: readOptionalString(data, 'imageUrl'),
      createdAt: readTimestamp(data, 'createdAt'),
      updatedAt: readTimestamp(data, 'updatedAt'),
    );
  }

  static Set<T> _readEnumSet<T extends Enum>(
    List<String> names,
    List<T> values,
    String field,
  ) {
    final byName = {for (final value in values) value.name: value};
    if (names.any((name) => !byName.containsKey(name))) {
      throw FormatException('Invalid Firestore field: $field');
    }
    return Set.unmodifiable(names.map((name) => byName[name]!));
  }
}
