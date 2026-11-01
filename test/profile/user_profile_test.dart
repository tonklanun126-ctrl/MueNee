import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:muenee/features/profile/models/user_profile.dart';
import 'package:muenee/features/profile/providers/user_profile_provider.dart';
import 'package:muenee/features/profile/repositories/user_profile_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  test('profile round-trips through versioned JSON', () {
    final profile = UserProfile(
      age: 21,
      heightCm: 172.5,
      weightKg: 68,
      activityLevel: ActivityLevel.moderatelyActive,
    );

    expect(UserProfile.fromJson(profile.toJson()).toJson(), profile.toJson());
    expect(profile.isComplete, isTrue);
  });

  test('empty profile is allowed before setup is completed', () {
    final profile = UserProfile();

    expect(profile.isComplete, isFalse);
    expect(UserProfile.fromJson(profile.toJson()).toJson(), profile.toJson());
  });

  test('malformed or out-of-range profile is not silently reset', () {
    final storage = SharedPreferencesAsync();
    final repo = LocalUserProfileRepository(storage);
    final malformed = [
      'broken JSON',
      '[]',
      jsonEncode({...UserProfile().toJson(), 'activityLevel': 'unknown'}),
      jsonEncode({...UserProfile().toJson(), 'age': 0}),
      jsonEncode({...UserProfile().toJson(), 'version': 2}),
    ];

    return () async {
      for (final raw in malformed) {
        await storage.setString(LocalUserProfileRepository.storageKey, raw);
        await expectLater(repo.load(), throwsFormatException);
        expect(
          await storage.getString(LocalUserProfileRepository.storageKey),
          raw,
        );
      }
    }();
  });

  test('failed save preserves the last confirmed provider state', () async {
    final container = ProviderContainer(
      overrides: [
        userProfileRepositoryProvider.overrideWithValue(_FailingRepository()),
      ],
    );
    addTearDown(container.dispose);
    final initial = await container.read(userProfileProvider.future);
    await expectLater(
      container
          .read(userProfileProvider.notifier)
          .save(
            UserProfile(
              age: 21,
              heightCm: 170,
              weightKg: 65,
              activityLevel: ActivityLevel.lightlyActive,
            ),
          ),
      throwsStateError,
    );
    expect(container.read(userProfileProvider).requireValue, same(initial));
  });
}

class _FailingRepository implements UserProfileRepository {
  @override
  Future<UserProfile> load() async => UserProfile();

  @override
  Future<void> save(UserProfile profile) async =>
      throw StateError('disk failure');
}
