import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:muenee/core/firebase/firebase_config.dart';
import 'package:muenee/core/firebase/firebase_initializer.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('create an emulator session for process restart', (tester) async {
    final config = FirebaseConfig.fromEnvironment();
    if (config.mode != FirebaseMode.emulator ||
        config.projectId != FirebaseConfig.demoProjectId) {
      throw StateError(
        'Persistence setup requires the isolated demo emulator.',
      );
    }
    final services = await FlutterFirebaseInitializer(config).initialize();
    final auth = FirebaseAuth.instanceFor(app: services.app);
    await auth.useAuthEmulator(config.emulatorHost, 9099);
    await auth.signOut();
    final email =
        'phase3-persist-${DateTime.now().microsecondsSinceEpoch}@example.test';
    await auth.createUserWithEmailAndPassword(
      email: email,
      password: 'Emulator-persistence-only-123!',
    );
    expect(auth.currentUser?.email, email);
    // Intentionally leave this generated emulator session signed in. The next
    // test runs in a new app process and deletes this exact current account.
  });
}
