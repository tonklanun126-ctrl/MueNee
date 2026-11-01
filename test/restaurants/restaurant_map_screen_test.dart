import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:muenee/app/theme/app_theme.dart';
import 'package:muenee/features/map/presentation/restaurant_map_screen.dart';
import 'package:muenee/features/restaurants/models/restaurant.dart';

void main() {
  testWidgets(
    'missing configuration keeps address accessible without native map or permission',
    (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final now = DateTime.utc(2026, 9, 9);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [mapsConfiguredProvider.overrideWithValue(false)],
          child: MaterialApp(
            theme: AppTheme.light,
            home: RestaurantMapScreen(
              restaurant: Restaurant(
                id: 'shop',
                name: 'ร้านสำหรับทดสอบแผนที่',
                googlePlaceId: 'place',
                address: 'ถนนสนามจันทร์ นครปฐม',
                location: const GeoPoint(13.82, 100.04),
                verificationStatus: RestaurantVerificationStatus.unverified,
                isActive: true,
                createdAt: now,
                updatedAt: now,
              ),
            ),
          ),
        ),
      );
      expect(find.text('ถนนสนามจันทร์ นครปฐม'), findsOneWidget);
      expect(find.byType(GoogleMap), findsNothing);
      await tester.scrollUntilVisible(
        find.textContaining('ยังไม่มีตำแหน่งของคุณ'),
        200,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
}
