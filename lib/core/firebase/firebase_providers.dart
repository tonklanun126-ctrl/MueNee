import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'firebase_config.dart';
import 'firebase_initializer.dart';

final firebaseConfigProvider = Provider<FirebaseConfig>(
  (ref) => FirebaseConfig.fromEnvironment(),
);

final firebaseInitializerProvider = Provider<FirebaseInitializer>(
  (ref) => FlutterFirebaseInitializer(ref.watch(firebaseConfigProvider)),
);

final firebaseStartupProvider = FutureProvider<FirebaseServices>((ref) async {
  try {
    return await ref
        .watch(firebaseInitializerProvider)
        .initialize()
        .timeout(const Duration(seconds: 20));
  } catch (error, stackTrace) {
    if (kDebugMode) {
      // Avoid printing SDK options, API keys or App Check tokens.
      final category = switch (error) {
        FirebaseException e => '${e.plugin}/${e.code}',
        FirebaseConfigurationException e => e.message,
        TimeoutException() => 'initialization-timeout',
        _ => error.runtimeType.toString(),
      };
      debugPrint('MueNee Firebase initialization failed: $category');
      debugPrintStack(stackTrace: stackTrace);
    }
    rethrow;
  }
}, retry: (retryCount, error) => null);

/// Consumers must await startup; no code accesses FirebaseFirestore.instance.
final firestoreProvider = Provider<FirebaseFirestore>(
  (ref) => ref.watch(firebaseStartupProvider).requireValue.firestore,
);
