class TelemetrySettings {
  const TelemetrySettings({
    this.analyticsEnabled = false,
    this.crashReportsEnabled = false,
  });

  static const schemaVersion = 1;

  final bool analyticsEnabled;
  final bool crashReportsEnabled;

  TelemetrySettings copyWith({
    bool? analyticsEnabled,
    bool? crashReportsEnabled,
  }) => TelemetrySettings(
    analyticsEnabled: analyticsEnabled ?? this.analyticsEnabled,
    crashReportsEnabled: crashReportsEnabled ?? this.crashReportsEnabled,
  );

  Map<String, Object> toJson() => {
    'version': schemaVersion,
    'analyticsEnabled': analyticsEnabled,
    'crashReportsEnabled': crashReportsEnabled,
  };

  factory TelemetrySettings.fromJson(Map<String, dynamic> json) {
    if (json['version'] != schemaVersion ||
        json['analyticsEnabled'] is! bool ||
        json['crashReportsEnabled'] is! bool) {
      throw const FormatException('Invalid telemetry settings document');
    }
    return TelemetrySettings(
      analyticsEnabled: json['analyticsEnabled'] as bool,
      crashReportsEnabled: json['crashReportsEnabled'] as bool,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is TelemetrySettings &&
      other.analyticsEnabled == analyticsEnabled &&
      other.crashReportsEnabled == crashReportsEnabled;

  @override
  int get hashCode => Object.hash(analyticsEnabled, crashReportsEnabled);
}
