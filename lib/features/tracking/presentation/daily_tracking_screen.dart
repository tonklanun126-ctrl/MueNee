import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_theme.dart';
import '../../../app/widgets/main_navigation_bar.dart';
import '../../auth/auth_repository.dart';
import '../models/daily_nutrition_summary.dart';
import '../models/meal_log.dart';
import '../providers/daily_tracking_provider.dart';

class DailyTrackingScreen extends ConsumerStatefulWidget {
  const DailyTrackingScreen({super.key, this.initialDay, this.referenceNow});

  final DateTime? initialDay;
  final DateTime? referenceNow;

  @override
  ConsumerState<DailyTrackingScreen> createState() =>
      _DailyTrackingScreenState();
}

class _DailyTrackingScreenState extends ConsumerState<DailyTrackingScreen> {
  late final DateTime _today;
  late DateTime _selectedDay;

  @override
  void initState() {
    super.initState();
    final now = widget.referenceNow ?? DateTime.now();
    _today = DateTime(now.year, now.month, now.day);
    final initial = widget.initialDay ?? now;
    final requested = DateTime(initial.year, initial.month, initial.day);
    _selectedDay = requested.isAfter(_today) ? _today : requested;
  }

  @override
  Widget build(BuildContext context) {
    final account = ref.watch(accountProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('บันทึกประจำวัน')),
      bottomNavigationBar: const MainNavigationBar(selectedIndex: 1),
      body: account.when(
        loading: () => const _CenteredState(
          icon: Icons.hourglass_top,
          title: 'กำลังตรวจสอบบัญชี',
        ),
        error: (error, stack) => _CenteredState(
          icon: Icons.cloud_off_outlined,
          title: 'ตรวจสอบบัญชีไม่สำเร็จ',
          supportingText: 'ลองเชื่อมต่ออีกครั้งเพื่อดูบันทึกของคุณ',
          actionLabel: 'ลองอีกครั้ง',
          onAction: () => ref.invalidate(accountProvider),
        ),
        data: (account) {
          final userId = account?.uid?.trim();
          if (account == null) {
            return _CenteredState(
              icon: Icons.lock_outline,
              title: 'เข้าสู่ระบบเพื่อดูบันทึก',
              supportingText: 'มื้อที่บันทึกจะเป็นข้อมูลส่วนตัวของบัญชีคุณ',
              actionLabel: 'เข้าสู่ระบบ',
              onAction: () => context.push('/account'),
            );
          }
          if (userId == null || userId.isEmpty) {
            return _CenteredState(
              icon: Icons.sync_problem_outlined,
              title: 'เซสชันบัญชียังไม่พร้อม',
              supportingText: 'ตรวจสอบบัญชีอีกครั้งก่อนเปิดบันทึก',
              actionLabel: 'ตรวจสอบอีกครั้ง',
              onAction: () => ref.invalidate(accountProvider),
            );
          }
          return _SignedInTracking(
            userId: userId,
            selectedDay: _selectedDay,
            today: _today,
            onPreviousDay: () => setState(
              () => _selectedDay = DateTime(
                _selectedDay.year,
                _selectedDay.month,
                _selectedDay.day - 1,
              ),
            ),
            onNextDay: _selectedDay.isBefore(_today)
                ? () => setState(
                    () => _selectedDay = DateTime(
                      _selectedDay.year,
                      _selectedDay.month,
                      _selectedDay.day + 1,
                    ),
                  )
                : null,
          );
        },
      ),
    );
  }
}

class _SignedInTracking extends ConsumerWidget {
  const _SignedInTracking({
    required this.userId,
    required this.selectedDay,
    required this.today,
    required this.onPreviousDay,
    required this.onNextDay,
  });

