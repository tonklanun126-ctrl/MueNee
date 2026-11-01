import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../app/theme/app_tokens.dart';
import '../../../../app/widgets/companion_components.dart';
import '../../../budget/providers/meal_budget_provider.dart';
import '../../../location/providers/location_provider.dart';
import '../../../restaurants/models/menu_preview.dart';
import '../../../restaurants/models/restaurant_detail_arguments.dart';
import '../../models/ranked_menu_recommendation.dart';
import '../../providers/recommendation_provider.dart';

class RecommendationResultsScreen extends ConsumerWidget {
  const RecommendationResultsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = ref.watch(locationProvider).location;
    final budget = ref.watch(mealBudgetProvider);
    if (location == null) {
      return _MissingInput(
        title: 'ต้องมีตำแหน่งก่อน',
        message: 'ใช้ตำแหน่งปัจจุบันเพื่อจัดลำดับร้านที่อยู่ใกล้คุณ',
        action: 'ไปตั้งค่าตำแหน่ง',
        onPressed: () => context.push('/location'),
      );
    }
    if (budget == null) {
      return _MissingInput(
        title: 'ต้องกำหนดงบก่อน',
        message: 'ระบุงบสูงสุดต่อมื้อเพื่อคัดเมนูที่ราคาไม่เกินงบ',
        action: 'ไปกำหนดงบ',
        onPressed: () => context.push('/budget'),
      );
    }

    final recommendations = ref.watch(recommendationProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('เมนูแนะนำ'),
        actions: [
          IconButton(
            tooltip: 'อัปเดตข้อมูลเมนู',
            onPressed: () => ref.invalidate(recommendationProvider),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: recommendations.when(
        loading: () => const _ResultSkeleton(),
        error: (error, stack) =>
            _LoadError(onRetry: () => ref.invalidate(recommendationProvider)),
        data: (items) => _Results(items: items, budgetBaht: budget.amountBaht),
      ),
    );
  }
}

class _Results extends ConsumerWidget {
  const _Results({required this.items, required this.budgetBaht});

  final List<RankedMenuRecommendation> items;
  final int budgetBaht;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (items.isEmpty) {
      return _EmptyResults(budgetBaht: budgetBaht);
    }
    return RefreshIndicator(
      onRefresh: () => ref.refresh(recommendationProvider.future),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '3 เมนูสำหรับมื้อนี้',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 4),
                    Text('งบไม่เกิน $budgetBaht บาท · คัดตามอาหารที่คุณกินได้'),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              ExcludeSemantics(
                child: Icon(
                  Icons.bolt_rounded,
                  size: 28,
                  color: AppTheme.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.large),
          for (var index = 0; index < items.length; index++) ...[
            _RecommendationCard(rank: index + 1, item: items[index]),
            if (index != items.length - 1) const SizedBox(height: 12),
          ],
          const SizedBox(height: 20),
          const Text(
            'ราคาและโภชนาการอาจเปลี่ยนแปลงหรือเป็นค่าประเมิน '
            'ควรตรวจสอบราคา ส่วนผสม และสารก่อภูมิแพ้กับร้านก่อนสั่ง',
            style: TextStyle(color: AppTheme.muted),
          ),
        ],
      ),
    );
  }
}

class _RecommendationCard extends StatelessWidget {
  const _RecommendationCard({required this.rank, required this.item});

  final int rank;
  final RankedMenuRecommendation item;

