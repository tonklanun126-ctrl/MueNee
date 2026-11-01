import 'package:image_picker/image_picker.dart';

import '../models/food_scan_result.dart';

enum FoodImageSource { camera, gallery }

abstract interface class FoodImagePicker {
  Future<FoodScanImage?> pick(FoodImageSource source);

  Future<FoodScanImage?> recoverLostImage();
}

class DeviceFoodImagePicker implements FoodImagePicker {
  DeviceFoodImagePicker([ImagePicker? picker])
    : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  @override
  Future<FoodScanImage?> pick(FoodImageSource source) async {
    final file = await _picker.pickImage(
      source: source == FoodImageSource.camera
          ? ImageSource.camera
          : ImageSource.gallery,
      maxWidth: 1600,
      maxHeight: 1600,
      imageQuality: 85,
      requestFullMetadata: false,
    );
    return file == null ? null : _read(file);
  }

  @override
  Future<FoodScanImage?> recoverLostImage() async {
    final response = await _picker.retrieveLostData();
    if (response.isEmpty || response.files == null || response.files!.isEmpty) {
      return null;
    }
    return _read(response.files!.first);
  }

  Future<FoodScanImage> _read(XFile file) async {
    final bytes = await file.readAsBytes();
    final mimeType = _supportedMimeType(file.mimeType, file.name);
    return FoodScanImage(
      bytes: bytes,
      mimeType: mimeType,
      displayName: file.name,
    );
  }

  static String _supportedMimeType(String? supplied, String name) {
    final normalized = supplied?.toLowerCase().trim();
    if (normalized != null &&
        FoodScanImage.supportedMimeTypes.contains(normalized)) {
      return normalized;
    }
    final lowerName = name.toLowerCase();
    if (lowerName.endsWith('.png')) return 'image/png';
    if (lowerName.endsWith('.webp')) return 'image/webp';
    if (lowerName.endsWith('.jpg') || lowerName.endsWith('.jpeg')) {
      return 'image/jpeg';
    }
    throw const FormatException('Food scan image type is unsupported');
  }
}
