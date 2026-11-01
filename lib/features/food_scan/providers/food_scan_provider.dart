import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/firebase/firebase_providers.dart';
import '../../restaurants/models/menu_item.dart';
import '../../tracking/repositories/meal_log_repository.dart';
import '../models/food_scan_result.dart';
import '../services/food_analysis_service.dart';
import '../services/food_image_picker.dart';
import '../../../core/monitoring/telemetry_providers.dart';
import '../../../core/monitoring/telemetry_service.dart';

enum FoodScanStatus { idle, picking, ready, analyzing, review, saving, saved }

class FoodScanState {
  const FoodScanState({
    this.status = FoodScanStatus.idle,
    this.image,
    this.result,
    this.message,
    this.revision = 0,
  });

  final FoodScanStatus status;
  final FoodScanImage? image;
  final FoodScanResult? result;
  final String? message;
  final int revision;

  FoodScanState copyWith({
    FoodScanStatus? status,
    FoodScanImage? image,
    FoodScanResult? result,
    String? message,
    bool clearMessage = false,
    int? revision,
  }) => FoodScanState(
    status: status ?? this.status,
    image: image ?? this.image,
    result: result ?? this.result,
    message: clearMessage ? null : message ?? this.message,
    revision: revision ?? this.revision,
  );
}

final foodImagePickerProvider = Provider<FoodImagePicker>(
  (ref) => DeviceFoodImagePicker(),
);

final foodAnalysisServiceProvider = Provider<FoodAnalysisService>(
  (ref) => FirebaseFoodAnalysisService(
    app: ref.watch(firebaseStartupProvider).requireValue.app,
  ),
);

final foodScanMealRepositoryProvider = Provider<FoodScanMealRepository>(
  (ref) => FirestoreMealLogRepository(ref.watch(firestoreProvider)),
);

final foodScanProvider =
    NotifierProvider.autoDispose<FoodScanController, FoodScanState>(
      FoodScanController.new,
    );

class FoodScanController extends Notifier<FoodScanState> {
  @override
  FoodScanState build() => const FoodScanState();

  Future<void> recoverLostImage() async {
    if (state.status != FoodScanStatus.idle) return;
    try {
      final image = await ref.read(foodImagePickerProvider).recoverLostImage();
      if (image != null) {
        state = FoodScanState(status: FoodScanStatus.ready, image: image);
      }
    } catch (error, stack) {
      _debug('Food image recovery failed', error, stack);
      state = const FoodScanState(
        message: 'กู้คืนภาพเดิมไม่สำเร็จ กรุณาเลือกภาพอีกครั้ง',
      );
    }
  }

  Future<void> pick(FoodImageSource source) async {
    if (_busy) return;
    final previous = state;
    state = previous.copyWith(
      status: FoodScanStatus.picking,
      clearMessage: true,
    );
    try {
      final image = await ref.read(foodImagePickerProvider).pick(source);
      if (image == null) {
        state = previous.copyWith(clearMessage: true);
        return;
      }
      state = FoodScanState(status: FoodScanStatus.ready, image: image);
    } catch (error, stack) {
      _debug('Food image selection failed', error, stack);
      state = previous.copyWith(
        message: error is FormatException
            ? 'รองรับเฉพาะภาพ JPG, PNG หรือ WebP ขนาดไม่เกิน 10 MB'
            : 'เปิดภาพไม่สำเร็จ กรุณาลองอีกครั้ง',
      );
    }
  }

  Future<void> analyze() async {
    final image = state.image;
    if (image == null || _busy) return;
    state = state.copyWith(
      status: FoodScanStatus.analyzing,
      clearMessage: true,
    );
    try {
      final result = await ref.read(foodAnalysisServiceProvider).analyze(image);
      state = FoodScanState(
        status: FoodScanStatus.review,
        image: image,
        result: result,
        revision: state.revision + 1,
      );
      unawaited(
        ref
            .read(telemetryServiceProvider)
            .logEvent(MueNeeAnalyticsEvent.foodScanAnalysisCompleted),
      );
    } on FoodNotRecognizedException catch (error, stack) {
      _debug('Food was not recognized', error, stack);
      state = FoodScanState(
        status: FoodScanStatus.ready,
        image: image,
        message:
            'ยังระบุอาหารจากภาพนี้ไม่ได้ ลองถ่ายให้เห็นอาหารและปริมาณชัดขึ้น',
        revision: state.revision,
      );
    } catch (error, stack) {
      _debug('Food analysis failed', error, stack);
      unawaited(
        ref
            .read(telemetryServiceProvider)
            .recordNonFatal('food_scan_analysis_failed', stack),
      );
      state = FoodScanState(
        status: FoodScanStatus.ready,
        image: image,
        message: 'วิเคราะห์ภาพไม่สำเร็จ ภาพยังไม่ถูกบันทึก กรุณาลองอีกครั้ง',
        revision: state.revision,
      );
    }
  }

  Future<bool> confirmAndSave({
    required String userId,
    required String foodName,
    required int calories,
    required double proteinGrams,
    required double carbsGrams,
    required double fatGrams,
  }) async {
    final currentResult = state.result;
    if (state.status != FoodScanStatus.review || currentResult == null) {
      return false;
    }
    try {
      final normalizedFoodName = foodName.trim();
      if (userId.trim().isEmpty ||
          normalizedFoodName.isEmpty ||
          normalizedFoodName.length > 160) {
        throw const FormatException('Invalid confirmed food scan meal');
      }
      final nutrition = NutritionEstimate(
        calories: calories,
        proteinGrams: proteinGrams,
        carbsGrams: carbsGrams,
        fatGrams: fatGrams,
      );
      state = state.copyWith(status: FoodScanStatus.saving, clearMessage: true);
      await ref
          .read(foodScanMealRepositoryProvider)
          .createFoodScanMeal(
            userId: userId,
            foodName: normalizedFoodName,
            nutrition: nutrition,
          );
      state = state.copyWith(status: FoodScanStatus.saved, clearMessage: true);
      unawaited(
        ref
            .read(telemetryServiceProvider)
            .logEvent(MueNeeAnalyticsEvent.foodScanMealRecorded),
      );
      return true;
    } catch (error, stack) {
      _debug('Food scan meal save failed', error, stack);
      unawaited(
        ref
            .read(telemetryServiceProvider)
            .recordNonFatal('food_scan_meal_save_failed', stack),
      );
      state = state.copyWith(
        status: FoodScanStatus.review,
        message: 'บันทึกมื้อไม่สำเร็จ ค่าที่แก้ไว้ยังอยู่ กรุณาลองอีกครั้ง',
      );
      return false;
    }
  }

  void reset() => state = const FoodScanState();

  bool get _busy =>
      state.status == FoodScanStatus.picking ||
      state.status == FoodScanStatus.analyzing ||
      state.status == FoodScanStatus.saving;

  void _debug(String label, Object error, StackTrace stack) {
    if (!kDebugMode) return;
    debugPrint('$label: ${error.runtimeType}');
    debugPrintStack(stackTrace: stack);
  }
}
