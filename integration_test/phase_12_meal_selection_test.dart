import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:muenee/app/theme/app_theme.dart';
import 'package:muenee/core/firebase/firebase_config.dart';
import 'package:muenee/core/firebase/firebase_initializer.dart';
import 'package:muenee/features/auth/auth_repository.dart';
import 'package:muenee/features/profile/models/food_preferences.dart';
import 'package:muenee/features/restaurants/models/menu_item.dart';
import 'package:muenee/features/restaurants/models/menu_preview.dart';
import 'package:muenee/features/restaurants/models/restaurant.dart';
import 'package:muenee/features/restaurants/models/restaurant_detail_arguments.dart';
import 'package:muenee/features/restaurants/presentation/screens/restaurant_detail_screen.dart';
import 'package:muenee/features/tracking/providers/meal_selection_provider.dart';
import 'package:muenee/features/tracking/repositories/meal_log_repository.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'selects one recommendation meal through Auth and Firestore emulators',
    (tester) async {
      final config = FirebaseConfig.fromEnvironment();
      if (config.mode != FirebaseMode.emulator ||
          config.projectId != FirebaseConfig.demoProjectId) {
        throw StateError('Phase 12 test requires the isolated demo emulator.');
      }

      final services = await FlutterFirebaseInitializer(config).initialize();
      final auth = FirebaseAuth.instanceFor(app: services.app);
      await auth.useAuthEmulator(config.emulatorHost, 9099);
      await auth.signOut();
      final credential = await auth.createUserWithEmailAndPassword(
        email: 'phase12-${DateTime.now().microsecondsSinceEpoch}@example.test',
        password: 'Emulator-only-123!',
      );
      final uid = credential.user!.uid;
      final repository = FirestoreMealLogRepository(services.firestore);

      addTearDown(() async {
        if (auth.currentUser?.uid != uid) return;
        final meals = await services.firestore
            .collection('meal_logs')
            .where('userId', isEqualTo: uid)
            .get();
        for (final meal in meals.docs) {
          await meal.reference.delete();
        }
        await auth.currentUser!.delete();
      });

      final details = _details();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            accountProvider.overrideWith(
              (ref) => Stream.value(
                Account(credential.user!.email!, false, uid: uid),
              ),
            ),
            mealLogRepositoryProvider.overrideWithValue(repository),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            home: RestaurantDetailScreen(details: details),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('select-meal')));
      await tester.pumpAndSettle();
      expect(find.textContaining('ไม่ได้สั่งหรือชำระ'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('confirm-meal-selection')));

      for (var attempt = 0; attempt < 100; attempt++) {
        await tester.pump(const Duration(milliseconds: 100));
        if (find.text('บันทึกมื้อนี้แล้ว').evaluate().isNotEmpty) break;
      }
      expect(find.text('บันทึกมื้อนี้แล้ว'), findsOneWidget);

      final meals = await services.firestore
          .collection('meal_logs')
          .where('userId', isEqualTo: uid)
          .get(const GetOptions(source: Source.server));
      expect(meals.docs, hasLength(1));
      final data = meals.docs.single.data();
      expect(data['schemaVersion'], 1);
      expect(data['source'], 'recommendation');
      expect(data['menuId'], details.menu.id);
      expect(data['restaurantId'], details.restaurant.id);
      expect(data['foodName'], details.menu.name);
      expect(data['nutrition'], details.menu.nutrition.toFirestore());
      expect(data['createdAt'], isA<Timestamp>());
      expect(tester.takeException(), isNull);
    },
  );
}

RestaurantDetailArguments _details() {
  final now = DateTime.utc(2026, 9, 10);
  final restaurant = Restaurant(
    id: 'phase12-restaurant',
    name: 'ร้านทดสอบ Phase 12',
    googlePlaceId: 'phase12-place',
    location: const GeoPoint(13.82, 100.0443),
    address: 'นครปฐม',
    verificationStatus: RestaurantVerificationStatus.verified,
    isActive: true,
    createdAt: now,
    updatedAt: now,
  );
  return RestaurantDetailArguments(
    restaurant: restaurant,
    menu: MenuItem(
      id: 'phase12-menu',
      restaurantId: restaurant.id,
      name: 'ข้าวไก่ทดสอบ Phase 12',
      price: MenuPrice(amount: 65, confidence: PriceConfidence.estimated),
      nutrition: NutritionEstimate(
        calories: 510,
        proteinGrams: 26,
        carbsGrams: 61,
        fatGrams: 15,
      ),
      tags: const ['rice'],
      ingredients: const {FoodIngredient.chicken},
      allergens: const {FoodAllergen.soy},
      ingredientsKnown: false,
      allergensKnown: false,
      vegetarianConfirmed: false,
      halalConfirmed: false,
      isActive: true,
      createdAt: now,
      updatedAt: now,
    ),
    distanceMeters: 250,
    rank: 1,
  );
}
