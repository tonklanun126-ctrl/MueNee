import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_profile.dart';

abstract interface class UserProfileRepository {
  Future<UserProfile> load();
  Future<void> save(UserProfile profile);
}

class LocalUserProfileRepository implements UserProfileRepository {
  LocalUserProfileRepository(this._storage);

  final SharedPreferencesAsync _storage;
  static const storageKey = 'muenee.user_profile.v1';

  @override
  Future<UserProfile> load() async {
    final raw = await _storage.getString(storageKey);
    if (raw == null) return UserProfile();
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Invalid user profile document');
    }
    return UserProfile.fromJson(decoded);
  }

  @override
  Future<void> save(UserProfile profile) =>
      _storage.setString(storageKey, jsonEncode(profile.toJson()));
}
