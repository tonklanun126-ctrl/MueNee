import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../auth/auth_repository.dart';
import '../../../tracking/providers/meal_selection_provider.dart';
import '../../models/menu_preview.dart';
import '../../models/restaurant.dart';
import '../../models/restaurant_detail_arguments.dart';

class RestaurantDetailScreen extends ConsumerWidget {
  const RestaurantDetailScreen({required this.details, super.key});

  final RestaurantDetailArguments details;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final restaurant = details.restaurant;
    final menu = details.menu;
    final confidence = menu.price.effectiveConfidence(DateTime.now().toUtc());
    final account = ref.watch(accountProvider);
    final selection = ref.watch(mealSelectionProvider);
    final saved = selection.saved(menu.id);

    return Scaffold(
      appBar: AppBar(title: const Text('รายละเอียดร้าน')),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(16),
        child: _MealSelectionAction(
          account: account,
          state: selection,
          menuId: menu.id,
          onSignIn: () => context.push('/account'),
          onRetryAccount: () => ref.invalidate(accountProvider),
          onSelect: (userId) => _confirmMeal(context, ref, userId),
        ),
      ),
      body: ListView(
        key: const PageStorageKey('restaurant-detail-scroll'),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 112),
        children: [
          _CatalogImage(imageUrl: menu.imageUrl ?? restaurant.imageUrl),
          const SizedBox(height: 20),
          Text(
            'อันดับ ${details.rank} ตามเงื่อนไขมื้อนี้',
            style: const TextStyle(
              color: AppTheme.coralActive,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            menu.name,
            style: Theme.of(context).textTheme.headlineMedium
                ?.copyWith(fontWeight: FontWeight.w700, height: 1.25),
          ),
          const SizedBox(height: 6),
          Text(restaurant.name, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 16),
          _PriceCard(
            amount: menu.price.amount,
            confidence: confidence,
            onEvidencePressed: () => _showPriceEvidence(context),
          ),
          const SizedBox(height: 16),
          _SectionCard(
            title: 'ร้านและระยะทาง',
            children: [
              _DetailRow(
                icon: Icons.near_me_outlined,
                title: _distance(details.distanceMeters),
                subtitle: 'เป็นระยะทางเส้นตรง ไม่ใช่เวลาเดินทาง',
              ),
              _DetailRow(
                icon: Icons.location_on_outlined,
                title: restaurant.address,
                subtitle: 'ที่อยู่สำหรับตรวจสอบร้านก่อนเดินทาง',
              ),
              _DetailRow(
                icon: Icons.verified_outlined,
                title: _verificationLabel(restaurant.verificationStatus),
                subtitle: 'อัปเดตข้อมูลร้าน ${_date(restaurant.updatedAt)}',
              ),
            ],
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            key: const ValueKey('open-restaurant-map'),
            onPressed: () => context.push(
              '/restaurant/${Uri.encodeComponent(restaurant.id)}/menu/${Uri.encodeComponent(menu.id)}/map',
              extra: details,
            ),
            icon: const Icon(Icons.map_outlined),
            label: const Text('ดูร้านบนแผนที่'),
          ),
          const SizedBox(height: 16),
          _SectionCard(
            title: 'โภชนาการโดยประมาณ',
            supportingText:
                'เป็นค่าประเมินต่อหนึ่งรายการ ไม่ใช่ผลตรวจทางห้องปฏิบัติการ',
            children: [
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _NutritionValue(
                    label: 'พลังงาน',
                    value: '${menu.nutrition.calories} kcal',
                  ),
                  _NutritionValue(
                    label: 'โปรตีน',
                    value: '${_grams(menu.nutrition.proteinGrams)} กรัม',
                  ),
                  _NutritionValue(
                    label: 'คาร์โบไฮเดรต',
                    value: '${_grams(menu.nutrition.carbsGrams)} กรัม',
                  ),
                  _NutritionValue(
                    label: 'ไขมัน',
                    value: '${_grams(menu.nutrition.fatGrams)} กรัม',
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          _DietaryEvidenceCard(details: details),
          const SizedBox(height: 16),
          Card(
            color: saved ? const Color(0xFFE7F3EB) : AppTheme.yellowSoft,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        saved ? Icons.check_circle_outline : Icons.info_outline,
                        color: saved ? AppTheme.success : AppTheme.warning,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          saved
                              ? 'บันทึกเมนูนี้เป็นมื้อของคุณแล้ว ดูรายการและสรุปโภชนาการโดยประมาณได้ในบันทึกวันนี้'
                              : 'การเลือกเมนูนี้จะบันทึกเป็นมื้อของคุณ ไม่ใช่การสั่งอาหารกับร้าน กรุณาตรวจสอบราคา ส่วนผสม และสารก่อภูมิแพ้ก่อนสั่ง',
                        ),
                      ),
                    ],
                  ),
                  if (saved) ...[
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      key: const ValueKey('open-daily-tracking'),
                      onPressed: () => context.push('/tracking'),
                      icon: const Icon(Icons.today_outlined),
                      label: const Text('ดูบันทึกวันนี้'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmMeal(
    BuildContext context,
    WidgetRef ref,
    String userId,
  ) async {
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'เลือก ${details.menu.name} เป็นมื้อนี้?',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              Text('ร้าน ${details.restaurant.name}'),
              Text('โภชนาการประมาณ ${details.menu.nutrition.calories} kcal'),
              const SizedBox(height: 12),
              const Text(
                'การยืนยันจะบันทึกมื้อนี้ในบัญชีของคุณ แต่ไม่ได้สั่งหรือชำระค่าอาหารกับร้าน',
              ),
              const SizedBox(height: 20),
              FilledButton(
                key: const ValueKey('confirm-meal-selection'),
                onPressed: () => Navigator.pop(context, true),
                child: const Text('ยืนยันและบันทึกมื้อ'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('ยังไม่เลือก'),
              ),
            ],
          ),
        ),
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final success = await ref
        .read(mealSelectionProvider.notifier)
        .select(userId: userId, details: details);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'บันทึก ${details.menu.name} เป็นมื้อนี้แล้ว'
              : 'บันทึกมื้อไม่สำเร็จ กรุณาลองอีกครั้ง',
        ),
      ),
    );
  }

  void _showPriceEvidence(BuildContext context) {
    final price = details.menu.price;
    final confidence = price.effectiveConfidence(DateTime.now().toUtc());
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'ข้อมูลราคา ${details.menu.name}',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              Text('ราคา ${price.amount} บาท'),
              Text(_priceConfidenceLabel(confidence)),
              Text(
                'แหล่งข้อมูล: ${price.source?.trim().isNotEmpty == true ? price.source : 'ยังไม่มีแหล่งข้อมูล'}',
              ),
              Text(
                price.verifiedAt == null
                    ? 'ยังไม่มีวันที่ตรวจสอบราคา'
                    : 'ตรวจสอบราคา ${_date(price.verifiedAt!)}',
              ),
              const SizedBox(height: 12),
              const Text(
                'สถานะราคายืนยันแล้วต้องมีหลักฐานภายใน 30 วัน ราคาอาจเปลี่ยนแปลง และหลักฐานราคาไม่ได้ยืนยันส่วนผสมหรือสารก่อภูมิแพ้',
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
      ? 'ทางตรงประมาณ ${meters.round()} เมตร'
      : 'ทางตรงประมาณ ${(meters / 1000).toStringAsFixed(1)} กิโลเมตร';

  static String _date(DateTime value) {
    final local = value.toLocal();
    return '${local.day}/${local.month}/${local.year + 543}';
  }

  static String _grams(double value) => value == value.roundToDouble()
      ? value.round().toString()
      : value.toStringAsFixed(1);

  static String _verificationLabel(RestaurantVerificationStatus status) =>
      switch (status) {
        RestaurantVerificationStatus.verified => 'ข้อมูลร้านได้รับการตรวจสอบ',
        RestaurantVerificationStatus.pending => 'ข้อมูลร้านกำลังรอตรวจสอบ',
        RestaurantVerificationStatus.unverified => 'ข้อมูลร้านยังไม่ยืนยัน',
      };

  static String _priceConfidenceLabel(PriceConfidence confidence) =>
      switch (confidence) {
        PriceConfidence.verified => 'ราคายืนยันแล้ว',
        PriceConfidence.estimated => 'ราคาโดยประมาณ',
        PriceConfidence.unverified => 'ราคายังไม่ยืนยัน',
      };
}

class RestaurantDetailUnavailableScreen extends StatelessWidget {
  const RestaurantDetailUnavailableScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('รายละเอียดร้าน')),
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.storefront_outlined, size: 52),
            const SizedBox(height: 16),
            Text(
              'เปิดรายละเอียดร้านไม่ได้',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'กลับไปเลือกเมนูอีกครั้ง เพื่อให้ข้อมูลร้านตรงกับผลแนะนำล่าสุด',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () => context.go('/recommendations'),
              child: const Text('กลับไปเมนูแนะนำ'),
            ),
          ],
        ),
      ),
    ),
  );
}

