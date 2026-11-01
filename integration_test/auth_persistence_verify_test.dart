import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:muenee/core/firebase/firebase_config.dart';
import 'package:muenee/core/firebase/firebase_initializer.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('restore the emulator session in a new app process', (
    tester,
  ) async {
    final config = FirebaseConfig.fromEnvironment();
    if (config.mode != FirebaseMode.emulator ||
        config.projectId != FirebaseConfig.demoProjectId) {
      throw StateError(
        'Persistence verification requires the isolated demo emulator.',
      );
    }
    final services = await FlutterFirebaseInitializer(config).initialize();
    final auth = FirebaseAuth.instanceFor(app: services.app);
    await auth.useAuthEmulator(config.emulatorHost, 9099);
    await auth.authStateChanges().first.timeout(const Duration(seconds: 10));
    final user = auth.currentUser;
    expect(user, isNotNull, reason: 'Firebase Auth session was not restored.');
    expect(user!.email, startsWith('phase3-persist-'));
    expect(user.email, endsWith('@example.test'));
    await user.delete();
    expect(auth.currentUser, isNull);
  });
}
