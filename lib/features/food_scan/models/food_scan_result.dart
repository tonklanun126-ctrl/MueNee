import 'dart:typed_data';

import '../../restaurants/models/menu_item.dart';

class FoodScanImage {
  FoodScanImage({
    required this.bytes,
    required this.mimeType,
    required this.displayName,
  }) {
    if (bytes.isEmpty || bytes.lengthInBytes > maxBytes) {
      throw const FormatException('Food scan image size is invalid');
    }
    if (!supportedMimeTypes.contains(mimeType)) {
      throw const FormatException('Food scan image type is unsupported');
    }
  }

  static const maxBytes = 10 * 1024 * 1024;
  static const supportedMimeTypes = {'image/jpeg', 'image/png', 'image/webp'};

  final Uint8List bytes;
  final String mimeType;
  final String displayName;
}

class FoodScanResult {
  FoodScanResult({
    required this.foodName,
    required this.nutrition,
    required this.assumption,
  }) {
    if (foodName.trim().isEmpty ||
        foodName.trim().length > 160 ||
        assumption.trim().isEmpty ||
        assumption.trim().length > 240) {
      throw const FormatException('Food scan result is invalid');
    }
  }

  final String foodName;
  final NutritionEstimate nutrition;
  final String assumption;

  factory FoodScanResult.fromJson(Map<String, dynamic> data) {
    if (data['recognizedFood'] != true) {
      throw const FoodNotRecognizedException();
    }
    return FoodScanResult(
      foodName: _requiredString(data, 'foodName'),
      nutrition: NutritionEstimate(
        calories: _requiredInt(data, 'calories'),
        proteinGrams: _requiredDouble(data, 'proteinGrams'),
        carbsGrams: _requiredDouble(data, 'carbsGrams'),
        fatGrams: _requiredDouble(data, 'fatGrams'),
      ),
      assumption: _requiredString(data, 'assumption'),
    );
  }

  static String _requiredString(Map<String, dynamic> data, String key) {
    final value = data[key];
    if (value is! String || value.trim().isEmpty) {
      throw FormatException('Invalid AI response field: $key');
    }
    return value.trim();
  }

  static int _requiredInt(Map<String, dynamic> data, String key) {
    final value = data[key];
    if (value is! num || !value.isFinite || value != value.roundToDouble()) {
      throw FormatException('Invalid AI response field: $key');
    }
    return value.toInt();
  }

  static double _requiredDouble(Map<String, dynamic> data, String key) {
    final value = data[key];
    if (value is! num || !value.isFinite) {
      throw FormatException('Invalid AI response field: $key');
    }
    return value.toDouble();
  }
}

class FoodNotRecognizedException implements Exception {
  const FoodNotRecognizedException();
}
