import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:muenee/features/profile/models/food_preferences.dart';
import 'package:muenee/features/profile/providers/food_preferences_provider.dart';
import 'package:muenee/features/profile/repositories/food_preferences_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  test(
    'saved preferences survive repository and provider recreation',
    () async {
      final original = FoodPreferences(
        restrictions: {DietaryRestriction.noPork, DietaryRestriction.halalOnly},
        dislikes: {FoodIngredient.coriander},
        allergies: {FoodAllergen.peanut, FoodAllergen.shellfish},
        hideDisliked: true,
      );
      final first = ProviderContainer();
      await first.read(foodPreferencesProvider.future);
      await first.read(foodPreferencesProvider.notifier).save(original);
      first.dispose();
      final reopened = ProviderContainer();
      addTearDown(reopened.dispose);
      expect(
        (await reopened.read(foodPreferencesProvider.future)).toJson(),
        original.toJson(),
      );
    },
  );

  test('malformed or unsupported preferences are not silently reset', () async {
    final storage = SharedPreferencesAsync();
    final repo = LocalFoodPreferencesRepository(storage);
    for (final raw in [
      'broken JSON',
      '[]',
      jsonEncode({
        ...FoodPreferences().toJson(),
        'allergies': ['unsupported'],
      }),
      jsonEncode({...FoodPreferences().toJson(), 'version': 2}),
    ]) {
      await storage.setString(LocalFoodPreferencesRepository.storageKey, raw);
      await expectLater(repo.load(), throwsFormatException);
      expect(
        await storage.getString(LocalFoodPreferencesRepository.storageKey),
        raw,
      );
    }
  });

  test('failed save preserves the last confirmed provider state', () async {
    final container = ProviderContainer(
      overrides: [
        foodPreferencesRepositoryProvider.overrideWithValue(
          _FailingRepository(),
        ),
      ],
    );
    addTearDown(container.dispose);
    final initial = await container.read(foodPreferencesProvider.future);
    await expectLater(
      container
          .read(foodPreferencesProvider.notifier)
          .save(FoodPreferences(allergies: {FoodAllergen.egg})),
      throwsStateError,
    );
    expect(container.read(foodPreferencesProvider).requireValue, same(initial));
  });
}

class _FailingRepository implements FoodPreferencesRepository {
  @override
  Future<FoodPreferences> load() async => FoodPreferences();
  @override
  Future<void> save(FoodPreferences preferences) async =>
      throw StateError('disk failure');
}
