import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';
import '../../models/menu_preview.dart';

class PriceStatus extends StatelessWidget {
  const PriceStatus({super.key, required this.price, required this.now});
  final MenuPrice price;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final confidence = price.effectiveConfidence(now);
    final (label, icon, color) = switch (confidence) {
      PriceConfidence.verified => (
        'ยืนยันแล้ว',
        Icons.verified_outlined,
        AppTheme.success,
      ),
      PriceConfidence.estimated => (
        'ราคาโดยประมาณ',
        Icons.calculate_outlined,
        AppTheme.warning,
      ),
      PriceConfidence.unverified => (
        'รอตรวจสอบ',
        Icons.schedule,
        AppTheme.muted,
      ),
    };
    final checked = price.verifiedAt;
    final date = checked == null
        ? 'ยังไม่มีวันที่ตรวจสอบ'
        : checked.isAfter(now)
        ? 'วันที่ตรวจสอบไม่ถูกต้อง'
        : 'ตรวจสอบล่าสุด ${_date(checked)}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${confidence == PriceConfidence.verified ? '' : 'ประมาณ '}${price.amount} บาท',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        TextButton.icon(
          style: TextButton.styleFrom(foregroundColor: color),
          icon: Icon(icon),
          label: Text(label),
          onPressed: () => showModalBottomSheet<void>(
            context: context,
            showDragHandle: true,
            isScrollControlled: true,
            builder: (context) => SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ข้อมูลราคา: $label',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'แหล่งข้อมูล: ${price.source?.trim().isNotEmpty == true ? price.source! : 'ยังไม่มีแหล่งข้อมูล'}',
                    ),
                    Text(date),
                    const SizedBox(height: 12),
                    const Text(
                      'ยืนยันแล้ว: มีแหล่งข้อมูลและตรวจสอบภายใน 30 วัน\n'
                      'ราคาโดยประมาณ: เป็นค่าประเมิน ยังไม่ได้ยืนยันราคาขาย\n'
                      'รอตรวจสอบ: ยังไม่มีหลักฐานครบ หรือข้อมูลยืนยันเกิน 30 วัน',
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'ข้อมูลหน้านี้เป็นตัวอย่าง ไม่ใช่ราคาขายของร้านจริง '
                      'ราคาจริงอาจเปลี่ยนแปลง กรุณาตรวจสอบกับร้านก่อนสั่ง',
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('ปิด'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        Text(date, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }

  String _date(DateTime value) =>
      '${value.day}/${value.month}/${value.year + 543}';
}
