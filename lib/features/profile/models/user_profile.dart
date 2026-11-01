enum ActivityLevel {
  sedentary('นั่งเป็นส่วนใหญ่', 'ทำงานนั่งโต๊ะ และไม่ค่อยได้ออกกำลังกาย'),
  lightlyActive('เคลื่อนไหวเล็กน้อย', 'ออกกำลังกายเบา ๆ หรือเดินเป็นบางวัน'),
  moderatelyActive(
    'เคลื่อนไหวปานกลาง',
    'ออกกำลังกายระดับปานกลางหลายวันต่อสัปดาห์',
  ),
  veryActive(
    'เคลื่อนไหวมาก',
    'ออกกำลังกายหนักหรือทำงานที่ต้องเคลื่อนไหวเกือบทุกวัน',
  ),
  extraActive('กิจกรรมหนักมาก', 'ฝึกซ้อมกีฬา หรือทำงานที่ใช้แรงมากเป็นประจำ');

  const ActivityLevel(this.label, this.description);

  final String label;
  final String description;
}

/// The local profile inputs needed to personalize future recommendations.
///
/// The values are intentionally optional so a newly installed app can open
/// without forcing the user through profile setup. Saving from the settings
/// screen requires a complete profile.
class UserProfile {
  UserProfile({this.age, this.heightCm, this.weightKg, this.activityLevel}) {
    _validateValueRanges();
  }

  static const minAge = 1;
  static const maxAge = 120;
  static const minHeightCm = 50.0;
  static const maxHeightCm = 250.0;
  static const minWeightKg = 10.0;
  static const maxWeightKg = 500.0;

  final int? age;
  final double? heightCm;
  final double? weightKg;
  final ActivityLevel? activityLevel;

  bool get isComplete =>
      age != null &&
      heightCm != null &&
      weightKg != null &&
      activityLevel != null;

  UserProfile copyWith({
    int? age,
    double? heightCm,
    double? weightKg,
    ActivityLevel? activityLevel,
  }) => UserProfile(
    age: age ?? this.age,
    heightCm: heightCm ?? this.heightCm,
    weightKg: weightKg ?? this.weightKg,
    activityLevel: activityLevel ?? this.activityLevel,
  );

  Map<String, Object?> toJson() => {
    'version': 1,
    'age': age,
    'heightCm': heightCm,
    'weightKg': weightKg,
    'activityLevel': activityLevel?.name,
  };

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    if (json['version'] != 1) {
      throw const FormatException('Unsupported user profile format');
    }

    final activityValue = json['activityLevel'];
    if (activityValue != null && activityValue is! String) {
      throw const FormatException('Invalid activity level');
    }

    ActivityLevel? activity;
    if (activityValue != null) {
      activity = ActivityLevel.values.cast<ActivityLevel?>().firstWhere(
        (option) => option!.name == activityValue,
        orElse: () => null,
      );
      if (activity == null) {
        throw const FormatException('Invalid activity level');
      }
    }

    return UserProfile(
      age: _readInt(json['age'], 'age'),
      heightCm: _readDouble(json['heightCm'], 'heightCm'),
      weightKg: _readDouble(json['weightKg'], 'weightKg'),
      activityLevel: activity,
    );
  }

  static int? _readInt(Object? value, String field) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num && value.isFinite && value % 1 == 0) {
      return value.toInt();
    }
    throw FormatException('Invalid $field');
  }

  static double? _readDouble(Object? value, String field) {
    if (value == null) return null;
    if (value is num && value.isFinite) return value.toDouble();
    throw FormatException('Invalid $field');
  }

  void _validateValueRanges() {
    if (age != null && (age! < minAge || age! > maxAge)) {
      throw const FormatException('Age is outside the supported range');
    }
    if (heightCm != null &&
        (heightCm! < minHeightCm || heightCm! > maxHeightCm)) {
      throw const FormatException('Height is outside the supported range');
    }
    if (weightKg != null &&
        (weightKg! < minWeightKg || weightKg! > maxWeightKg)) {
      throw const FormatException('Weight is outside the supported range');
    }
  }
}
