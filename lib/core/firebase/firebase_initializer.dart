import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import 'firebase_config.dart';

class FirebaseServices {
  const FirebaseServices({required this.app, required this.firestore});

  final FirebaseApp app;
  final FirebaseFirestore firestore;
}

abstract interface class FirebaseInitializer {
  Future<FirebaseServices> initialize();
}

class FlutterFirebaseInitializer implements FirebaseInitializer {
  FlutterFirebaseInitializer(this.config);

  final FirebaseConfig config;
  Future<FirebaseServices>? _initialization;

  @override
  Future<FirebaseServices> initialize() {
    // Keep one native operation in flight, including across UI timeouts/retry.
    return _initialization ??= _initialize().onError<Object>((
      error,
      stackTrace,
    ) {
      _initialization = null;
      Error.throwWithStackTrace(error, stackTrace);
    });
  }

  Future<FirebaseServices> _initialize() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      throw const FirebaseConfigurationException(
        'MueNee currently configures Firebase for Android only.',
      );
    }
    FirebaseApp? app;
    for (final existing in Firebase.apps) {
      if (existing.name == config.appName) app = existing;
    }
    app ??= await Firebase.initializeApp(options: config.resolvedOptions);
    if (app.options.projectId != config.projectId ||
        app.options != config.resolvedOptions) {
      throw const FirebaseConfigurationException(
        'Existing Firebase app has different configuration; restart the app.',
      );
    }

    if (config.mode == FirebaseMode.live) {
      await FirebaseAppCheck.instanceFor(app: app).activate(
        providerAndroid: config.useDebugAppCheck
            ? const AndroidDebugProvider()
            : const AndroidPlayIntegrityProvider(),
      );
    }
    final firestore = FirebaseFirestore.instanceFor(app: app);
    if (config.mode == FirebaseMode.emulator) {
      // Configure before any reads; do not reuse a persistent live-data cache.
      firestore.settings = const Settings(persistenceEnabled: false);
      firestore.useFirestoreEmulator(
        config.emulatorHost,
        config.firestorePort,
        automaticHostMapping: false,
      );
    }
    // SDK initialization is not proof of network access or App Check attestation.
    // A separate integration test verifies a server response without data writes.
    return FirebaseServices(app: app, firestore: firestore);
  }
}
