import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:muenee/core/firebase/firebase_config.dart';
import 'package:muenee/core/firebase/firebase_initializer.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('native Firebase initializes once and server rules deny access', (
    tester,
  ) async {
    final config = FirebaseConfig.fromEnvironment();
    final initializer = FlutterFirebaseInitializer(config);
    final first = initializer.initialize();
    final second = initializer.initialize();
    expect(identical(first, second), isTrue);
    final services = await first.timeout(const Duration(seconds: 30));
    expect(services.app.options.projectId, config.projectId);
    expect(services.firestore.app.name, config.appName);
    expect(identical(await initializer.initialize(), services), isTrue);
    if (config.mode == FirebaseMode.emulator) {
      expect(services.firestore.settings.persistenceEnabled, isFalse);
      expect(
        services.firestore.settings.host,
        '${config.emulatorHost}:${config.firestorePort}',
      );
      expect(services.firestore.settings.sslEnabled, isFalse);
    }
    // Read-only, server-only probe: no production health collection or writes.
    // A denied response proves the request reached rules; SDK init alone cannot.
    await expectLater(
      services.firestore
          .doc('_phase2_probe/no-data')
          .get(const GetOptions(source: Source.server))
          .timeout(const Duration(seconds: 20)),
      throwsA(
        isA<FirebaseException>().having(
          (error) => error.code,
          'server security rule response',
          'permission-denied',
        ),
      ),
    );
  });
}
