import 'dart:async';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../firebase/firebase_config.dart';
import 'telemetry_settings.dart';

enum MueNeeAnalyticsEvent {
  mealFlowStarted('meal_flow_started'),
  budgetConfirmed('budget_confirmed'),
  preferencesConfirmed('preferences_confirmed'),
  recommendationMealRecorded('recommendation_meal_recorded'),
  foodScanAnalysisCompleted('food_scan_analysis_completed'),
  foodScanMealRecorded('food_scan_meal_recorded');

  const MueNeeAnalyticsEvent(this.eventName);
  final String eventName;
}

abstract interface class TelemetryService {
  NavigatorObserver get navigatorObserver;
  Future<void> applySettings(TelemetrySettings settings);
  Future<void> logEvent(MueNeeAnalyticsEvent event);
  Future<void> recordNonFatal(String code, StackTrace stackTrace);
  void installGlobalErrorHandlers();
  void uninstallGlobalErrorHandlers();
}

class NoopTelemetryService implements TelemetryService {
  const NoopTelemetryService();

  @override
  NavigatorObserver get navigatorObserver => NavigatorObserver();

  @override
  Future<void> applySettings(TelemetrySettings settings) async {}

  @override
  Future<void> logEvent(MueNeeAnalyticsEvent event) async {}

  @override
  Future<void> recordNonFatal(String code, StackTrace stackTrace) async {}

  @override
  void installGlobalErrorHandlers() {}

  @override
  void uninstallGlobalErrorHandlers() {}
}

TelemetryService telemetryServiceFor(FirebaseApp app) {
  try {
    if (app.options.projectId == FirebaseConfig.liveProjectId) {
      return FirebaseTelemetryService(app);
    }
  } catch (_) {
    // Test doubles and partially initialized apps must never enable telemetry.
  }
  return const NoopTelemetryService();
}

class FirebaseTelemetryService implements TelemetryService {
  FirebaseTelemetryService(FirebaseApp app)
    : _analytics = FirebaseAnalytics.instanceFor(app: app),
      _crashlytics = FirebaseCrashlytics.instance {
    _observer = FirebaseAnalyticsObserver(
      analytics: _analytics,
      nameExtractor: (settings) => settings.name,
    );
  }

  final FirebaseAnalytics _analytics;
  final FirebaseCrashlytics _crashlytics;
  late final FirebaseAnalyticsObserver _observer;
  FlutterExceptionHandler? _previousFlutterHandler;
  bool Function(Object, StackTrace)? _previousPlatformHandler;
  FlutterExceptionHandler? _installedFlutterHandler;
  bool Function(Object, StackTrace)? _installedPlatformHandler;

  @override
  NavigatorObserver get navigatorObserver => _observer;

  @override
  Future<void> applySettings(TelemetrySettings settings) async {
    await _analytics.setAnalyticsCollectionEnabled(settings.analyticsEnabled);
    await _crashlytics.setCrashlyticsCollectionEnabled(
      settings.crashReportsEnabled,
    );
  }

  @override
  Future<void> logEvent(MueNeeAnalyticsEvent event) =>
      _analytics.logEvent(name: event.eventName);

  @override
  Future<void> recordNonFatal(String code, StackTrace stackTrace) =>
      _crashlytics.recordError(
        StateError(code),
        stackTrace,
        reason: code,
        fatal: false,
      );

  @override
  void installGlobalErrorHandlers() {
    if (_installedFlutterHandler != null) return;
    _previousFlutterHandler = FlutterError.onError;
    _previousPlatformHandler = PlatformDispatcher.instance.onError;

    _installedFlutterHandler = (details) {
      final previous = _previousFlutterHandler;
      if (previous != null) {
        previous(details);
      } else {
        FlutterError.presentError(details);
      }
      unawaited(_crashlytics.recordFlutterFatalError(details));
    };
    _installedPlatformHandler = (error, stackTrace) {
      unawaited(_crashlytics.recordError(error, stackTrace, fatal: true));
      return _previousPlatformHandler?.call(error, stackTrace) ?? true;
    };
    FlutterError.onError = _installedFlutterHandler;
    PlatformDispatcher.instance.onError = _installedPlatformHandler;
  }

  @override
  void uninstallGlobalErrorHandlers() {
    if (FlutterError.onError == _installedFlutterHandler) {
      FlutterError.onError = _previousFlutterHandler;
    }
    if (PlatformDispatcher.instance.onError == _installedPlatformHandler) {
      PlatformDispatcher.instance.onError = _previousPlatformHandler;
    }
    _installedFlutterHandler = null;
    _installedPlatformHandler = null;
  }
}
