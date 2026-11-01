import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../app/theme/app_tokens.dart';
import '../../../../app/widgets/brand_mark.dart';
import '../../../../app/widgets/companion_components.dart';
import '../../../../app/widgets/main_navigation_bar.dart';
import '../../../../core/monitoring/telemetry_providers.dart';
import '../../../../core/monitoring/telemetry_service.dart';
import '../../../budget/providers/meal_budget_provider.dart';
import '../../../location/providers/location_provider.dart';

class RecommendationPlaceholderScreen extends ConsumerWidget {
  const RecommendationPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final budget = ref.watch(mealBudgetProvider);
    final located = ref.watch(locationProvider).location != null;
    final next = !located
        ? '/location'
        : budget == null
        ? '/budget'
        : '/food-settings?flow=meal';
    return Scaffold(
      appBar: AppBar(
        title: const BrandWordmark(),
        actions: [
          IconButton(
            tooltip: 'บัญชี / เข้าสู่ระบบ',
            onPressed: () => context.push('/account'),
            icon: const Icon(Icons.account_circle_outlined),
          ),
        ],
      ),
      bottomNavigationBar: const MainNavigationBar(selectedIndex: 0),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 36),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'มื้อนี้กินอะไรดี?',
                            style: Theme.of(context).textTheme.displaySmall,
                          ),
                          const SizedBox(height: 4),
                          const Text('อิ่มได้ ในงบที่เลือก'),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (MediaQuery.textScalerOf(context).scale(16) <= 24)
                      const _CampusFoodDoodle(),
                  ],
                ),
                const SizedBox(height: AppSpacing.normal),
                _LocationShortcut(located: located),
                const SizedBox(height: AppSpacing.normal),
                _BudgetPanel(budgetBaht: budget?.amountBaht),
                const SizedBox(height: AppSpacing.normal),
                _PreferencesShortcut(
                  onTap: () => context.push('/food-settings'),
                ),
                const SizedBox(height: AppSpacing.normal),
                FilledButton.icon(
                  key: const ValueKey('find-menus'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(58),
                    backgroundColor: AppTheme.coralActive,
                  ),
                  onPressed: () {
                    unawaited(
                      ref
                          .read(telemetryServiceProvider)
                          .logEvent(MueNeeAnalyticsEvent.mealFlowStarted),
                    );
                    context.push(next);
                  },
                  icon: const Icon(Icons.arrow_forward_rounded),
                  label: const Text('หาเมนูให้หน่อย'),
                  iconAlignment: IconAlignment.end,
                ),
                const SizedBox(height: AppSpacing.small),
                Text(
                  !located
                      ? 'เริ่มจากตำแหน่ง แล้วเลือกงบกับอาหารที่กินได้'
                      : budget == null
                      ? 'เลือกงบของมื้อนี้ แล้วเราจะช่วยคัดเมนู'
                      : 'ตรวจอาหารที่กินได้ก่อนดูเมนูที่เหมาะกับคุณ',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: AppSpacing.large),
                const CompanionSectionHeader(
                  title: 'เลือกง่าย ได้ไม่เกิน 3 เมนู',
                  subtitle: 'ดูงบ ระยะทาง และข้อมูลอาหารก่อนตัดสินใจ',
                ),
                const SizedBox(height: AppSpacing.xLarge),
                const CompanionSectionHeader(title: 'ตั้งค่าของฉัน'),
                const SizedBox(height: AppSpacing.small),
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.person_outline),
                        title: const Text('ตั้งค่าโปรไฟล์'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => context.push('/profile-settings'),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.tune),
                        title: const Text('ตั้งค่าอาหารที่กิน'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => context.push('/food-settings'),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.privacy_tip_outlined),
                        title: const Text('ข้อมูลและความเป็นส่วนตัว'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => context.push('/privacy-settings'),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.receipt_long_outlined),
                        title: const Text('ดูตัวอย่างเมนูและสถานะราคา'),
                        subtitle: const Text('ข้อมูลตัวอย่าง ไม่ใช่ร้านจริง'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => context.push('/food-preview'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CampusFoodDoodle extends StatelessWidget {
  const _CampusFoodDoodle();

  @override
  Widget build(BuildContext context) => Semantics(
    image: true,
    label: 'ภาพประกอบอาหาร',
    child: SizedBox(
      width: 64,
      height: 64,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: AppTheme.yellow,
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.ink, width: 1.2),
            ),
            child: const Icon(
              Icons.ramen_dining_outlined,
              size: 34,
              color: AppTheme.coralActive,
            ),
          ),
          Positioned(
            top: 5,
            right: 3,
            child: Container(
              width: 11,
              height: 11,
              decoration: const BoxDecoration(
                color: AppTheme.lilac,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _LocationShortcut extends StatelessWidget {
  const _LocationShortcut({required this.located});

  final bool located;

  @override
  Widget build(BuildContext context) => Material(
    color: AppTheme.lilacSoft,
    borderRadius: AppRadii.button,
    child: InkWell(
      borderRadius: AppRadii.button,
      onTap: () => context.push('/location'),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            const Icon(Icons.location_on_outlined, color: AppTheme.ink),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                located ? 'ตำแหน่งพร้อมแล้ว' : 'ใช้ตำแหน่งปัจจุบัน',
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
            const Icon(Icons.edit_outlined, size: 18),
          ],
        ),
      ),
    ),
  );
}

class _PreferencesShortcut extends StatelessWidget {
  const _PreferencesShortcut({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: AppTheme.lilacSoft,
    borderRadius: AppRadii.card,
    child: InkWell(
      borderRadius: AppRadii.card,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            const Icon(Icons.restaurant_outlined, color: AppTheme.ink),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'อาหารที่กินได้',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const Text('ดูและแก้ไขข้อจำกัดอาหาร'),
                ],
              ),
            ),
            const Icon(Icons.edit_outlined, size: 18),
          ],
        ),
      ),
    ),
  );
}

class _BudgetPanel extends StatelessWidget {
  const _BudgetPanel({required this.budgetBaht});

  final int? budgetBaht;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: AppTheme.yellow,
      borderRadius: AppRadii.hero,
      border: Border.all(color: AppTheme.ink, width: 1.2),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'งบมื้อนี้',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            if (MediaQuery.textScalerOf(context).scale(16) > 26)
              IconButton(
                tooltip: 'กำหนดงบอื่น',
                onPressed: () => context.push('/budget'),
                icon: const Icon(Icons.edit_outlined),
              )
            else
              Tooltip(
                message: 'กำหนดงบอื่น',
                child: TextButton.icon(
                  onPressed: () => context.push('/budget'),
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('งบอื่น'),
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.xSmall),
        Text(
          budgetBaht == null ? 'ยังไม่ได้เลือกงบ' : '$budgetBaht บาท',
          style: Theme.of(context).textTheme.headlineMedium
              ?.copyWith(fontSize: 36, color: AppTheme.ink),
        ),
        const SizedBox(height: AppSpacing.xSmall),
        Text(
          budgetBaht == null
              ? 'งบสูงสุดต่อมื้อ'
              : 'ยืนยันแล้ว · ไม่เกิน ฿$budgetBaht',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: AppSpacing.normal),
        Wrap(
          spacing: AppSpacing.small,
          runSpacing: AppSpacing.small,
          children: [
            for (final amount in [40, 60, 80])
              CompanionBudgetChip(
                amount: amount,
                selected: budgetBaht == amount,
                onTap: () => context.push('/budget?amount=$amount'),
              ),
          ],
        ),
      ],
    ),
  );
}
