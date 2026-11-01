import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../profile/models/food_preferences.dart';
import '../../../profile/providers/food_preferences_provider.dart';
import '../../../restaurants/models/sample_menus.dart';
import '../../../restaurants/presentation/widgets/price_status.dart';
import '../../services/food_preference_filter.dart';

class FoodPreviewScreen extends ConsumerWidget {
  const FoodPreviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    appBar: AppBar(title: const Text('ตัวอย่างผลการตั้งค่า')),
    body: ref
        .watch(foodPreferencesProvider)
        .when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('โหลดการตั้งค่าไม่สำเร็จ จึงยังไม่แสดงเมนู'),
                  TextButton(
                    onPressed: () => ref.invalidate(foodPreferencesProvider),
                    child: const Text('ลองอีกครั้ง'),
                  ),
                ],
              ),
            ),
          ),
          data: (preferences) => _PreviewList(preferences: preferences),
        ),
  );
}

class _PreviewList extends StatelessWidget {
  const _PreviewList({required this.preferences});
  final FoodPreferences preferences;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final samples = sampleMenus(now);
    const filter = FoodPreferenceFilter();
    final menus = filter.apply(samples, preferences);
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text(
              'ลองดูมื้อที่ตรงกับคุณ',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'ข้อมูลตัวอย่างเท่านั้น\n'
                  'ชื่อเมนู ราคา วันที่ และข้อมูลฮาลาลเป็นข้อมูลจำลอง '
                  'ยังไม่ใช่คำแนะนำจากร้านจริง',
                ),
              ),
            ),
            Wrap(
              spacing: 8,
              children: [
                for (final rule in preferences.restrictions)
                  Chip(label: Text(rule.label)),
                for (final allergy in preferences.allergies)
                  Chip(label: Text('แพ้: ${allergy.label}')),
              ],
            ),
            TextButton.icon(
              onPressed: () => context.push('/food-settings'),
              icon: const Icon(Icons.tune),
              label: const Text('แก้ไขการตั้งค่าอาหาร'),
            ),
            Text('แสดง ${menus.length} จาก ${samples.length} เมนูตัวอย่าง'),
            if (preferences.dislikes.isNotEmpty)
              Text(
                preferences.hideDisliked
                    ? 'ซ่อนอาหารที่ไม่ชอบ รวมเมนูที่ข้อมูลส่วนผสมไม่ครบ'
                    : 'เมนูที่มีอาหารที่ไม่ชอบจะแสดงท้ายรายการ',
              ),
            if (preferences.allergies.isNotEmpty)
              const Text(
                'ซ่อนเมนูที่มีสารก่อภูมิแพ้ที่เลือกหรือข้อมูลไม่ครบ '
                'โปรดยืนยันส่วนผสมและการปนเปื้อนกับร้านก่อนสั่ง',
              ),
            const SizedBox(height: 16),
            if (menus.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'ยังไม่มีเมนูตัวอย่างที่ยืนยันได้ว่าตรงกับเงื่อนไขของคุณ '
                    'ระบบจะคงข้อจำกัดอาหารและอาหารที่แพ้ไว้',
                  ),
                ),
              ),
            for (final menu in menus)
              Card(
                key: ValueKey(menu.id),
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        menu.name,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      if (filter.isDisliked(menu, preferences))
                        const Text('มีอาหารที่คุณไม่ชอบ • แสดงท้ายรายการ'),
                      const SizedBox(height: 8),
                      PriceStatus(price: menu.price, now: now),
                      if (!menu.ingredientsKnown || !menu.allergensKnown)
                        const Text('ข้อมูลส่วนผสม / สารก่อภูมิแพ้ยังไม่ครบ'),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