class _MealSelectionAction extends StatelessWidget {
  const _MealSelectionAction({
    required this.account,
    required this.state,
    required this.menuId,
    required this.onSignIn,
    required this.onRetryAccount,
    required this.onSelect,
  });

  final AsyncValue<Account?> account;
  final MealSelectionState state;
  final String menuId;
  final VoidCallback onSignIn;
  final VoidCallback onRetryAccount;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) => account.when(
    loading: () => const _WideActionButton(
      onPressed: null,
      icon: SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
      label: 'กำลังตรวจสอบบัญชี',
    ),
    error: (error, stack) => Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('ตรวจสอบบัญชีไม่สำเร็จ'),
        TextButton(onPressed: onRetryAccount, child: const Text('ลองอีกครั้ง')),
      ],
    ),
    data: (value) {
      if (value == null) {
        return _WideActionButton(
          key: const ValueKey('sign-in-to-select-meal'),
          onPressed: onSignIn,
          icon: const Icon(Icons.login),
          label: 'เข้าสู่ระบบเพื่อบันทึกมื้อ',
        );
      }
      final userId = value.uid?.trim();
      if (userId == null || userId.isEmpty) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('เซสชันบัญชียังไม่พร้อม'),
            TextButton(
              onPressed: onRetryAccount,
              child: const Text('ตรวจสอบอีกครั้ง'),
            ),
          ],
        );
      }
      final isSaving =
          state.status == MealSelectionStatus.saving && state.menuId == menuId;
      final isSaved = state.saved(menuId);
      return _WideActionButton(
        key: const ValueKey('select-meal'),
        onPressed: isSaving || isSaved ? null : () => onSelect(userId),
        icon: isSaving
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(isSaved ? Icons.check : Icons.restaurant_outlined),
        label: isSaving
            ? 'กำลังบันทึกมื้อ'
            : isSaved
            ? 'บันทึกมื้อนี้แล้ว'
            : state.status == MealSelectionStatus.failure
            ? 'ลองบันทึกมื้อนี้อีกครั้ง'
            : 'เลือกเมนูนี้เป็นมื้อนี้',
      );
    },
  );
}

