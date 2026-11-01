import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

enum FirebaseMode { live, emulator }

class FirebaseConfigurationException implements Exception {
  const FirebaseConfigurationException(this.message);

  final String message;

  @override
  String toString() => 'FirebaseConfigurationException: $message';
}

/// Client identifiers come from an ignored --dart-define-from-file JSON file.
/// No service-account credentials belong in a mobile application.
class FirebaseConfig {
  const FirebaseConfig._({
    required this.mode,
    this.options,
    this.emulatorHost = '10.0.2.2',
    this.firestorePort = 8080,
    this.useDebugAppCheck = false,
  });

  static const liveProjectId = 'muenee-pj';
  static const demoProjectId = 'demo-muenee-pj';

  factory FirebaseConfig.fromEnvironment() => FirebaseConfig.fromValues(const {
    'FIREBASE_MODE': String.fromEnvironment(
      'FIREBASE_MODE',
      defaultValue: 'live',
    ),
    'FIREBASE_PROJECT_ID': String.fromEnvironment('FIREBASE_PROJECT_ID'),
    'FIREBASE_ANDROID_APP_ID': String.fromEnvironment(
      'FIREBASE_ANDROID_APP_ID',
    ),
    'FIREBASE_API_KEY': String.fromEnvironment('FIREBASE_API_KEY'),
    'FIREBASE_MESSAGING_SENDER_ID': String.fromEnvironment(
      'FIREBASE_MESSAGING_SENDER_ID',
    ),
    'FIREBASE_STORAGE_BUCKET': String.fromEnvironment(
      'FIREBASE_STORAGE_BUCKET',
    ),
    'FIREBASE_EMULATOR_HOST': String.fromEnvironment(
      'FIREBASE_EMULATOR_HOST',
      defaultValue: '10.0.2.2',
    ),
    'FIREBASE_FIRESTORE_PORT': String.fromEnvironment(
      'FIREBASE_FIRESTORE_PORT',
      defaultValue: '8080',
    ),
    'FIREBASE_APP_CHECK_DEBUG': String.fromEnvironment(
      'FIREBASE_APP_CHECK_DEBUG',
      defaultValue: 'false',
    ),
  }, isDebugBuild: kDebugMode);

  @visibleForTesting
  factory FirebaseConfig.fromValues(
    Map<String, String> values, {
    required bool isDebugBuild,
  }) {
    String value(String key, [String fallback = '']) =>
        (values[key] ?? fallback).trim();

    final mode = switch (value('FIREBASE_MODE', 'live')) {
      'live' => FirebaseMode.live,
      'emulator' => FirebaseMode.emulator,
      _ => throw const FirebaseConfigurationException('Invalid FIREBASE_MODE.'),
    };
    final debugAppCheck = switch (value('FIREBASE_APP_CHECK_DEBUG', 'false')) {
      'true' => true,
      'false' => false,
      _ => throw const FirebaseConfigurationException(
        'FIREBASE_APP_CHECK_DEBUG must be true or false.',
      ),
    };
    if (!isDebugBuild && (mode == FirebaseMode.emulator || debugAppCheck)) {
      throw const FirebaseConfigurationException(
        'Emulators and debug App Check require a debug build.',
      );
    }
    if (mode == FirebaseMode.emulator) {
      // Always use a demo project, even if a live config was passed as well.
      final host = value('FIREBASE_EMULATOR_HOST', '10.0.2.2');
      if (!{'10.0.2.2', '127.0.0.1', 'localhost'}.contains(host)) {
        throw const FirebaseConfigurationException(
          'Use the Android host alias or loopback with adb reverse.',
        );
      }
      final port = int.tryParse(value('FIREBASE_FIRESTORE_PORT', '8080'));
      if (port == null || port < 1 || port > 65535) {
        throw const FirebaseConfigurationException('Invalid Firestore port.');
      }
      return FirebaseConfig._(
        mode: mode,
        emulatorHost: host,
        firestorePort: port,
      );
    }

    for (final key in [
      'FIREBASE_PROJECT_ID',
      'FIREBASE_ANDROID_APP_ID',
      'FIREBASE_API_KEY',
      'FIREBASE_MESSAGING_SENDER_ID',
    ]) {
      if (value(key).isEmpty) {
        throw FirebaseConfigurationException('Missing $key.');
      }
    }
    final senderId = value('FIREBASE_MESSAGING_SENDER_ID');
    final appId = value('FIREBASE_ANDROID_APP_ID');
    if (value('FIREBASE_PROJECT_ID') != liveProjectId ||
        !RegExp(r'^\d+$').hasMatch(senderId) ||
        !RegExp('^1:$senderId:android:[a-fA-F0-9]+\$').hasMatch(appId)) {
      throw const FirebaseConfigurationException(
        'Config must match the muenee-pj Android application.',
      );
    }
    return FirebaseConfig._(
      mode: mode,
      useDebugAppCheck: debugAppCheck,
      options: FirebaseOptions(
        apiKey: value('FIREBASE_API_KEY'),
        appId: appId,
        messagingSenderId: senderId,
        projectId: liveProjectId,
        storageBucket: value('FIREBASE_STORAGE_BUCKET').isEmpty
            ? null
            : value('FIREBASE_STORAGE_BUCKET'),
      ),
    );
  }

  final FirebaseMode mode;
  final FirebaseOptions? options;
  final String emulatorHost;
  final int firestorePort;
  final bool useDebugAppCheck;

  String get projectId =>
      mode == FirebaseMode.emulator ? demoProjectId : liveProjectId;
  String get appName => defaultFirebaseAppName;

  FirebaseOptions get resolvedOptions =>
      options ??
      const FirebaseOptions(
        apiKey: '12345',
        appId: '1:1:android:1',
        messagingSenderId: '',
        projectId: demoProjectId,
      );
}
