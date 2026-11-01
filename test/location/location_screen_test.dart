import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:muenee/app/theme/app_theme.dart';
import 'package:muenee/features/location/models/device_location.dart';
import 'package:muenee/features/location/presentation/screens/location_screen.dart';
import 'package:muenee/features/location/providers/location_provider.dart';
import 'package:muenee/features/location/services/location_service.dart';

void main() {
  testWidgets('waits for user intent before requesting permission', (
    tester,
  ) async {
    final service = _FakeLocationService();
    await tester.pumpWidget(_app(service));

    expect(service.permissionRequests, 0);
    expect(find.text('ยังไม่ได้ใช้ตำแหน่ง'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('locate-current-position')));
    await tester.pumpAndSettle();

    expect(service.permissionRequests, 1);
    expect(find.text('พร้อมหาร้านใกล้คุณ'), findsOneWidget);
    expect(find.textContaining('คลาดเคลื่อนประมาณ 13 ม.'), findsOneWidget);
    expect(
      find.textContaining('ไม่บันทึกตำแหน่งและไม่ติดตามเบื้องหลัง'),
      findsOneWidget,
    );
  });

  testWidgets('location UI remains usable on a small screen with large text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(2)),
        child: _app(_FakeLocationService()),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(
      find.byKey(const ValueKey('locate-current-position')),
      findsOneWidget,
    );
    await tester.ensureVisible(
      find.byKey(const ValueKey('locate-current-position')),
    );
    await tester.tap(find.byKey(const ValueKey('locate-current-position')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('explains how to recover when location services are disabled', (
    tester,
  ) async {
    final service = _FakeLocationService(serviceEnabled: false);
    await tester.pumpWidget(_app(service));

    await tester.tap(find.byKey(const ValueKey('locate-current-position')));
    await tester.pumpAndSettle();

    expect(find.text('บริการตำแหน่งปิดอยู่'), findsOneWidget);
    expect(find.text('เปิดการตั้งค่าตำแหน่ง'), findsOneWidget);
    expect(service.permissionRequests, 0);
  });
}

Widget _app(LocationService service) => ProviderScope(
  overrides: [locationServiceProvider.overrideWithValue(service)],
  child: MaterialApp(theme: AppTheme.light, home: const LocationScreen()),
);

class _FakeLocationService implements LocationService {
  _FakeLocationService({this.serviceEnabled = true});

  final bool serviceEnabled;
  int permissionRequests = 0;

  @override
  Future<DeviceLocationPermission> checkPermission() async =>
      DeviceLocationPermission.denied;

  @override
  Future<DeviceLocation> getCurrentLocation() async => DeviceLocation(
    latitude: 13.8199,
    longitude: 100.0443,
    accuracyMeters: 12.4,
    measuredAt: DateTime.utc(2026, 9, 6),
    precision: DeviceLocationPrecision.precise,
  );

  @override
  Future<bool> isServiceEnabled() async => serviceEnabled;

  @override
  Future<bool> openAppSettings() async => true;

  @override
  Future<bool> openLocationSettings() async => true;

  @override
  Future<DeviceLocationPermission> requestPermission() async {
    permissionRequests += 1;
    return DeviceLocationPermission.whileInUse;
  }
}