  @override
  Widget build(BuildContext context) {
    final menu = item.menu;
    final confidence = menu.price.effectiveConfidence(DateTime.now().toUtc());
    final confidenceText = switch (confidence) {
      PriceConfidence.verified => 'ราคายืนยันแล้ว',
      PriceConfidence.estimated => 'ราคาโดยประมาณ',
      PriceConfidence.unverified => 'ราคายังไม่ยืนยัน',
    };
    final confidenceColor = switch (confidence) {
      PriceConfidence.verified => AppTheme.success,
      PriceConfidence.estimated => AppTheme.warning,
      PriceConfidence.unverified => AppTheme.muted,
    };
    final panelColor = switch (rank) {
      1 => AppTheme.yellowSoft,
      2 => AppTheme.lilacSoft,
      _ => AppTheme.coralSoft,
    };
    return Semantics(
      label: 'อันดับ $rank ${menu.name} ร้าน ${item.restaurant.name}',
      child: Card(
        key: ValueKey('recommendation-${menu.id}'),
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 4,
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: panelColor,
                      borderRadius: AppRadii.button,
                      border: Border.all(color: AppTheme.ink, width: .8),
                    ),
                    child: Text(
                      rank == 1
                          ? 'อันดับ 1 · แนะนำตามเงื่อนไข'
                          : 'อันดับ $rank',
                      style: Theme.of(context).textTheme.labelMedium
                          ?.copyWith(color: AppTheme.ink),
                    ),
                  ),
                  Text(
                    '${confidence == PriceConfidence.verified ? '' : 'ประมาณ '}${menu.price.amount} บาท',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppTheme.coralActive,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (rank == 1 &&
                  MediaQuery.textScalerOf(context).scale(16) <= 24) ...[
                _FoodArtwork(featured: true, color: panelColor),
                const SizedBox(height: 10),
                _MenuHeading(
                  menuName: menu.name,
                  restaurantName: item.restaurant.name,
                ),
              ] else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (MediaQuery.textScalerOf(context).scale(16) <= 24) ...[
                      _FoodArtwork(featured: false, color: panelColor),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      child: _MenuHeading(
                        menuName: menu.name,
                        restaurantName: item.restaurant.name,
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _FactChip(
                    icon: Icons.near_me_outlined,
                    text: _distance(item.distanceMeters),
                    color: AppTheme.lilacSoft,
                  ),
                  _FactChip(
                    icon: Icons.local_fire_department_outlined,
                    text: 'ประมาณ ${menu.nutrition.calories} kcal',
                    color: AppTheme.orangeSoft,
                  ),
                  _FactChip(
                    icon: Icons.fitness_center,
                    text:
                        'โปรตีนประมาณ ${_grams(menu.nutrition.proteinGrams)} กรัม',
                    color: AppTheme.yellowSoft,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.info_outline, size: 18, color: confidenceColor),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      confidenceText,
                      style: TextStyle(
                        color: confidenceColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              if (item.isDisliked) ...[
                const SizedBox(height: 8),
                const Text(
                  'มีส่วนผสมที่คุณไม่ชอบ จึงถูกจัดไว้หลังตัวเลือกอื่น',
                  style: TextStyle(color: AppTheme.warning),
                ),
              ],
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  TextButton.icon(
                    key: ValueKey('explain-${menu.id}'),
                    onPressed: () => _showExplanation(context),
                    icon: const Icon(Icons.info_outline),
                    label: const Text('ทำไมแนะนำ'),
                  ),
                  OutlinedButton.icon(
                    key: ValueKey('restaurant-${menu.id}'),
                    onPressed: () => context.push(
                      '/restaurant/${Uri.encodeComponent(item.restaurant.id)}/menu/${Uri.encodeComponent(menu.id)}',
                      extra: RestaurantDetailArguments(
                        restaurant: item.restaurant,
                        menu: menu,
                        distanceMeters: item.distanceMeters,
                        rank: rank,
                      ),
                    ),
                    icon: const Icon(Icons.storefront_outlined),
                    label: const Text('ดูร้าน'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showExplanation(BuildContext context) {
    final price = item.menu.price;
    final date = price.verifiedAt;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                item.menu.name,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              const Text(
                'เมนูนี้ผ่านตัวกรองงบและการตั้งค่าอาหารของคุณ ระบบจัดอันดับจากระยะทาง ราคา และความน่าเชื่อถือของราคา โดยให้ความสำคัญกับร้านที่หลากหลาย',
              ),
              const SizedBox(height: 12),
              Text(_distance(item.distanceMeters)),
              if (item.isDisliked)
                const Text(
                  'มีส่วนผสมที่คุณไม่ชอบ จึงอยู่หลังตัวเลือกที่ไม่ติดความชอบนี้',
                ),
              const Divider(height: 32),
              Text(
                'แหล่งข้อมูลราคา: ${price.source?.trim().isNotEmpty == true ? price.source : 'ยังไม่มีแหล่งข้อมูล'}',
              ),
              Text(
                date == null
                    ? 'ยังไม่มีวันที่ตรวจสอบราคา'
                    : 'วันที่ข้อมูลราคา ${date.day}/${date.month}/${date.year + 543}',
              ),
              const SizedBox(height: 12),
              const Text(
                'สถานะราคายืนยันแล้วต้องมีหลักฐานภายใน 30 วัน โภชนาการเป็นค่าประมาณ การยืนยันราคาไม่ได้ยืนยันส่วนผสมหรือสารก่อภูมิแพ้ กรุณาตรวจสอบกับร้านก่อนสั่ง',
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('ปิด'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _distance(double meters) => meters < 1000
      ? 'ทางตรงประมาณ ${meters.round()} ม.'
      : 'ทางตรงประมาณ ${(meters / 1000).toStringAsFixed(1)} กม.';

  static String _grams(double value) => value == value.roundToDouble()
      ? value.round().toString()
      : value.toStringAsFixed(1);
}

class _MenuHeading extends StatelessWidget {
  const _MenuHeading({required this.menuName, required this.restaurantName});

  final String menuName;
  final String restaurantName;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        menuName,
        style: Theme.of(context).textTheme.titleLarge
            ?.copyWith(fontWeight: FontWeight.w700),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      Text(
        restaurantName,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.bodySmall,
      ),
    ],
  );
}

class _FoodArtwork extends StatelessWidget {
  const _FoodArtwork({required this.featured, required this.color});

  final bool featured;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: featured ? double.infinity : 76,
    height: featured ? 116 : 78,
    decoration: BoxDecoration(
      color: color,
      borderRadius: AppRadii.button,
      border: Border.all(color: AppTheme.ink, width: .8),
    ),
    child: Stack(
      alignment: Alignment.center,
      children: [
        Icon(
          featured ? Icons.ramen_dining_outlined : Icons.restaurant_outlined,
          size: featured ? 48 : 30,
          color: AppTheme.ink,
        ),
        Positioned(
          left: 10,
          bottom: 7,
          child: Text(
            'ภาพประกอบ',
            style: Theme.of(context).textTheme.labelSmall
                ?.copyWith(color: AppTheme.body, backgroundColor: color),
          ),
        ),
      ],
    ),
  );
}

class _FactChip extends StatelessWidget {
  const _FactChip({
    required this.icon,
    required this.text,
    required this.color,
  });

  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
    decoration: BoxDecoration(color: color, borderRadius: AppRadii.button),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16),
        const SizedBox(width: 6),
        Flexible(child: Text(text)),
      ],
    ),
  );
}

class _ResultSkeleton extends StatelessWidget {
  const _ResultSkeleton();

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'กำลังโหลดเมนูแนะนำ',
    liveRegion: true,
    child: ExcludeSemantics(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          for (var i = 0; i < 3; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 64,
                        decoration: BoxDecoration(
                          color: AppTheme.orangeSoft,
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        height: 20,
                        width: 180,
                        color: AppTheme.hairline,
                      ),
                      const SizedBox(height: 12),
                      Container(
                        height: 14,
                        width: 120,
                        color: AppTheme.hairline,
                      ),
                      const SizedBox(height: 24),
                      Container(
                        height: 14,
                        width: 220,
                        color: AppTheme.hairline,
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    ),
  );
}

class _EmptyResults extends StatelessWidget {
  const _EmptyResults({required this.budgetBaht});

  final int budgetBaht;

  @override
  Widget build(BuildContext context) => CompanionStateCard(
    icon: Icons.no_meals_outlined,
    title: 'ยังไม่พบเมนูที่ตรงครบทุกเงื่อนไข',
    message:
        'ระบบจะไม่ลดข้อจำกัดหรือการกรองอาหารแพ้ให้อัตโนมัติ งบปัจจุบันไม่เกิน $budgetBaht บาท',
    action: Column(
      children: [
        FilledButton(
          onPressed: () => context.push('/budget'),
          child: const Text('ปรับงบ'),
        ),
        const SizedBox(height: AppSpacing.small),
        OutlinedButton(
          onPressed: () => context.push('/food-settings?flow=meal'),
          child: const Text('ตรวจการตั้งค่าอาหาร'),
        ),
      ],
    ),
  );
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => CompanionStateCard(
    icon: Icons.cloud_off_outlined,
    title: 'โหลดเมนูไม่สำเร็จ ข้อมูลเดิมไม่ได้ถูกแก้ไข',
    message: 'ตรวจการเชื่อมต่อแล้วลองอีกครั้ง',
    action: FilledButton(onPressed: onRetry, child: const Text('ลองอีกครั้ง')),
  );
}

class _MissingInput extends StatelessWidget {
  const _MissingInput({
    required this.title,
    required this.message,
    required this.action,
    required this.onPressed,
  });

  final String title;
  final String message;
  final String action;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('เมนูแนะนำ')),
    body: CompanionStateCard(
      icon: Icons.route_outlined,
      title: title,
      message: message,
      action: FilledButton(onPressed: onPressed, child: Text(action)),
    ),
  );
}
