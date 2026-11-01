import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:muenee/app/startup/startup_app.dart';
import 'package:muenee/core/firebase/firebase_initializer.dart';
import 'package:muenee/core/firebase/firebase_providers.dart';

void main() {
  FirebaseServices ready() =>
      FirebaseServices(app: _FakeApp(), firestore: _FakeFirestore());

  Future<void> mount(WidgetTester tester, _Initializer initializer) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [firebaseInitializerProvider.overrideWithValue(initializer)],
        child: const StartupApp(),
      ),
    );
  }

  testWidgets('waits for Firebase before showing the existing home', (
    tester,
  ) async {
    final pending = Completer<FirebaseServices>();
    await mount(tester, _Initializer(() => pending.future));
    expect(find.text('กำลังเตรียม MueNee…'), findsOneWidget);
    expect(find.text('ตั้งค่าโปรไฟล์'), findsNothing);
    pending.complete(ready());
    await tester.pumpAndSettle();
    expect(find.text('ตั้งค่าโปรไฟล์'), findsOneWidget);
    expect(find.text('ตั้งค่าอาหารที่กิน'), findsOneWidget);
  });

  testWidgets('failure is readable, hides SDK details, and retry succeeds', (
    tester,
  ) async {
    var calls = 0;
    await mount(
      tester,
      _Initializer(() async {
        if (++calls == 1) {
          throw FirebaseException(
            plugin: 'core',
            code: 'initialization-failed',
            message: 'internal-detail-not-for-ui',
          );
        }
        return ready();
      }),
    );
    await tester.pumpAndSettle();
    expect(find.text('ยังเปิดแอปไม่ได้'), findsOneWidget);
    expect(find.textContaining('internal-detail'), findsNothing);
    expect(calls, 1);
    await tester.tap(find.text('ลองอีกครั้ง'));
    await tester.pumpAndSettle();
    expect(find.text('ตั้งค่าโปรไฟล์'), findsOneWidget);
    expect(calls, 2);
  });

  testWidgets(
    'startup timeout exposes recovery instead of an endless spinner',
    (tester) async {
      final pending = Completer<FirebaseServices>();
      await mount(tester, _Initializer(() => pending.future));
      await tester.pump(const Duration(seconds: 21));
      await tester.pump();
      expect(find.text('ลองอีกครั้ง'), findsOneWidget);
      pending.complete(ready());
      await tester.pump();
      // The timed-out result must not replace the error without an explicit retry.
      expect(find.text('ยังเปิดแอปไม่ได้'), findsOneWidget);
      await tester.tap(find.text('ลองอีกครั้ง'));
      await tester.pumpAndSettle();
      expect(find.text('ตั้งค่าโปรไฟล์'), findsOneWidget);
    },
  );

  testWidgets('startup error remains usable on small screens with large text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 480);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await mount(tester, _Initializer(() => Future.error(StateError('failed'))));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('ลองอีกครั้ง'));
    expect(tester.takeException(), isNull);
  });
}

class _Initializer implements FirebaseInitializer {
  _Initializer(this.run);
  final Future<FirebaseServices> Function() run;
  @override
  Future<FirebaseServices> initialize() => run();
}

class _FakeApp implements FirebaseApp {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeFirestore implements FirebaseFirestore {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
