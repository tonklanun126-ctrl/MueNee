import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:muenee/app/theme/app_theme.dart';
import 'package:muenee/core/firebase/firebase_config.dart';
import 'package:muenee/core/firebase/firebase_initializer.dart';
import 'package:muenee/features/auth/account_screen.dart';
import 'package:muenee/features/auth/auth_repository.dart';

// Never accepts a live project or credentials. OOB codes belong only to the
// isolated Auth emulator; no real email is sent by this test.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  final screenshots = <Map<String, Object>>[];
  binding.reportData = {'screenshots': screenshots};

  testWidgets('Android Auth registration, verification, reset and sign out', (
    tester,
  ) async {
    final config = FirebaseConfig.fromEnvironment();
    if (config.mode != FirebaseMode.emulator ||
        config.projectId != 'demo-muenee-pj') {
      throw StateError(
        'Auth lifecycle test requires the isolated demo emulator.',
      );
    }
    final services = await FlutterFirebaseInitializer(config).initialize();
    final auth = FirebaseAuth.instanceFor(app: services.app);
    await auth.useAuthEmulator(config.emulatorHost, 9099);
    final repo = FirebaseAuthRepository(auth);
    await repo.signOut();
    final email =
        'phase3-${DateTime.now().microsecondsSinceEpoch}@example.test';
    const password = 'Emulator-only-123!';
    const newPassword = 'Emulator-reset-456!';
    final captureKey = GlobalKey();

    Future<void> waitFor(Finder finder) async {
      for (var attempt = 0; attempt < 100; attempt++) {
        await tester.pump(const Duration(milliseconds: 200));
        if (finder.evaluate().isNotEmpty) {
          await tester.pumpAndSettle();
          return;
        }
      }
      fail('Expected Auth UI state did not appear.');
    }

    Future<void> tapText(String text) async {
      await tester.ensureVisible(find.text(text));
      await tester.tap(find.text(text));
      await tester.pump();
    }

    Future<void> capture(String name) async {
      await tester.pumpAndSettle();
      final boundary =
          captureKey.currentContext!.findRenderObject()!
              as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 2);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      screenshots.add({
        'screenshotName': name,
        'bytes': bytes!.buffer.asUint8List(),
      });
      image.dispose();
    }

    Future<String> oobCode(String type) async {
      final client = HttpClient();
      try {
        final request = await client.getUrl(
          Uri.parse(
            'http://${config.emulatorHost}:9099/emulator/v1/projects/demo-muenee-pj/oobCodes',
          ),
        );
        final response = await request.close();
        expect(response.statusCode, 200);
        final data = jsonDecode(
          await utf8.decoder.bind(response).join(),
        ) as Map<String, dynamic>;
        final codes = (data['oobCodes'] as List).cast<Map<String, dynamic>>();
        return codes.lastWhere(
              (code) => code['email'] == email && code['requestType'] == type,
            )['oobCode']
            as String;
      } finally {
        client.close(force: true);
      }
    }

    await tester.pumpWidget(
      ProviderScope(
        overrides: [authRepositoryProvider.overrideWith((ref) async => repo)],
        child: RepaintBoundary(
          key: captureKey,
          child: MaterialApp(
            theme: AppTheme.light,
            home: const AccountScreen(),
          ),
        ),
      ),
    );
    await waitFor(find.widgetWithText(FilledButton, 'เข้าสู่ระบบ'));
    await capture('sign-in');
    await tapText('ยังไม่มีบัญชี? สร้างบัญชี');
    await tester.pumpAndSettle();
    await capture('register');
    await tester.enterText(find.byType(TextFormField).at(0), email);
    await tester.enterText(find.byType(TextFormField).at(1), password);
    await tester.enterText(find.byType(TextFormField).at(2), password);
    await tester.ensureVisible(find.widgetWithText(FilledButton, 'สร้างบัญชี'));
    await tester.tap(find.widgetWithText(FilledButton, 'สร้างบัญชี'));
    await waitFor(find.text('ยังไม่ได้ยืนยันอีเมล'));
    final testUid = auth.currentUser!.uid;
    addTearDown(() async {
      // Delete only the account created by this run, never flush emulator data.
      if (auth.currentUser?.uid == testUid) await auth.currentUser!.delete();
    });
    await capture('unverified');
    await tapText('ส่งอีเมลยืนยัน');
    await waitFor(find.text('ส่งลิงก์แล้ว โปรดเปิดอีเมลเพื่อยืนยันบัญชี'));
    await auth.applyActionCode(await oobCode('VERIFY_EMAIL'));
    await tapText('ยืนยันแล้ว ตรวจสอบอีกครั้ง');
    await waitFor(find.text('ยืนยันอีเมลแล้ว'));
    await capture('verified');
    await tapText('ออกจากระบบ');
    await waitFor(find.widgetWithText(FilledButton, 'เข้าสู่ระบบ'));
    expect(auth.currentUser, isNull);
    await expectLater(
      repo.verifyEmail(),
      throwsA(isA<FirebaseAuthException>()),
    );
    await expectLater(repo.reload(), throwsA(isA<FirebaseAuthException>()));

    await tapText('ลืมรหัสผ่าน?');
    await tester.pumpAndSettle();
    await capture('reset');
    await tester.enterText(find.byType(TextFormField).first, email);
    await tapText('ส่งลิงก์รีเซ็ต');
    await waitFor(find.textContaining('หากอีเมลนี้มีบัญชี'));
    final code = await oobCode('PASSWORD_RESET');
    expect(await auth.verifyPasswordResetCode(code), email);
    await auth.confirmPasswordReset(code: code, newPassword: newPassword);
    await expectLater(
      repo.signIn(email, password),
      throwsA(isA<FirebaseAuthException>()),
    );
    await tapText('กลับไปเข้าสู่ระบบ');
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, email);
    await tester.enterText(find.byType(TextFormField).at(1), newPassword);
    await tester.ensureVisible(
      find.widgetWithText(FilledButton, 'เข้าสู่ระบบ'),
    );
    await tester.tap(find.widgetWithText(FilledButton, 'เข้าสู่ระบบ'));
    await waitFor(find.text('ยืนยันอีเมลแล้ว'));
    expect(auth.currentUser!.uid, testUid);
    expect(await repo.changes.first, isA<Account>());
    await auth.currentUser!.delete();
    await waitFor(find.widgetWithText(FilledButton, 'เข้าสู่ระบบ'));
    expect(tester.takeException(), isNull);
  });
}
