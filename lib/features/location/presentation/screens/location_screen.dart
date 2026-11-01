import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/device_location.dart';
import '../../providers/location_provider.dart';

class LocationScreen extends ConsumerWidget {
  const LocationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(locationProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('ตำแหน่งของคุณ')),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const _LocationIntro(),
                  const SizedBox(height: 20),
                  _LocationStatusCard(state: state),
                  const SizedBox(height: 16),
                  _LocationAction(state: state),
                  const SizedBox(height: 20),
                  const _PrivacyNote(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LocationIntro extends StatelessWidget {
  const _LocationIntro();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.primaryContainer,
      borderRadius: BorderRadius.circular(24),
    ),
    child: Column(
      children: [
        Icon(
          Icons.near_me_outlined,
          size: 44,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(height: 12),
        Text(
          'เริ่มหาร้านใกล้คุณ',
          style: Theme.of(context).textTheme.headlineSmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        const Text(
          'MueNee ใช้ตำแหน่งขณะเปิดแอป เพื่อเตรียมหาเมนูในระยะใกล้เคียง',
          textAlign: TextAlign.center,
        ),
      ],
    ),
  );
}

class _LocationStatusCard extends StatelessWidget {
  const _LocationStatusCard({required this.state});

  final LocationState state;

  @override
  Widget build(BuildContext context) {
    final content = _content(state);
    return Semantics(
      liveRegion: state.status != LocationStatus.idle,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(content.icon, color: content.color(context), size: 28),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      content.title,
                      style: Theme.of(context).textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    Text(content.message),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static _StatusContent _content(LocationState state) => switch (state.status) {
    LocationStatus.idle => const _StatusContent(
      Icons.location_searching,
      'ยังไม่ได้ใช้ตำแหน่ง',
      'ระบบจะขอสิทธิ์เมื่อคุณกดปุ่มด้านล่างเท่านั้น',
      _StatusTone.neutral,
    ),
    LocationStatus.loading => const _StatusContent(
      Icons.location_searching,
      'กำลังค้นหาตำแหน่ง…',
      'อาจใช้เวลาสักครู่ โดยเฉพาะเมื่ออยู่ภายในอาคาร',
      _StatusTone.neutral,
    ),
    LocationStatus.ready => _readyContent(state.location!),
    LocationStatus.serviceDisabled => const _StatusContent(
      Icons.location_disabled_outlined,
      'บริการตำแหน่งปิดอยู่',
      'เปิดตำแหน่งของเครื่อง แล้วกลับมาตรวจสอบอีกครั้ง',
      _StatusTone.warning,
    ),
    LocationStatus.permissionDenied => const _StatusContent(
      Icons.gps_off_outlined,
      'ยังไม่ได้อนุญาตตำแหน่ง',
      'คุณลองขอสิทธิ์อีกครั้งได้ MueNee ใช้เฉพาะตอนที่แอปเปิดอยู่',
      _StatusTone.warning,
    ),
    LocationStatus.permissionDeniedForever => const _StatusContent(
      Icons.app_settings_alt_outlined,
      'ต้องอนุญาตจากการตั้งค่าแอป',
      'เปิดการตั้งค่า เลือกสิทธิ์ตำแหน่ง แล้วกลับมาตรวจสอบอีกครั้ง',
      _StatusTone.warning,
    ),
    LocationStatus.timedOut => const _StatusContent(
      Icons.timer_off_outlined,
      'ค้นหาตำแหน่งไม่ทันเวลา',
      'ลองย้ายไปบริเวณที่รับสัญญาณได้ดีขึ้น แล้วลองอีกครั้ง',
      _StatusTone.warning,
    ),
    LocationStatus.unavailable => const _StatusContent(
      Icons.error_outline,
      'ใช้ตำแหน่งไม่ได้ในขณะนี้',
      'ตรวจสอบบริการตำแหน่ง แล้วลองอีกครั้ง',
      _StatusTone.error,
    ),
  };

  static _StatusContent _readyContent(DeviceLocation location) {
    final accuracy = location.accuracyMeters.isFinite
        ? location.accuracyMeters.ceil()
        : null;
    final precision = switch (location.precision) {
      DeviceLocationPrecision.precise => 'ตำแหน่งแบบแม่นยำ',
      DeviceLocationPrecision.reduced => 'ตำแหน่งโดยประมาณ',
      DeviceLocationPrecision.unknown => 'ตำแหน่งพร้อมใช้งาน',
    };
    return _StatusContent(
      Icons.check_circle_outline,
      'พร้อมหาร้านใกล้คุณ',
      accuracy == null
          ? precision
          : '$precision · คลาดเคลื่อนประมาณ $accuracy ม.',
      _StatusTone.success,
    );
  }
}

class _LocationAction extends ConsumerWidget {
  const _LocationAction({required this.state});

  final LocationState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(locationProvider.notifier);
    if (state.status == LocationStatus.ready) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FilledButton.icon(
            onPressed: () => context.push('/budget'),
            icon: const Icon(Icons.arrow_forward),
            label: const Text('ต่อไป: กำหนดงบ'),
          ),
          TextButton(
            onPressed: controller.locate,
            child: const Text('อัปเดตตำแหน่ง'),
          ),
        ],
      );
    }
    if (state.status == LocationStatus.loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.status == LocationStatus.serviceDisabled) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FilledButton.icon(
            onPressed: () =>
                _openSettings(context, controller.openLocationSettings),
            icon: const Icon(Icons.settings_outlined),
            label: const Text('เปิดการตั้งค่าตำแหน่ง'),
          ),
          TextButton(
            onPressed: controller.locate,
            child: const Text('เปิดแล้ว ตรวจสอบอีกครั้ง'),
          ),
        ],
      );
    }
    if (state.status == LocationStatus.permissionDeniedForever) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FilledButton.icon(
            onPressed: () => _openSettings(context, controller.openAppSettings),
            icon: const Icon(Icons.app_settings_alt_outlined),
            label: const Text('เปิดการตั้งค่าแอป'),
          ),
          TextButton(
            onPressed: controller.locate,
            child: const Text('อนุญาตแล้ว ตรวจสอบอีกครั้ง'),
          ),
        ],
      );
    }
    return FilledButton.icon(
      key: const ValueKey('locate-current-position'),
      onPressed: controller.locate,
      icon: Icon(
        state.status == LocationStatus.ready
            ? Icons.refresh
            : Icons.my_location,
      ),
      label: Text(
        state.status == LocationStatus.ready
            ? 'อัปเดตตำแหน่ง'
            : state.status == LocationStatus.idle
            ? 'ใช้ตำแหน่งปัจจุบัน'
            : 'ลองอีกครั้ง',
      ),
    );
  }

  Future<void> _openSettings(
    BuildContext context,
    Future<bool> Function() open,
  ) async {
    final opened = await open();
    if (!context.mounted || opened) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('เปิดการตั้งค่าไม่ได้ กรุณาเปิดจากการตั้งค่าของเครื่อง'),
      ),
    );
  }
}

class _PrivacyNote extends StatelessWidget {
  const _PrivacyNote();

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(
        Icons.lock_outline,
        size: 20,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      const SizedBox(width: 10),
      const Expanded(
        child: Text(
          'ใช้ตำแหน่งชั่วคราวขณะเปิดแอป ไม่บันทึกตำแหน่งและไม่ติดตามเบื้องหลัง',
        ),
      ),
    ],
  );
}

enum _StatusTone { neutral, success, warning, error }

class _StatusContent {
  const _StatusContent(this.icon, this.title, this.message, this.tone);

  final IconData icon;
  final String title;
  final String message;
  final _StatusTone tone;

  Color color(BuildContext context) => switch (tone) {
    _StatusTone.neutral => Theme.of(context).colorScheme.primary,
    _StatusTone.success => const Color(0xFF2E7D32),
    _StatusTone.warning => const Color(0xFFB45309),
    _StatusTone.error => Theme.of(context).colorScheme.error,
  };
}
