enum DietaryRestriction {
  noPork('ไม่กินเนื้อหมู'),
  noBeef('ไม่กินเนื้อวัว'),
  vegetarian('มังสวิรัติ'),
  halalOnly('รับประทานเฉพาะอาหารฮาลาล');

  const DietaryRestriction(this.label);
  final String label;
}

enum FoodIngredient {
  pork('หมู'),
  beef('เนื้อวัว'),
  chicken('ไก่'),
  fish('ปลา'),
  shellfish('กุ้ง / ปู / หอย'),
  egg('ไข่'),
  milk('นม'),
  mushroom('เห็ด'),
  coriander('ผักชี'),
  offal('เครื่องใน');

  const FoodIngredient(this.label);
  final String label;
}

enum FoodAllergen {
  peanut('ถั่วลิสง'),
  treeNuts('ถั่วเปลือกแข็ง'),
  milk('นม'),
  egg('ไข่'),
  soy('ถั่วเหลือง'),
  wheat('ข้าวสาลี'),
  fish('ปลา'),
  shellfish('กุ้ง / ปู / หอย'),
  sesame('งา');

  const FoodAllergen(this.label);
  final String label;
}

class FoodPreferences {
  FoodPreferences({
    Set<DietaryRestriction> restrictions = const {},
    Set<FoodIngredient> dislikes = const {},
    Set<FoodAllergen> allergies = const {},
    this.hideDisliked = false,
  }) : restrictions = Set.unmodifiable(restrictions),
       dislikes = Set.unmodifiable(dislikes),
       allergies = Set.unmodifiable(allergies);

  final Set<DietaryRestriction> restrictions;
  final Set<FoodIngredient> dislikes;
  final Set<FoodAllergen> allergies;
  final bool hideDisliked;

  FoodPreferences copyWith({
    Set<DietaryRestriction>? restrictions,
    Set<FoodIngredient>? dislikes,
    Set<FoodAllergen>? allergies,
    bool? hideDisliked,
  }) => FoodPreferences(
    restrictions: restrictions ?? this.restrictions,
    dislikes: dislikes ?? this.dislikes,
    allergies: allergies ?? this.allergies,
    hideDisliked: hideDisliked ?? this.hideDisliked,
  );

  Map<String, Object> toJson() => {
    'version': 1,
    'restrictions': [
      for (final item in DietaryRestriction.values)
        if (restrictions.contains(item)) item.name,
    ],
    'dislikes': [
      for (final item in FoodIngredient.values)
        if (dislikes.contains(item)) item.name,
    ],
    'allergies': [
      for (final item in FoodAllergen.values)
        if (allergies.contains(item)) item.name,
    ],
    'hideDisliked': hideDisliked,
  };

  factory FoodPreferences.fromJson(Map<String, dynamic> json) {
    if (json['version'] != 1 || json['hideDisliked'] is! bool) {
      throw const FormatException('Unsupported food preferences format');
    }
    return FoodPreferences(
      restrictions: _readEnums(json['restrictions'], DietaryRestriction.values),
      dislikes: _readEnums(json['dislikes'], FoodIngredient.values),
      allergies: _readEnums(json['allergies'], FoodAllergen.values),
      hideDisliked: json['hideDisliked'] as bool,
    );
  }

  static Set<T> _readEnums<T extends Enum>(Object? value, List<T> values) {
    if (value is! List ||
        value.any((item) => !values.any((option) => option.name == item))) {
      throw const FormatException('Invalid food preference option');
    }
    return {
      for (final item in value)
        values.firstWhere((option) => option.name == item),
    };
  }
}
