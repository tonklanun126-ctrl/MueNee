import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/firebase/firebase_providers.dart';
import '../../restaurants/models/restaurant_detail_arguments.dart';
import '../repositories/meal_log_repository.dart';
import '../../../core/monitoring/telemetry_providers.dart';
import '../../../core/monitoring/telemetry_service.dart';

enum MealSelectionStatus { idle, saving, saved, failure }

class MealSelectionState {
  const MealSelectionState(this.status, {this.menuId});

  const MealSelectionState.idle() : this(MealSelectionStatus.idle);

  final MealSelectionStatus status;
  final String? menuId;

  bool saved(String id) => status == MealSelectionStatus.saved && menuId == id;
}

final mealLogRepositoryProvider = Provider<MealLogRepository>(
  (ref) => FirestoreMealLogRepository(ref.watch(firestoreProvider)),
);

final mealSelectionProvider =
    NotifierProvider.autoDispose<MealSelectionController, MealSelectionState>(
      MealSelectionController.new,
    );

class MealSelectionController extends Notifier<MealSelectionState> {
  @override
  MealSelectionState build() => const MealSelectionState.idle();

  Future<bool> select({
    required String userId,
    required RestaurantDetailArguments details,
  }) async {
    if (state.status == MealSelectionStatus.saving ||
        state.saved(details.menu.id)) {
      return false;
    }
    state = MealSelectionState(
      MealSelectionStatus.saving,
      menuId: details.menu.id,
    );
    try {
      await ref
          .read(mealLogRepositoryProvider)
          .createRecommendationMeal(
            userId: userId,
            menu: details.menu,
            imageUrl: details.menu.imageUrl ?? details.restaurant.imageUrl,
          );
      state = MealSelectionState(
        MealSelectionStatus.saved,
        menuId: details.menu.id,
      );
      unawaited(
        ref
            .read(telemetryServiceProvider)
            .logEvent(MueNeeAnalyticsEvent.recommendationMealRecorded),
      );
      return true;
    } catch (error, stack) {
      if (kDebugMode) {
        debugPrint('Meal selection failed: ${error.runtimeType}');
        debugPrintStack(stackTrace: stack);
      }
      unawaited(
        ref
            .read(telemetryServiceProvider)
            .recordNonFatal('recommendation_meal_save_failed', stack),
      );
      state = MealSelectionState(
        MealSelectionStatus.failure,
        menuId: details.menu.id,
      );
      return false;
    }
  }
}