class _WideActionButton extends StatelessWidget {
  const _WideActionButton({
    required this.onPressed,
    required this.icon,
    required this.label,
    super.key,
  });

  final VoidCallback? onPressed;
  final Widget icon;
  final String label;

  @override
  Widget build(BuildContext context) => FilledButton(
    onPressed: onPressed,
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        icon,
        const SizedBox(width: 12),
        Flexible(child: Text(label, textAlign: TextAlign.center)),
      ],
    ),
  );
}

class _CatalogImage extends StatelessWidget {
  const _CatalogImage({this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final url = imageUrl?.trim();
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: url == null || url.isEmpty
            ? const _ImageFallback()
            : Image.network(
                url,
                fit: BoxFit.cover,
                semanticLabel: 'ภาพเมนูจากข้อมูลร้าน',
                errorBuilder: (context, error, stack) =>
                    const _ImageFallback(loadFailed: true),
              ),
      ),
    );
  }
}

class _ImageFallback extends StatelessWidget {
  const _ImageFallback({this.loadFailed = false});

  final bool loadFailed;

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: AppTheme.orangeSoft,
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const ExcludeSemantics(
          child: Icon(Icons.restaurant_menu, size: 58, color: AppTheme.warning),
        ),
        const SizedBox(height: 8),
        Text(loadFailed ? 'โหลดภาพไม่ได้ — แสดงภาพประกอบ' : 'ภาพประกอบเมนู'),
      ],
    ),
  );
}

