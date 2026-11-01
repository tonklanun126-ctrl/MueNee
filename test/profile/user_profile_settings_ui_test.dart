import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:muenee/app/app.dart';
import 'package:muenee/features/profile/models/user_profile.dart';
import 'package:muenee/features/profile/providers/user_profile_provider.dart';
import 'package:muenee/features/profile/repositories/user_profile_repository.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  Future<void> openSettings(WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: MueNeeApp()));
    await tester.ensureVisible(find.text('ตั้งค่าโปรไฟล์'));
    await tester.tap(find.text('ตั้งค่าโปรไฟล์'));
    await tester.pumpAndSettle();
  }

  Future<void> fillCompleteProfile(WidgetTester tester) async {
    await tester.enterText(find.byKey(const ValueKey('profile-age')), '21');
    await tester.enterText(
      find.byKey(const ValueKey('profile-height')),
      '172.5',
    );
    await tester.enterText(find.byKey(const ValueKey('profile-weight')), '68');
    await tester.tap(find.byKey(const ValueKey('profile-activity')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('เคลื่อนไหวปานกลาง').last);
    await tester.pump();
  }

  testWidgets('saves and reopens the profile settings', (tester) async {
    await openSettings(tester);
    await fillCompleteProfile(tester);
    await tester.tap(find.text('บันทึกโปรไฟล์'));
    await tester.pumpAndSettle();

    expect(find.text('บันทึกโปรไฟล์แล้ว'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('ตั้งค่าโปรไฟล์'));
    await tester.tap(find.text('ตั้งค่าโปรไฟล์'));
    await tester.pumpAndSettle();

    expect(
      tester
          .widget<TextFormField>(find.byKey(const ValueKey('profile-age')))
          .controller!
          .text,
      '21',
    );
    expect(
      tester
          .widget<TextFormField>(find.byKey(const ValueKey('profile-height')))
          .controller!
          .text,
      '172.5',
    );
    expect(
      tester
          .widget<TextFormField>(find.byKey(const ValueKey('profile-weight')))
          .controller!
          .text,
      '68',
    );
  });

  testWidgets('invalid values prevent saving', (tester) async {
    await openSettings(tester);
    await tester.enterText(find.byKey(const ValueKey('profile-age')), '0');
    await tester.enterText(find.byKey(const ValueKey('profile-height')), '170');
    await tester.enterText(find.byKey(const ValueKey('profile-weight')), '60');
    await tester.tap(find.byKey(const ValueKey('profile-activity')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('นั่งเป็นส่วนใหญ่').last);
    await tester.pump();
    await tester.tap(find.text('บันทึกโปรไฟล์'));
    await tester.pumpAndSettle();

    expect(find.textContaining('อายุต้องอยู่ระหว่าง'), findsOneWidget);
    expect(find.text('บันทึกโปรไฟล์แล้ว'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('back confirms unsaved draft and discard keeps saved profile', (
    tester,
  ) async {
    final saved = UserProfile(
      age: 22,
      heightCm: 165,
      weightKg: 55,
      activityLevel: ActivityLevel.lightlyActive,
    );
    final repository = _MemoryRepository(saved);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          userProfileRepositoryProvider.overrideWithValue(repository),
        ],
        child: const MueNeeApp(),
      ),
    );
    await tester.ensureVisible(find.text('ตั้งค่าโปรไฟล์'));
    await tester.tap(find.text('ตั้งค่าโปรไฟล์'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('profile-age')), '23');
    await tester.pump();
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('ยังไม่ได้บันทึกการเปลี่ยนแปลง'), findsOneWidget);
    await tester.tap(find.text('ทิ้งการเปลี่ยนแปลง'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ตั้งค่าโปรไฟล์'));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<TextFormField>(find.byKey(const ValueKey('profile-age')))
          .controller!
          .text,
      '22',
    );
  });

  testWidgets('small screen and large text remain scrollable', (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 1.5;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await openSettings(tester);
    final profileList = find.byType(ListView).last;
    for (
      var attempt = 0;
      attempt < 6 &&
          find.byKey(const ValueKey('profile-weight')).evaluate().isEmpty;
      attempt++
    ) {
      await tester.drag(profileList, const Offset(0, -250));
      await tester.pump();
    }
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('บันทึกโปรไฟล์'), findsOneWidget);
  });
}

class _MemoryRepository implements UserProfileRepository {
  _MemoryRepository(this.saved);

  UserProfile saved;

  @override
  Future<UserProfile> load() async => saved;

  @override
  Future<void> save(UserProfile profile) async => saved = profile;
}
