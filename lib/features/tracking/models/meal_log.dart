import '../../../core/firestore/firestore_serialization.dart';
import '../../restaurants/models/menu_item.dart';

enum MealSource { recommendation, foodScan, manual }

extension MealSourceFirestoreValue on MealSource {
  String get firestoreValue => switch (this) {
    MealSource.recommendation => 'recommendation',
    MealSource.foodScan => 'food_scan',
    MealSource.manual => 'manual',
  };
}

class MealLog {
  MealLog({
    required this.id,
    required this.userId,
    required this.source,
    required this.foodName,
    required this.nutrition,
    required this.createdAt,
    this.menuId,
    this.restaurantId,
    this.imageUrl,
  }) {
    if (id.isEmpty ||
        userId.isEmpty ||
        foodName.trim().isEmpty ||
        (menuId != null && menuId!.trim().isEmpty) ||
        (restaurantId != null && restaurantId!.trim().isEmpty) ||
        (imageUrl != null && imageUrl!.trim().isEmpty)) {
      throw const FormatException('Invalid meal log document');
    }
  }

  static const schemaVersion = 1;

  final String id;
  final String userId;
  final MealSource source;
  final String foodName;
  final NutritionEstimate nutrition;
  final String? menuId;
  final String? restaurantId;
  final String? imageUrl;
  final DateTime createdAt;

  Map<String, Object?> toFirestore() => {
    'schemaVersion': schemaVersion,
    'userId': userId,
    'source': source.firestoreValue,
    'foodName': foodName.trim(),
    'nutrition': nutrition.toFirestore(),
    if (menuId != null) 'menuId': menuId,
    if (restaurantId != null) 'restaurantId': restaurantId,
    if (imageUrl != null) 'imageUrl': imageUrl,
    'createdAt': firestoreTimestamp(createdAt),
  };

  factory MealLog.fromFirestore(String id, Map<String, dynamic> data) {
    requireSchemaVersion(data, schemaVersion);
    final source = switch (readRequiredString(data, 'source')) {
      'recommendation' => MealSource.recommendation,
      'food_scan' => MealSource.foodScan,
      'manual' => MealSource.manual,
      _ => throw const FormatException('Invalid Firestore field: source'),
    };
    return MealLog(
      id: id,
      userId: readRequiredString(data, 'userId'),
      source: source,
      foodName: readRequiredString(data, 'foodName'),
      nutrition: NutritionEstimate.fromFirestore(readMap(data, 'nutrition')),
      menuId: readOptionalString(data, 'menuId'),
      restaurantId: readOptionalString(data, 'restaurantId'),
      imageUrl: readOptionalString(data, 'imageUrl'),
      createdAt: readTimestamp(data, 'createdAt'),
    );
  }
}
