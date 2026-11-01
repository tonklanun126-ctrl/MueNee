import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/firestore/firestore_serialization.dart';

enum RestaurantVerificationStatus { unverified, pending, verified }

class Restaurant {
  Restaurant({
    required this.id,
    required this.name,
    required this.googlePlaceId,
    required this.location,
    required this.address,
    required this.verificationStatus,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.rating,
    this.imageUrl,
  }) {
    if (id.isEmpty ||
        name.trim().isEmpty ||
        googlePlaceId.trim().isEmpty ||
        address.trim().isEmpty ||
        (rating != null && (rating! < 0 || rating! > 5)) ||
        (imageUrl != null && imageUrl!.trim().isEmpty) ||
        updatedAt.isBefore(createdAt)) {
      throw const FormatException('Invalid restaurant document');
    }
  }

  static const schemaVersion = 1;

  final String id;
  final String name;
  final String googlePlaceId;
  final GeoPoint location;
  final String address;
  final double? rating;
  final String? imageUrl;
  final RestaurantVerificationStatus verificationStatus;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  Map<String, Object?> toFirestore() => {
    'schemaVersion': schemaVersion,
    'name': name.trim(),
    'googlePlaceId': googlePlaceId.trim(),
    'location': location,
    'address': address.trim(),
    if (rating != null) 'rating': rating,
    if (imageUrl != null) 'imageUrl': imageUrl!.trim(),
    'verificationStatus': verificationStatus.name,
    'isActive': isActive,
    'createdAt': firestoreTimestamp(createdAt),
    'updatedAt': firestoreTimestamp(updatedAt),
  };

  factory Restaurant.fromFirestore(String id, Map<String, dynamic> data) {
    requireSchemaVersion(data, schemaVersion);
    final location = data['location'];
    if (location is! GeoPoint) {
      throw const FormatException('Invalid Firestore field: location');
    }
    return Restaurant(
      id: id,
      name: readRequiredString(data, 'name'),
      googlePlaceId: readRequiredString(data, 'googlePlaceId'),
      location: location,
      address: readRequiredString(data, 'address'),
      rating: readOptionalDouble(data, 'rating'),
      imageUrl: readOptionalString(data, 'imageUrl'),
      verificationStatus: readEnum(
        data,
        'verificationStatus',
        RestaurantVerificationStatus.values,
      ),
      isActive: readBool(data, 'isActive'),
      createdAt: readTimestamp(data, 'createdAt'),
      updatedAt: readTimestamp(data, 'updatedAt'),
    );
  }
}
