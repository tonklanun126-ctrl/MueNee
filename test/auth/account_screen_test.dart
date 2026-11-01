import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:muenee/app/theme/app_theme.dart';
import 'package:muenee/features/auth/account_screen.dart';
import 'package:muenee/features/auth/auth_repository.dart';

class FakeAuth implements AuthRepository {
  int calls = 0;
  Object? failure;
  Completer<void>? pending;
  final users = StreamController<Account?>.broadcast();
  @override
  Stream<Account?> get changes async* {
    yield null;
    yield* users.stream;
  }

  Future<void> act() async {
    calls++;
    if (failure != null) throw failure!;
    await pending?.future;
  }

  @override
  Future<void> signIn(String email, String password) => act();
  @override
  Future<void> register(String email, String password) async {
    await act();
    users.add(Account(email, false));
  }

  @override
  Future<void> resetPassword(String email) => act();
  @override
  Future<void> reload() => act();
  @override
  Future<void> verifyEmail() => act();
  @override
  Future<void> signOut() async {
    await act();
    users.add(null);
  }
}

void main() {
  test('CTA and text-action colors retain readable contrast', () {
    double contrast(Color first, Color second) {
      final a = first.computeLuminance();
      final b = second.computeLuminance();
      return a > b ? (a + .05) / (b + .05) : (b + .05) / (a + .05);
    }

    final filled = AppTheme.light.filledButtonTheme.style!;
    final text = AppTheme.light.textButtonTheme.style!;
    expect(
      contrast(
        filled.foregroundColor!.resolve({})!,
        filled.backgroundColor!.resolve({})!,
      ),
      greaterThanOrEqualTo(4.5),
    );
    expect(
      contrast(text.foregroundColor!.resolve({})!, AppTheme.canvas),
      greaterThanOrEqualTo(4.5),
    );
  });

  Future<void> mount(
    WidgetTester tester,
    FakeAuth repo, {
    Account? user,
    bool useRepositoryStream = false,
    double textScale = 1,
  }) async {
    addTearDown(repo.users.close);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWith((ref) async => repo),
          if (!useRepositoryStream)
            accountProvider.overrideWith((ref) => Stream.value(user)),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(textScale)),
            child: child!,
          ),
          home: const AccountScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  test(
    'credential errors do not disclose SDK messages or account existence',
    () {
      expect(
        authErrorMessage(
          FirebaseAuthException(code: 'user-not-found', message: 'secret'),
        ),
        authErrorMessage(FirebaseAuthException(code: 'wrong-password')),
      );
      expect(authErrorMessage(Exception('secret')), isNot(contains('secret')));
    },
  );
  testWidgets('invalid email never submits', (tester) async {
    final repo = FakeAuth();
    await mount(tester, repo);
    await tester.tap(find.widgetWithText(FilledButton, 'เข้าสู่ระบบ'));
    await tester.pumpAndSettle();
    expect(repo.calls, 0);
    expect(find.text('กรุณากรอกอีเมลให้ถูกต้อง'), findsOneWidget);
  });
  testWidgets('registration requires matching passwords', (tester) async {
    final repo = FakeAuth();
    await mount(tester, repo);
    await tester.ensureVisible(find.text('ยังไม่มีบัญชี? สร้างบัญชี'));
    await tester.tap(find.text('ยังไม่มีบัญชี? สร้างบัญชี'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextFormField).at(0),
      'person@example.com',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'password123');
    await tester.enterText(find.byType(TextFormField).at(2), 'different');
    await tester.ensureVisible(find.widgetWithText(FilledButton, 'สร้างบัญชี'));
    await tester.tap(find.widgetWithText(FilledButton, 'สร้างบัญชี'));
    await tester.pumpAndSettle();
    expect(repo.calls, 0);
    expect(find.text('รหัสผ่านไม่ตรงกัน'), findsOneWidget);
  });
  testWidgets('network error is readable and retry enabled', (tester) async {
    final repo = FakeAuth()
      ..failure = FirebaseAuthException(code: 'network-request-failed');
    await mount(tester, repo);
    await tester.enterText(
      find.byType(TextFormField).at(0),
      'person@example.com',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'password123');
    await tester.tap(find.widgetWithText(FilledButton, 'เข้าสู่ระบบ'));
    await tester.pumpAndSettle();
    expect(repo.calls, 1);
    expect(find.textContaining('ตรวจสอบอินเทอร์เน็ต'), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(
            find.widgetWithText(FilledButton, 'เข้าสู่ระบบ'),
          )
          .onPressed,
      isNotNull,
    );
  });
  testWidgets('signed in account exposes verification and sign out', (
    tester,
  ) async {
    final repo = FakeAuth();
    await mount(tester, repo, user: const Account('person@example.com', false));
    expect(find.text('person@example.com'), findsOneWidget);
    await tester.tap(find.text('ส่งอีเมลยืนยัน'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ส่งอีเมลยืนยัน'));
    await tester.pumpAndSettle();
    expect(repo.calls, 1);
    expect(find.text('ออกจากระบบ'), findsOneWidget);
  });

  testWidgets('switching modes preserves email and clears passwords', (
    tester,
  ) async {
    await mount(tester, FakeAuth());
    await tester.enterText(
      find.byType(TextFormField).first,
      'person@example.com',
    );
    await tester.enterText(
      find.byType(TextFormField).at(1),
      'private-password',
    );
    await tester.ensureVisible(find.text('ลืมรหัสผ่าน?'));
    await tester.tap(find.text('ลืมรหัสผ่าน?'));
    await tester.pumpAndSettle();
    expect(find.text('person@example.com'), findsOneWidget);
    expect(find.byType(TextFormField), findsOneWidget);
    await tester.tap(find.text('กลับไปเข้าสู่ระบบ'));
    await tester.pumpAndSettle();
    expect(find.text('person@example.com'), findsOneWidget);
    expect(
      tester
          .widget<TextFormField>(find.byType(TextFormField).at(1))
          .controller!
          .text,
      isEmpty,
    );
  });

  testWidgets('registration then sign out returns to sign in', (tester) async {
    final repo = FakeAuth();
    await mount(tester, repo, useRepositoryStream: true);
    await tester.ensureVisible(find.text('ยังไม่มีบัญชี? สร้างบัญชี'));
    await tester.tap(find.text('ยังไม่มีบัญชี? สร้างบัญชี'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextFormField).at(0),
      'person@example.com',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'password123');
    await tester.enterText(find.byType(TextFormField).at(2), 'password123');
    await tester.ensureVisible(find.widgetWithText(FilledButton, 'สร้างบัญชี'));
    await tester.tap(find.widgetWithText(FilledButton, 'สร้างบัญชี'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('ออกจากระบบ'));
    await tester.tap(find.text('ออกจากระบบ'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(FilledButton, 'เข้าสู่ระบบ'), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(2));
  });

  testWidgets('pending request disables duplicate submission', (tester) async {
    final repo = FakeAuth()..pending = Completer<void>();
    await mount(tester, repo);
    await tester.enterText(
      find.byType(TextFormField).first,
      'person@example.com',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'password123');
    final submit = find.widgetWithText(FilledButton, 'เข้าสู่ระบบ');
    await tester.tap(submit);
    await tester.pump();
    expect(tester.widget<FilledButton>(submit).onPressed, isNull);
    expect(repo.calls, 1);
    repo.pending!.complete();
    await tester.pumpAndSettle();
  });

  testWidgets(
    'small screen and large Thai text keep forms reachable without overflow',
    (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await mount(tester, FakeAuth(), textScale: 2);
      await tester.ensureVisible(find.text('ยังไม่มีบัญชี? สร้างบัญชี'));
      await tester.tap(find.text('ยังไม่มีบัญชี? สร้างบัญชี'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.widgetWithText(FilledButton, 'สร้างบัญชี'),
      );
      await tester.tap(find.widgetWithText(FilledButton, 'สร้างบัญชี'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('กรุณากรอกอีเมลให้ถูกต้อง'), findsOneWidget);
      await tester.ensureVisible(find.text('กลับไปเข้าสู่ระบบ'));
      await tester.tap(find.text('กลับไปเข้าสู่ระบบ'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('ลืมรหัสผ่าน?'));
      await tester.tap(find.text('ลืมรหัสผ่าน?'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('ส่งลิงก์รีเซ็ต'));
      expect(tester.takeException(), isNull);
    },
  );
}
