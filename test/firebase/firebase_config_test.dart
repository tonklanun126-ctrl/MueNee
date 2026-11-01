import 'package:flutter_test/flutter_test.dart';
import 'package:muenee/core/firebase/firebase_config.dart';

void main() {
  const live = {
    'FIREBASE_PROJECT_ID': 'muenee-pj',
    'FIREBASE_ANDROID_APP_ID': '1:123456:android:abcdef123456',
    'FIREBASE_API_KEY': 'fictional-test-key',
    'FIREBASE_MESSAGING_SENDER_ID': '123456',
  };

  test(
    'live config requires all identifiers; error does not disclose keys',
    () {
      for (final key in live.keys) {
        final incomplete = {...live}..remove(key);
        expect(
          () => FirebaseConfig.fromValues(incomplete, isDebugBuild: true),
          throwsA(
            isA<FirebaseConfigurationException>().having(
              (error) => error.toString(),
              'redacted error',
              isNot(contains('fictional-test-key')),
            ),
          ),
        );
      }
    },
  );

  test('live mode uses the approved Android project and Play Integrity', () {
    final config = FirebaseConfig.fromValues(live, isDebugBuild: false);
    expect(config.mode, FirebaseMode.live);
    expect(config.projectId, 'muenee-pj');
    expect(config.options!.appId, live['FIREBASE_ANDROID_APP_ID']);
    expect(config.useDebugAppCheck, isFalse);
    expect(config.options!.storageBucket, isNull);
  });

  test('rejects another project and mismatched Android registration', () {
    for (final invalid in [
      {...live, 'FIREBASE_PROJECT_ID': 'another-project'},
      {...live, 'FIREBASE_ANDROID_APP_ID': '1:123456:ios:abcdef'},
      {...live, 'FIREBASE_MESSAGING_SENDER_ID': '999999'},
      {...live, 'FIREBASE_MODE': 'livve'},
      {...live, 'FIREBASE_APP_CHECK_DEBUG': 'yes'},
    ]) {
      expect(
        () => FirebaseConfig.fromValues(invalid, isDebugBuild: true),
        throwsA(isA<FirebaseConfigurationException>()),
      );
    }
  });

  test('emulator ignores live identifiers and uses isolated demo project', () {
    final config = FirebaseConfig.fromValues({
      ...live,
      'FIREBASE_MODE': 'emulator',
    }, isDebugBuild: true);
    expect(config.projectId, 'demo-muenee-pj');
    expect(config.options, isNull);
    expect(config.resolvedOptions.projectId, 'demo-muenee-pj');
    expect(config.appName, '[DEFAULT]');
    expect(config.emulatorHost, '10.0.2.2');
    expect(config.firestorePort, 8080);
  });

  test('profile and release builds reject emulator and debug App Check', () {
    for (final values in [
      {...live, 'FIREBASE_MODE': 'emulator'},
      {...live, 'FIREBASE_APP_CHECK_DEBUG': 'true'},
    ]) {
      expect(
        () => FirebaseConfig.fromValues(values, isDebugBuild: false),
        throwsA(isA<FirebaseConfigurationException>()),
      );
    }
  });

  test(
    'emulator accepts loopback for USB reverse, rejects unsafe endpoints',
    () {
      final base = {'FIREBASE_MODE': 'emulator'};
      expect(
        FirebaseConfig.fromValues({
          ...base,
          'FIREBASE_EMULATOR_HOST': '127.0.0.1',
        }, isDebugBuild: true).emulatorHost,
        '127.0.0.1',
      );
      for (final invalid in [
        {...base, 'FIREBASE_EMULATOR_HOST': 'example.com'},
        {...base, 'FIREBASE_FIRESTORE_PORT': '0'},
        {...base, 'FIREBASE_FIRESTORE_PORT': '65536'},
        {...base, 'FIREBASE_FIRESTORE_PORT': 'eight'},
      ]) {
        expect(
          () => FirebaseConfig.fromValues(invalid, isDebugBuild: true),
          throwsA(isA<FirebaseConfigurationException>()),
        );
      }
    },
  );
}
