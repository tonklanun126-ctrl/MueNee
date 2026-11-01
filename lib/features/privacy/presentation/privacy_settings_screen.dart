import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/motion/app_feedback.dart';
import '../../../app/motion/app_motion.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/monitoring/telemetry_providers.dart';
import '../../../core/monitoring/telemetry_settings.dart';

class PrivacySettingsScreen extends ConsumerStatefulWidget {
  const PrivacySettingsScreen({super.key});

  @override
  ConsumerState<PrivacySettingsScreen> createState() =>
      _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends ConsumerState<PrivacySettingsScreen> {
  TelemetrySettings? _draft;
  TelemetrySettings? _source;
  bool _saving = false;
  String? _message;
  bool _messageIsError = false;

  bool get _dirty => _draft != null && _draft != _source;

  Future<void> _save() async {
    final draft = _draft;
    if (draft == null || !_dirty || _saving) return;
    setState(() {
      _saving = true;
      _message = null;
    });
    try {
      await ref.read(telemetrySettingsProvider.notifier).save(draft);
      if (!mounted) return;
      unawaited(AppFeedback.confirmed());
      setState(() {
        _source = draft;
        _message = 'บันทึกการตั้งค่าความเป็นส่วนตัวแล้ว';
        _messageIsError = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _message = 'บันทึกไม่สำเร็จ ค่าก่อนหน้ายังถูกใช้อยู่ กรุณาลองอีกครั้ง';
        _messageIsError = true;
      });
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(telemetrySettingsProvider);
    final value = settings.value;
    if (value != null && (_source == null || (!_dirty && _source != value))) {
      _source = value;
      _draft = value;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('ข้อมูลและความเป็นส่วนตัว')),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: AnimatedSwitcher(
                duration: AppMotion.contentFor(context),
                child: _content(settings),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _content(AsyncValue<TelemetrySettings> settings) {
    if (settings.isLoading && settings.value == null) {
      return const Center(
        key: ValueKey('privacy-loading'),
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(),
        ),
      );
    }
    if (settings.hasError && settings.value == null) {
      return Card(
        key: const ValueKey('privacy-load-error'),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const Icon(Icons.sync_problem, size: 44, color: AppTheme.error),
              const SizedBox(height: 12),
              const Text(
                'เปิดการตั้งค่าความเป็นส่วนตัวไม่สำเร็จ',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: () => ref.invalidate(telemetrySettingsProvider),
                icon: const Icon(Icons.refresh),
                label: const Text('ลองอีกครั้ง'),
              ),
            ],
          ),
        ),
      );
    }

    final draft = _draft ?? const TelemetrySettings();
    return Column(
      key: const ValueKey('privacy-content'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const Icon(
                  Icons.privacy_tip_outlined,
                  size: 48,
                  color: AppTheme.coralActive,
                ),
                const SizedBox(height: 12),
                Text(
                  'คุณเป็นคนเลือกว่าจะช่วยส่งข้อมูลหรือไม่',
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'ทั้งสองรายการปิดไว้ตั้งแต่เริ่ม และเปลี่ยนได้ทุกเมื่อบนอุปกรณ์นี้',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Column(
            children: [
              SwitchListTile(
                key: const ValueKey('analytics-consent'),
                value: draft.analyticsEnabled,
                onChanged: _saving
                    ? null
                    : (enabled) => setState(() {
                        _draft = draft.copyWith(analyticsEnabled: enabled);
                        _message = null;
                      }),
                secondary: const Icon(Icons.query_stats_outlined),
                title: const Text('ข้อมูลการใช้งานแอป'),
                subtitle: const Text(
                  'ช่วยดูว่าหน้าและขั้นตอนหลักใช้งานสำเร็จหรือไม่ โดย MueNee ส่งเฉพาะชื่อหน้าหรือเหตุการณ์ที่กำหนดไว้',
                ),
              ),
              const Divider(height: 1),
              SwitchListTile(
                key: const ValueKey('crash-consent'),
                value: draft.crashReportsEnabled,
                onChanged: _saving
                    ? null
                    : (enabled) => setState(() {
                        _draft = draft.copyWith(crashReportsEnabled: enabled);
                        _message = null;
                      }),
                secondary: const Icon(Icons.bug_report_outlined),
                title: const Text('รายงานข้อขัดข้อง'),
                subtitle: const Text(
                  'ส่ง stack trace และข้อมูลทางเทคนิคของแอปหรืออุปกรณ์ เพื่อช่วยแก้ปัญหา',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'ข้อมูลที่ MueNee ไม่ใส่ในเหตุการณ์ Analytics',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                SizedBox(height: 10),
                Text('• พิกัดหรือตำแหน่งที่อยู่'),
                Text('• งบประมาณและข้อจำกัดอาหาร'),
                Text('• ค่าโภชนาการ ชื่ออาหาร หรือรูปอาหาร'),
                Text('• อีเมล รหัสผู้ใช้ หรือข้อความที่คุณกรอก'),
              ],
            ),
          ),
        ),
        if (_message != null) ...[
          const SizedBox(height: 16),
          Semantics(
            liveRegion: true,
            child: Text(
              _message!,
              key: const ValueKey('privacy-message'),
              style: TextStyle(
                color: _messageIsError ? AppTheme.error : AppTheme.success,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
        const SizedBox(height: 20),
        FilledButton.icon(
          key: const ValueKey('save-privacy-settings'),
          onPressed: _dirty && !_saving ? _save : null,
          icon: _saving
              ? const SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.check_circle_outline),
          label: Text(_saving ? 'กำลังบันทึก…' : 'บันทึกการตั้งค่า'),
        ),
      ],
    );
  }
}
