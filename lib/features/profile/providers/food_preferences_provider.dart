import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/food_preferences.dart';
import '../repositories/food_preferences_repository.dart';

final foodPreferencesRepositoryProvider = Provider<FoodPreferencesRepository>(
  (ref) => LocalFoodPreferencesRepository(SharedPreferencesAsync()),
);

final foodPreferencesProvider =
    AsyncNotifierProvider<FoodPreferencesController, FoodPreferences>(
      FoodPreferencesController.new,
    );

class FoodPreferencesController extends AsyncNotifier<FoodPreferences> {
  @override
  Future<FoodPreferences> build() =>
      ref.watch(foodPreferencesRepositoryProvider).load();

  Future<void> save(FoodPreferences preferences) async {
    await ref.read(foodPreferencesRepositoryProvider).save(preferences);
    if (ref.mounted) state = AsyncData(preferences);
  }
}
