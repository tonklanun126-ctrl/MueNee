import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/firebase/firebase_providers.dart';
import '../models/meal_log.dart';
import '../repositories/meal_log_repository.dart';

class DailyMealRequest {
  DailyMealRequest({required this.userId, required DateTime localDay})
    : localDay = DateTime(localDay.year, localDay.month, localDay.day);

  final String userId;
  final DateTime localDay;

  @override
  bool operator ==(Object other) =>
      other is DailyMealRequest &&
      other.userId == userId &&
      other.localDay == localDay;

  @override
  int get hashCode => Object.hash(userId, localDay);
}

final dailyMealLogRepositoryProvider = Provider<DailyMealLogRepository>(
  (ref) => FirestoreMealLogRepository(ref.watch(firestoreProvider)),
  dependencies: [firestoreProvider],
);

final dailyMealsProvider = StreamProvider.autoDispose
    .family<List<MealLog>, DailyMealRequest>(
      (ref, request) => ref
          .watch(dailyMealLogRepositoryProvider)
          .watchMealsForDay(userId: request.userId, localDay: request.localDay),
      dependencies: [dailyMealLogRepositoryProvider],
    );
