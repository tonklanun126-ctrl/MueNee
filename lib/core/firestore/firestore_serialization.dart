import 'package:cloud_firestore/cloud_firestore.dart';

Never _invalid(String field) =>
    throw FormatException('Invalid Firestore field: $field');

String readRequiredString(Map<String, dynamic> data, String field) {
  final value = data[field];
  if (value is! String || value.trim().isEmpty) return _invalid(field);
  return value;
}

String? readOptionalString(Map<String, dynamic> data, String field) {
  final value = data[field];
  if (value == null) return null;
  if (value is! String || value.trim().isEmpty) return _invalid(field);
  return value;
}

bool readBool(Map<String, dynamic> data, String field) {
  final value = data[field];
  if (value is! bool) return _invalid(field);
  return value;
}

int readInt(Map<String, dynamic> data, String field) {
  final value = data[field];
  if (value is int) return value;
  if (value is num && value.isFinite && value % 1 == 0) {
    return value.toInt();
  }
  return _invalid(field);
}

int? readOptionalInt(Map<String, dynamic> data, String field) {
  if (data[field] == null) return null;
  return readInt(data, field);
}

double readDouble(Map<String, dynamic> data, String field) {
  final value = data[field];
  if (value is num && value.isFinite) return value.toDouble();
  return _invalid(field);
}

double? readOptionalDouble(Map<String, dynamic> data, String field) {
  if (data[field] == null) return null;
  return readDouble(data, field);
}

DateTime readTimestamp(Map<String, dynamic> data, String field) {
  final value = data[field];
  if (value is! Timestamp) return _invalid(field);
  return value.toDate().toUtc();
}

DateTime? readOptionalTimestamp(Map<String, dynamic> data, String field) {
  if (data[field] == null) return null;
  return readTimestamp(data, field);
}

List<String> readStringList(Map<String, dynamic> data, String field) {
  final value = data[field];
  if (value is! List || value.any((item) => item is! String)) {
    return _invalid(field);
  }
  return List.unmodifiable(value.cast<String>());
}

Map<String, dynamic> readMap(Map<String, dynamic> data, String field) {
  final value = data[field];
  if (value is! Map) return _invalid(field);
  return Map<String, dynamic>.from(value);
}

T readEnum<T extends Enum>(
  Map<String, dynamic> data,
  String field,
  List<T> values,
) {
  final value = data[field];
  if (value is! String) return _invalid(field);
  for (final option in values) {
    if (option.name == value) return option;
  }
  return _invalid(field);
}

void requireSchemaVersion(Map<String, dynamic> data, int supportedVersion) {
  if (data['schemaVersion'] != supportedVersion) {
    throw const FormatException('Unsupported Firestore schema version');
  }
}

Timestamp firestoreTimestamp(DateTime value) =>
    Timestamp.fromDate(value.toUtc());
