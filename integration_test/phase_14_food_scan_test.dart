import 'dart:convert';
import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:muenee/app/theme/app_theme.dart';
import 'package:muenee/core/firebase/firebase_config.dart';
import 'package:muenee/core/firebase/firebase_initializer.dart';
import 'package:muenee/features/auth/auth_repository.dart';
import 'package:muenee/features/food_scan/models/food_scan_result.dart';
import 'package:muenee/features/food_scan/presentation/food_scan_screen.dart';
import 'package:muenee/features/food_scan/providers/food_scan_provider.dart';
import 'package:muenee/features/food_scan/services/food_analysis_service.dart';
import 'package:muenee/features/food_scan/services/food_image_picker.dart';
import 'package:muenee/features/restaurants/models/menu_item.dart';
import 'package:muenee/features/tracking/repositories/meal_log_repository.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('confirms an edited scan before the owner meal write', (
    tester,
  ) async {
    final config = FirebaseConfig.fromEnvironment();
    if (config.mode != FirebaseMode.emulator ||
        config.projectId != FirebaseConfig.demoProjectId) {
      throw StateError('Phase 14 test requires the isolated demo emulator.');
    }

    final services = await FlutterFirebaseInitializer(config).initialize();
    final auth = FirebaseAuth.instanceFor(app: services.app);
    await auth.useAuthEmulator(config.emulatorHost, 9099);
    await auth.signOut();
    final credential = await auth.createUserWithEmailAndPassword(
      email: 'phase14-${DateTime.now().microsecondsSinceEpoch}@example.test',
      password: 'Emulator-only-123!',
    );
    final uid = credential.user!.uid;
    final repository = FirestoreMealLogRepository(services.firestore);

    addTearDown(() async {
      final meals = await services.firestore
          .collection('meal_logs')
          .where('userId', isEqualTo: uid)
          .get();
      for (final meal in meals.docs) {
        await meal.reference.delete();
      }
      if (auth.currentUser?.uid == uid) await auth.currentUser!.delete();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          accountProvider.overrideWith(
            (ref) =>
                Stream.value(Account(credential.user!.email!, false, uid: uid)),
          ),
          foodImagePickerProvider.overrideWithValue(_IntegrationImagePicker()),
          foodAnalysisServiceProvider.overrideWithValue(
            _IntegrationAnalysisService(),
          ),
          foodScanMealRepositoryProvider.overrideWithValue(repository),
        ],
        child: MaterialApp(theme: AppTheme.light, home: const FoodScanScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('pick-food-gallery')));
    await tester.pumpAndSettle();
    expect(
      await services.firestore
          .collection('meal_logs')
          .where('userId', isEqualTo: uid)
          .get()
          .then((value) => value.docs),
      isEmpty,
    );

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('analyze-food-image')),
      240,
    );
    await tester.drag(find.byType(ListView).first, const Offset(0, -100));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('analyze-food-image')));
    await tester.pumpAndSettle();
    expect(find.text('ตรวจและแก้ค่าประมาณ'), findsOneWidget);
    expect(
      await services.firestore
          .collection('meal_logs')
          .where('userId', isEqualTo: uid)
          .get()
          .then((value) => value.docs),
      isEmpty,
    );

    await tester.ensureVisible(find.byKey(const ValueKey('confirm-food-scan')));
    await tester.pumpAndSettle();
    await binding.convertFlutterSurfaceToImage();
    await tester.pumpAndSettle();
    await binding.takeScreenshot('food-scan-review');

    await tester.enterText(
      find.byKey(const ValueKey('food-name-field')),
      'ข้าวกะเพราไก่ ไข่ดาว',
    );
    await tester.enterText(find.byKey(const ValueKey('calories-field')), '620');
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const ValueKey('confirm-food-scan')));
    await tester.drag(find.byType(ListView).first, const Offset(0, -120));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('confirm-food-scan')));
    await tester.pumpAndSettle();

    expect(find.text('บันทึกมื้อนี้แล้ว'), findsOneWidget);
    final meals = await services.firestore
        .collection('meal_logs')
        .where('userId', isEqualTo: uid)
        .get();
    expect(meals.docs, hasLength(1));
    final data = meals.docs.single.data();
    expect(data['source'], 'food_scan');
    expect(data['foodName'], 'ข้าวกะเพราไก่ ไข่ดาว');
    expect((data['nutrition'] as Map<String, dynamic>)['calories'], 620);
    expect(data.containsKey('imageUrl'), isFalse);
    expect(tester.takeException(), isNull);

    await binding.takeScreenshot('food-scan-saved');
  });
}

class _IntegrationImagePicker implements FoodImagePicker {
  final image = FoodScanImage(
    bytes: Uint8List.fromList(
      base64Decode(
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',
      ),
    ),
    mimeType: 'image/png',
    displayName: 'phase14-meal.png',
  );

  @override
  Future<FoodScanImage?> pick(FoodImageSource source) async => image;

  @override
  Future<FoodScanImage?> recoverLostImage() async => null;
}

class _IntegrationAnalysisService implements FoodAnalysisService {
  @override
  Future<FoodScanResult> analyze(FoodScanImage image) async => FoodScanResult(
    foodName: 'ข้าวกะเพราไก่',
    nutrition: NutritionEstimate(
      calories: 540,
      proteinGrams: 28,
      carbsGrams: 65,
      fatGrams: 18,
    ),
    assumption: 'ค่าจำลองสำหรับทดสอบ ประเมินจากอาหารหนึ่งจาน',
  );
}
