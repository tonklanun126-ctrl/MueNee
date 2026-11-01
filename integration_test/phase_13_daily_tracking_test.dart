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
import 'package:muenee/features/tracking/presentation/daily_tracking_screen.dart';
import 'package:muenee/features/tracking/providers/daily_tracking_provider.dart';
import 'package:muenee/features/tracking/repositories/meal_log_repository.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('reads and summarizes owner meals on Android', (tester) async {
    final config = FirebaseConfig.fromEnvironment();
    if (config.mode != FirebaseMode.emulator ||
        config.projectId != FirebaseConfig.demoProjectId) {
      throw StateError('Phase 13 test requires the isolated demo emulator.');
    }

    final services = await FlutterFirebaseInitializer(config).initialize();
    final auth = FirebaseAuth.instanceFor(app: services.app);
    await auth.useAuthEmulator(config.emulatorHost, 9099);
    await auth.signOut();
    final credential = await auth.createUserWithEmailAndPassword(
      email: 'phase13-${DateTime.now().microsecondsSinceEpoch}@example.test',
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

    await repository.createRecommendationMeal(
      userId: uid,
      menu: _menu('phase13-rice', 'ข้าวไก่ Phase 13', 520, 28, 62, 16),
    );
    await repository.createRecommendationMeal(
      userId: uid,
      menu: _menu('phase13-soup', 'ต้มจืด Phase 13', 310, 15, 44, 8),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          accountProvider.overrideWith(
            (ref) =>
                Stream.value(Account(credential.user!.email!, false, uid: uid)),
          ),
          dailyMealLogRepositoryProvider.overrideWithValue(repository),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const DailyTrackingScreen(),
        ),
      ),
    );

    for (var attempt = 0; attempt < 100; attempt++) {
      await tester.pump(const Duration(milliseconds: 100));
      if (find.text('ประมาณ 830 kcal').evaluate().isNotEmpty) break;
    }
    expect(find.text('ประมาณ 830 kcal'), findsOneWidget);
    expect(find.text('มื้อที่บันทึก (2)'), findsOneWidget);
    expect(find.text('ข้าวไก่ Phase 13'), findsOneWidget);
    expect(find.text('ต้มจืด Phase 13'), findsOneWidget);
    expect(find.textContaining('คำแนะนำทางการแพทย์'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await binding.convertFlutterSurfaceToImage();
    await tester.pumpAndSettle();
    await binding.takeScreenshot('daily-tracking');
  });
}

MenuItem _menu(
  String id,
  String name,
  int calories,
  double protein,
  double carbs,
  double fat,
) {
  final now = DateTime.now().toUtc();
  return MenuItem(
    id: id,
    restaurantId: 'phase13-restaurant',
    name: name,
    price: MenuPrice(amount: 65, confidence: PriceConfidence.estimated),
    nutrition: NutritionEstimate(
      calories: calories,
      proteinGrams: protein,
      carbsGrams: carbs,
      fatGrams: fat,
    ),
    tags: const ['phase13'],
    ingredients: const {FoodIngredient.chicken},
    allergens: const {},
    ingredientsKnown: false,
    allergensKnown: false,
    vegetarianConfirmed: false,
    halalConfirmed: false,
    isActive: true,
    createdAt: now,
    updatedAt: now,
  );
}
