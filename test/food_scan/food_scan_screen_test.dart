import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:muenee/app/theme/app_theme.dart';
import 'package:muenee/features/auth/auth_repository.dart';
import 'package:muenee/features/food_scan/models/food_scan_result.dart';
import 'package:muenee/features/food_scan/presentation/food_scan_screen.dart';
import 'package:muenee/features/food_scan/providers/food_scan_provider.dart';
import 'package:muenee/features/food_scan/services/food_analysis_service.dart';
import 'package:muenee/features/food_scan/services/food_image_picker.dart';
import 'package:muenee/features/restaurants/models/menu_item.dart';
import 'package:muenee/features/tracking/repositories/meal_log_repository.dart';

void main() {
  Widget app({
    Account? account = const Account('student@example.com', true, uid: 'owner'),
    required _FakeImagePicker picker,
    required _FakeAnalysisService analysis,
    required _FakeFoodScanMealRepository repository,
  }) => ProviderScope(
    overrides: [
      accountProvider.overrideWith((ref) => Stream.value(account)),
      foodImagePickerProvider.overrideWithValue(picker),
      foodAnalysisServiceProvider.overrideWithValue(analysis),
      foodScanMealRepositoryProvider.overrideWithValue(repository),
    ],
    child: MaterialApp(theme: AppTheme.light, home: const FoodScanScreen()),
  );

  testWidgets('requires an account before image analysis', (tester) async {
    final picker = _FakeImagePicker();
    final analysis = _FakeAnalysisService();
    final repository = _FakeFoodScanMealRepository();
    await tester.pumpWidget(
      app(
        account: null,
        picker: picker,
        analysis: analysis,
        repository: repository,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('เข้าสู่ระบบก่อนสแกนอาหาร'), findsOneWidget);
    expect(find.byKey(const ValueKey('pick-food-camera')), findsNothing);
    expect(analysis.calls, 0);
    expect(repository.calls, 0);
  });

  testWidgets('does not save AI output until edited result is confirmed', (
    tester,
  ) async {
    final picker = _FakeImagePicker();
    final analysis = _FakeAnalysisService();
    final repository = _FakeFoodScanMealRepository();
    await tester.pumpWidget(
      app(picker: picker, analysis: analysis, repository: repository),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('AI ให้ค่าประมาณ'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('pick-food-gallery')));
    await tester.pumpAndSettle();
    expect(repository.calls, 0);

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('analyze-food-image')),
      240,
    );
    await tester.drag(find.byType(ListView), const Offset(0, -100));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('analyze-food-image')));
    await tester.pumpAndSettle();
    expect(analysis.calls, 1);
    expect(find.text('ตรวจและแก้ค่าประมาณ'), findsOneWidget);
    expect(repository.calls, 0);

    await tester.enterText(
      find.byKey(const ValueKey('food-name-field')),
      'ข้าวกะเพราไก่ ไข่ดาว',
    );
    await tester.enterText(find.byKey(const ValueKey('calories-field')), '620');
    tester.testTextInput.hide();
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const ValueKey('confirm-food-scan')));
    await tester.drag(find.byType(ListView).first, const Offset(0, -120));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('confirm-food-scan')));
    await tester.pumpAndSettle();

    expect(repository.calls, 1);
    expect(repository.userId, 'owner');
    expect(repository.foodName, 'ข้าวกะเพราไก่ ไข่ดาว');
    expect(repository.nutrition?.calories, 620);
    expect(find.text('บันทึกมื้อนี้แล้ว'), findsOneWidget);
  });

  testWidgets('analysis failure keeps image and allows retry', (tester) async {
    final picker = _FakeImagePicker();
    final analysis = _FakeAnalysisService(failuresRemaining: 1);
    final repository = _FakeFoodScanMealRepository();
    await tester.pumpWidget(
      app(picker: picker, analysis: analysis, repository: repository),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('pick-food-camera')));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('analyze-food-image')),
      240,
    );
    await tester.drag(find.byType(ListView), const Offset(0, -100));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('analyze-food-image')));
    await tester.pumpAndSettle();

    expect(find.textContaining('วิเคราะห์ภาพไม่สำเร็จ'), findsOneWidget);
    expect(find.bySemanticsLabel('ภาพอาหารที่เลือก'), findsOneWidget);
    expect(repository.calls, 0);

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('analyze-food-image')),
      160,
    );
    await tester.drag(find.byType(ListView), const Offset(0, -100));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('analyze-food-image')));
    await tester.pumpAndSettle();
    expect(find.text('ตรวจและแก้ค่าประมาณ'), findsOneWidget);
    expect(analysis.calls, 2);
  });

  testWidgets('save failure keeps reviewed values and can retry', (
    tester,
  ) async {
    final picker = _FakeImagePicker();
    final analysis = _FakeAnalysisService();
    final repository = _FakeFoodScanMealRepository(fail: true);
    await tester.pumpWidget(
      app(picker: picker, analysis: analysis, repository: repository),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('pick-food-gallery')));
    await tester.pumpAndSettle();
    await tester.dragUntilVisible(
      find.byKey(const ValueKey('analyze-food-image')),
      find.byType(ListView).first,
      const Offset(0, -300),
    );
    await tester.drag(find.byType(ListView).first, const Offset(0, -100));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('analyze-food-image')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const ValueKey('confirm-food-scan')));
    await tester.drag(find.byType(ListView).first, const Offset(0, -120));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('confirm-food-scan')));
    await tester.pumpAndSettle();

    expect(repository.calls, 1);
    expect(
      find.textContaining('ค่าที่แก้ไว้ยังอยู่', skipOffstage: false),
      findsOneWidget,
    );
    expect(
      tester
          .widget<TextFormField>(find.byKey(const ValueKey('calories-field')))
          .controller
          ?.text,
      '540',
    );

    repository.fail = false;
    await tester.ensureVisible(find.byKey(const ValueKey('confirm-food-scan')));
    await tester.tap(find.byKey(const ValueKey('confirm-food-scan')));
    await tester.pumpAndSettle();
    expect(repository.calls, 2);
    expect(find.text('บันทึกมื้อนี้แล้ว'), findsOneWidget);
  });

  testWidgets('remains usable at 320x640 and 200 percent text', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await tester.pumpWidget(
      app(
        picker: _FakeImagePicker(),
        analysis: _FakeAnalysisService(),
        repository: _FakeFoodScanMealRepository(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.dragUntilVisible(
      find.byKey(const ValueKey('pick-food-gallery')),
      find.byType(ListView).first,
      const Offset(0, -300),
    );
    await tester.drag(find.byType(ListView).first, const Offset(0, -100));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('pick-food-gallery')));
    await tester.pumpAndSettle();
    await tester.dragUntilVisible(
      find.byKey(const ValueKey('analyze-food-image')),
      find.byType(ListView).first,
      const Offset(0, -300),
    );
    await tester.drag(find.byType(ListView).first, const Offset(0, -100));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('analyze-food-image')));
    await tester.pumpAndSettle();
    await tester.dragUntilVisible(
      find.byKey(const ValueKey('confirm-food-scan')),
      find.byType(ListView).first,
      const Offset(0, -300),
    );
    expect(find.byKey(const ValueKey('confirm-food-scan')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

class _FakeImagePicker implements FoodImagePicker {
  final image = FoodScanImage(
    bytes: Uint8List.fromList(
      base64Decode(
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',
      ),
    ),
    mimeType: 'image/png',
    displayName: 'meal.png',
  );

  @override
  Future<FoodScanImage?> pick(FoodImageSource source) async => image;

  @override
  Future<FoodScanImage?> recoverLostImage() async => null;
}

class _FakeAnalysisService implements FoodAnalysisService {
  _FakeAnalysisService({this.failuresRemaining = 0});

  int failuresRemaining;
  int calls = 0;

  @override
  Future<FoodScanResult> analyze(FoodScanImage image) async {
    calls++;
    if (failuresRemaining > 0) {
      failuresRemaining--;
      throw StateError('private SDK detail');
    }
    return FoodScanResult(
      foodName: 'ข้าวกะเพราไก่',
      nutrition: NutritionEstimate(
        calories: 540,
        proteinGrams: 28,
        carbsGrams: 65,
        fatGrams: 18,
      ),
      assumption: 'ประเมินจากอาหารหนึ่งจาน ปริมาณจริงอาจต่างออกไป',
    );
  }
}

class _FakeFoodScanMealRepository implements FoodScanMealRepository {
  _FakeFoodScanMealRepository({this.fail = false});

  bool fail;
  int calls = 0;
  String? userId;
  String? foodName;
  NutritionEstimate? nutrition;

  @override
  Future<String> createFoodScanMeal({
    required String userId,
    required String foodName,
    required NutritionEstimate nutrition,
  }) async {
    calls++;
    this.userId = userId;
    this.foodName = foodName;
    this.nutrition = nutrition;
    if (fail) throw StateError('private SDK detail');
    return 'meal-$calls';
  }
}