  final String userId;
  final DateTime selectedDay;
  final DateTime today;
  final VoidCallback onPreviousDay;
  final VoidCallback? onNextDay;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final request = DailyMealRequest(userId: userId, localDay: selectedDay);
    final meals = ref.watch(dailyMealsProvider(request));
    return Column(
      children: [
        _DaySelector(
          selectedDay: selectedDay,
          isToday: selectedDay == today,
          onPreviousDay: onPreviousDay,
          onNextDay: onNextDay,
        ),
        Expanded(
          child: meals.when(
            loading: () => const _TrackingLoading(),
            error: (error, stack) => _TrackingError(
              onRetry: () => ref.invalidate(dailyMealsProvider(request)),
            ),
            data: (items) => _TrackingContent(
              meals: items,
              isToday: selectedDay == today,
              onRefresh: () async {
                ref.invalidate(dailyMealsProvider(request));
                await ref.read(dailyMealsProvider(request).future);
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _DaySelector extends StatelessWidget {
  const _DaySelector({
    required this.selectedDay,
    required this.isToday,
    required this.onPreviousDay,
    required this.onNextDay,
  });

  final DateTime selectedDay;
  final bool isToday;
  final VoidCallback onPreviousDay;
  final VoidCallback? onNextDay;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
    child: Row(
      children: [
        IconButton(
          key: const ValueKey('previous-tracking-day'),
          tooltip: 'วันก่อนหน้า',
          onPressed: onPreviousDay,
          icon: const Icon(Icons.chevron_left),
        ),
        Expanded(
          child: Column(
            children: [
              Text(
                isToday ? 'วันนี้' : _weekday(selectedDay.weekday),
                style: Theme.of(context).textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              Text(
                '${selectedDay.day} ${_month(selectedDay.month)} ${selectedDay.year + 543}',
                style: const TextStyle(color: AppTheme.muted),
              ),
            ],
          ),
        ),
        IconButton(
          key: const ValueKey('next-tracking-day'),
          tooltip: 'วันถัดไป',
          onPressed: onNextDay,
          icon: const Icon(Icons.chevron_right),
        ),
      ],
    ),
  );

  static String _weekday(int weekday) => const [
    'วันจันทร์',
    'วันอังคาร',
    'วันพุธ',
    'วันพฤหัสบดี',
    'วันศุกร์',
    'วันเสาร์',
    'วันอาทิตย์',
  ][weekday - 1];

  static String _month(int month) => const [
    'ม.ค.',
    'ก.พ.',
    'มี.ค.',
    'เม.ย.',
    'พ.ค.',
    'มิ.ย.',
    'ก.ค.',
    'ส.ค.',
    'ก.ย.',
    'ต.ค.',
    'พ.ย.',
    'ธ.ค.',
  ][month - 1];
}

class _TrackingContent extends StatelessWidget {
  const _TrackingContent({
    required this.meals,
    required this.isToday,
    required this.onRefresh,
  });

  final List<MealLog> meals;
  final bool isToday;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    if (meals.isEmpty) {
      return RefreshIndicator(
        onRefresh: onRefresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(24, 48, 24, 96),
          children: [
            Icon(
              Icons.no_meals_outlined,
              size: 56,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              isToday
                  ? 'ยังไม่มีมื้อที่บันทึกในวันนี้'
                  : 'ไม่มีมื้อที่บันทึกในวันนี้',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            const Text(
              'ดึงหน้าจอลงเพื่ออัปเดตข้อมูล',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.muted),
            ),
            if (isToday) ...[
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: () => context.go('/'),
                icon: const Icon(Icons.restaurant_menu),
                label: const Text('ให้ MueNee ช่วยเลือกมื้อ'),
              ),
            ],
          ],
        ),
      );
    }

    final summary = DailyNutritionSummary.fromMeals(meals);
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
        children: [
          _SummaryCard(summary: summary),
          const SizedBox(height: 16),
          Text(
            'มื้อที่บันทึก (${summary.mealCount})',
            style: Theme.of(context).textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          ...meals.map(
            (meal) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _MealCard(meal: meal),
            ),
          ),
          if (meals.length == 50)
            const Text(
              'แสดงสูงสุด 50 มื้อต่อวัน',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.muted),
            ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.summary});

  final DailyNutritionSummary summary;

  @override
  Widget build(BuildContext context) => Card(
    color: AppTheme.coralSoft,
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'สรุปจากมื้อที่บันทึก',
            style: Theme.of(context).textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          Text(
            'ประมาณ ${summary.calories} kcal',
            style: Theme.of(context).textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 16,
            runSpacing: 10,
            children: [
              _Nutrient(label: 'โปรตีน', value: summary.proteinGrams),
              _Nutrient(label: 'คาร์บ', value: summary.carbsGrams),
              _Nutrient(label: 'ไขมัน', value: summary.fatGrams),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'เป็นผลรวมจากค่าประมาณของแต่ละรายการ ไม่ใช่เป้าหมายหรือคำแนะนำทางการแพทย์',
            style: TextStyle(color: AppTheme.body),
          ),
        ],
      ),
    ),
  );
}

class _Nutrient extends StatelessWidget {
  const _Nutrient({required this.label, required this.value});

  final String label;
  final double value;

  @override
  Widget build(BuildContext context) => Text(
    '$label ${_grams(value)} กรัม',
    style: const TextStyle(fontWeight: FontWeight.w600),
  );
}

class _MealCard extends StatelessWidget {
  const _MealCard({required this.meal});

  final MealLog meal;

  @override
  Widget build(BuildContext context) {
    final time = meal.createdAt.toLocal();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: AppTheme.orangeSoft,
              foregroundColor: AppTheme.warning,
              child: Icon(_sourceIcon(meal.source)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    meal.foodName,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${_twoDigits(time.hour)}:${_twoDigits(time.minute)} • ${_sourceLabel(meal.source)}',
                    style: const TextStyle(color: AppTheme.muted),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'ประมาณ ${meal.nutrition.calories} kcal • โปรตีน ${_grams(meal.nutrition.proteinGrams)} กรัม',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static IconData _sourceIcon(MealSource source) => switch (source) {
    MealSource.recommendation => Icons.auto_awesome_outlined,
    MealSource.foodScan => Icons.document_scanner_outlined,
    MealSource.manual => Icons.edit_note_outlined,
  };

  static String _sourceLabel(MealSource source) => switch (source) {
    MealSource.recommendation => 'จากเมนูแนะนำ',
    MealSource.foodScan => 'จากการสแกนอาหาร',
    MealSource.manual => 'เพิ่มเอง',
  };

  static String _twoDigits(int value) => value.toString().padLeft(2, '0');
}

class _TrackingLoading extends StatelessWidget {
  const _TrackingLoading();

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(24),
    children: const [
      LinearProgressIndicator(),
      SizedBox(height: 16),
      Text('กำลังโหลดมื้อที่บันทึก', textAlign: TextAlign.center),
    ],
  );
}

class _TrackingError extends StatelessWidget {
  const _TrackingError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => _CenteredState(
    icon: Icons.cloud_off_outlined,
    title: 'โหลดบันทึกไม่สำเร็จ',
    supportingText: 'ข้อมูลเดิมไม่ถูกลบ ลองเชื่อมต่อแล้วโหลดอีกครั้ง',
    actionLabel: 'ลองโหลดอีกครั้ง',
    onAction: onRetry,
  );
}

class _CenteredState extends StatelessWidget {
  const _CenteredState({
    required this.icon,
    required this.title,
    this.supportingText,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String? supportingText;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Center(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 52, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          if (supportingText != null) ...[
            const SizedBox(height: 8),
            Text(supportingText!, textAlign: TextAlign.center),
          ],
          if (onAction != null && actionLabel != null) ...[
            const SizedBox(height: 20),
            FilledButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    ),
  );
}

String _grams(double value) => value == value.roundToDouble()
    ? value.round().toString()
    : value.toStringAsFixed(1);
