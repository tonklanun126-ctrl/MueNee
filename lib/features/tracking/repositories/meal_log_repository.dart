import 'package:cloud_firestore/cloud_firestore.dart';

import '../../restaurants/models/menu_item.dart';
import '../models/meal_log.dart';

abstract interface class MealLogRepository {
  Future<String> createRecommendationMeal({
    required String userId,
    required MenuItem menu,
    String? imageUrl,
  });
}

abstract interface class DailyMealLogRepository {
  Stream<List<MealLog>> watchMealsForDay({
    required String userId,
    required DateTime localDay,
    int limit = 50,
  });
}

abstract interface class FoodScanMealRepository {
  Future<String> createFoodScanMeal({
    required String userId,
    required String foodName,
    required NutritionEstimate nutrition,
  });
}

class FirestoreMealLogRepository
    implements
        MealLogRepository,
        DailyMealLogRepository,
        FoodScanMealRepository {
  const FirestoreMealLogRepository(this._firestore);

  final FirebaseFirestore _firestore;

  @override
  Future<String> createRecommendationMeal({
    required String userId,
    required MenuItem menu,
    String? imageUrl,
  }) async {
    if (userId.trim().isEmpty) {
      throw const FormatException('A signed-in user is required');
    }
    final reference = _firestore.collection('meal_logs').doc();
    final meal = MealLog(
      id: reference.id,
      userId: userId,
      source: MealSource.recommendation,
      foodName: menu.name,
      nutrition: menu.nutrition,
      menuId: menu.id,
      restaurantId: menu.restaurantId,
      imageUrl: imageUrl,
      createdAt: DateTime.now().toUtc(),
    );
    final data = meal.toFirestore();
    data['createdAt'] = FieldValue.serverTimestamp();
    await reference.set(data);
    return reference.id;
  }

  @override
  Future<String> createFoodScanMeal({
    required String userId,
    required String foodName,
    required NutritionEstimate nutrition,
  }) async {
    final normalizedUserId = userId.trim();
    final normalizedFoodName = foodName.trim();
    if (normalizedUserId.isEmpty ||
        normalizedFoodName.isEmpty ||
        normalizedFoodName.length > 160) {
      throw const FormatException('Invalid confirmed food scan meal');
    }
    final reference = _firestore.collection('meal_logs').doc();
    final meal = MealLog(
      id: reference.id,
      userId: normalizedUserId,
      source: MealSource.foodScan,
      foodName: normalizedFoodName,
      nutrition: nutrition,
      createdAt: DateTime.now().toUtc(),
    );
    final data = meal.toFirestore();
    data['createdAt'] = FieldValue.serverTimestamp();
    await reference.set(data);
    return reference.id;
  }

  @override
  Stream<List<MealLog>> watchMealsForDay({
    required String userId,
    required DateTime localDay,
    int limit = 50,
  }) {
    if (userId.trim().isEmpty || limit < 1 || limit > 50) {
      throw const FormatException('Invalid daily meal query');
    }
    final start = DateTime(localDay.year, localDay.month, localDay.day);
    final end = DateTime(localDay.year, localDay.month, localDay.day + 1);
    return _firestore
        .collection('meal_logs')
        .where('userId', isEqualTo: userId)
        .where(
          'createdAt',
          isGreaterThanOrEqualTo: Timestamp.fromDate(start.toUtc()),
        )
        .where('createdAt', isLessThan: Timestamp.fromDate(end.toUtc()))
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots(includeMetadataChanges: true)
        .where((snapshot) => !snapshot.metadata.isFromCache)
        .map(
          (snapshot) => List<MealLog>.unmodifiable(
            snapshot.docs.map(
              (document) => MealLog.fromFirestore(document.id, document.data()),
            ),
          ),
        )
        .timeout(const Duration(seconds: 20));
  }
}
