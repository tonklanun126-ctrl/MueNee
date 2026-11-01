import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_profile.dart';
import '../repositories/user_profile_repository.dart';

final userProfileRepositoryProvider = Provider<UserProfileRepository>(
  (ref) => LocalUserProfileRepository(SharedPreferencesAsync()),
);

final userProfileProvider =
    AsyncNotifierProvider<UserProfileController, UserProfile>(
      UserProfileController.new,
    );

class UserProfileController extends AsyncNotifier<UserProfile> {
  @override
  Future<UserProfile> build() =>
      ref.watch(userProfileRepositoryProvider).load();

  Future<void> save(UserProfile profile) async {
    await ref.read(userProfileRepositoryProvider).save(profile);
    if (ref.mounted) state = AsyncData(profile);
  }
}
