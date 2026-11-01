import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/food_preferences.dart';

abstract interface class FoodPreferencesRepository {
  Future<FoodPreferences> load();
  Future<void> save(FoodPreferences preferences);
}

class LocalFoodPreferencesRepository implements FoodPreferencesRepository {
  LocalFoodPreferencesRepository(this._storage);

  final SharedPreferencesAsync _storage;
  static const storageKey = 'muenee.food_preferences.v1';

  @override
  Future<FoodPreferences> load() async {
    final raw = await _storage.getString(storageKey);
    if (raw == null) return FoodPreferences();
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Invalid food preferences document');
    }
    return FoodPreferences.fromJson(decoded);
  }

  @override
  Future<void> save(FoodPreferences preferences) =>
      _storage.setString(storageKey, jsonEncode(preferences.toJson()));
}
