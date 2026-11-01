import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/firebase/firebase_providers.dart';
import '../../budget/providers/meal_budget_provider.dart';
import '../../location/providers/location_provider.dart';
import '../../profile/providers/food_preferences_provider.dart';
import '../models/ranked_menu_recommendation.dart';
import '../repositories/recommendation_catalog_repository.dart';
import '../services/recommendation_ranker.dart';

final recommendationCatalogRepositoryProvider =
    Provider<RecommendationCatalogRepository>(
      (ref) => FirestoreRecommendationCatalogRepository(
        ref.watch(firestoreProvider),
      ),
    );

final recommendationRankerProvider = Provider<RecommendationRanker>(
  (ref) => const RecommendationRanker(),
);

final recommendationProvider =
    FutureProvider.autoDispose<List<RankedMenuRecommendation>>((ref) async {
      final location = ref.watch(locationProvider).location;
      final budget = ref.watch(mealBudgetProvider);
      if (location == null || budget == null) {
        throw const RecommendationInputsMissing();
      }
      final preferences = await ref.watch(foodPreferencesProvider.future);
      if (!ref.mounted) return const [];
      final ranker = ref.watch(recommendationRankerProvider);
      try {
        final catalog = await ref
            .watch(recommendationCatalogRepositoryProvider)
            .loadActiveCatalog()
            .timeout(const Duration(seconds: 20));
        return ranker.rank(
          catalog: catalog,
          userLocation: location,
          budget: budget,
          preferences: preferences,
          now: DateTime.now().toUtc(),
        );
      } catch (error, stack) {
        if (kDebugMode) {
          debugPrint('Recommendation load failed: ${error.runtimeType}');
          debugPrintStack(stackTrace: stack);
        }
        rethrow;
      }
    }, retry: (retryCount, error) => null);

class RecommendationInputsMissing implements Exception {
  const RecommendationInputsMissing();
}