class _PriceCard extends StatelessWidget {
  const _PriceCard({
    required this.amount,
    required this.confidence,
    required this.onEvidencePressed,
  });

  final int amount;
  final PriceConfidence confidence;
  final VoidCallback onEvidencePressed;

  @override
  Widget build(BuildContext context) {
    final prefix = confidence == PriceConfidence.verified ? '' : 'ประมาณ ';
    return Card(
      color: AppTheme.coralSoft,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '$prefix$amount บาท',
              style: Theme.of(context).textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            Text(RestaurantDetailScreen._priceConfidenceLabel(confidence)),
            const SizedBox(height: 4),
            TextButton(
              key: const ValueKey('price-evidence'),
              onPressed: onEvidencePressed,
              child: const Text('ดูที่มาราคา'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.children,
    this.supportingText,
  });

  final String title;
  final String? supportingText;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          if (supportingText != null) ...[
            const SizedBox(height: 4),
            Text(
              supportingText!,
              style: const TextStyle(color: AppTheme.muted),
            ),
          ],
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    ),
  );
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppTheme.coralActive),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text(subtitle, style: const TextStyle(color: AppTheme.muted)),
            ],
          ),
        ),
      ],
    ),
  );
}

class _NutritionValue extends StatelessWidget {
  const _NutritionValue({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 132,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppTheme.muted)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
      ],
    ),
  );
}

class _DietaryEvidenceCard extends StatelessWidget {
  const _DietaryEvidenceCard({required this.details});

  final RestaurantDetailArguments details;

  @override
  Widget build(BuildContext context) {
    final menu = details.menu;
    final ingredients = menu.ingredients.map((item) => item.label).join(', ');
    final allergens = menu.allergens.map((item) => item.label).join(', ');
    return _SectionCard(
      title: 'ข้อมูลส่วนผสมและสารก่อภูมิแพ้',
      supportingText:
          'ข้อมูลนี้แยกจากการยืนยันราคา และไม่ใช่การรับรองว่าปลอดสารก่อภูมิแพ้',
      children: [
        Text(
          ingredients.isEmpty
              ? 'ยังไม่มีรายการส่วนผสมที่ระบุ'
              : 'ส่วนผสมที่มีข้อมูล: $ingredients',
        ),
        if (!menu.ingredientsKnown)
          const Text(
            'รายการส่วนผสมยังไม่ครบ',
            style: TextStyle(color: AppTheme.warning),
          ),
        const SizedBox(height: 8),
        Text(
          allergens.isEmpty
              ? 'ยังไม่มีสารก่อภูมิแพ้ที่ระบุ'
              : 'สารก่อภูมิแพ้ที่มีข้อมูล: $allergens',
        ),
        if (!menu.allergensKnown)
          const Text(
            'ข้อมูลสารก่อภูมิแพ้และการปนเปื้อนยังไม่ครบ',
            style: TextStyle(color: AppTheme.warning),
          ),
        if (menu.vegetarianConfirmed || menu.halalConfirmed) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (menu.vegetarianConfirmed)
                const Chip(label: Text('ยืนยันมังสวิรัติ')),
              if (menu.halalConfirmed)
                const Chip(label: Text('มีข้อมูลยืนยันฮาลาล')),
            ],
          ),
        ],
        const SizedBox(height: 12),
        const Text(
          'หากมีข้อจำกัดหรืออาการแพ้ ควรยืนยันสูตรและการปนเปื้อนกับร้านทุกครั้ง',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
