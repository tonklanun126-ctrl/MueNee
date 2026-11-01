import '../../../core/firestore/firestore_serialization.dart';
import 'food_preferences.dart';
import 'user_profile.dart';

class UserDocument {
  UserDocument({
    required this.id,
    required this.profile,
    required this.preferences,
    required this.createdAt,
    required this.updatedAt,
    this.displayName,
    this.targetCalories,
  }) {
    if (id.isEmpty ||
        (displayName != null && displayName!.trim().isEmpty) ||
        (targetCalories != null &&
            (targetCalories! < 500 || targetCalories! > 10000)) ||
        updatedAt.isBefore(createdAt)) {
      throw const FormatException('Invalid user document');
    }
  }

  static const schemaVersion = 1;

  final String id;
  final String? displayName;
  final UserProfile profile;
  final FoodPreferences preferences;
  final int? targetCalories;
  final DateTime createdAt;
  final DateTime updatedAt;

  Map<String, Object?> toFirestore() => {
    'schemaVersion': schemaVersion,
    if (displayName != null) 'displayName': displayName!.trim(),
    'profile': profile.toJson(),
    'preferences': preferences.toJson(),
    if (targetCalories != null) 'targetCalories': targetCalories,
    'createdAt': firestoreTimestamp(createdAt),
    'updatedAt': firestoreTimestamp(updatedAt),
  };

  factory UserDocument.fromFirestore(String id, Map<String, dynamic> data) {
    requireSchemaVersion(data, schemaVersion);
    return UserDocument(
      id: id,
      displayName: readOptionalString(data, 'displayName'),
      profile: UserProfile.fromJson(readMap(data, 'profile')),
      preferences: FoodPreferences.fromJson(readMap(data, 'preferences')),
      targetCalories: readOptionalInt(data, 'targetCalories'),
      createdAt: readTimestamp(data, 'createdAt'),
      updatedAt: readTimestamp(data, 'updatedAt'),
    );
  }
}
