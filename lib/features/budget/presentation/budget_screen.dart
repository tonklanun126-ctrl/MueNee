import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_theme.dart';
import '../../../app/theme/app_tokens.dart';
import '../../../app/widgets/companion_components.dart';
import '../models/meal_budget.dart';
import '../providers/meal_budget_provider.dart';
import '../../../app/motion/app_feedback.dart';
import '../../../core/monitoring/telemetry_providers.dart';
import '../../../core/monitoring/telemetry_service.dart';

class BudgetScreen extends ConsumerStatefulWidget {
  const BudgetScreen({this.initialAmount, super.key});

  final int? initialAmount;

  @override
  ConsumerState<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends ConsumerState<BudgetScreen> {
  final _form = GlobalKey<FormState>();
  final _focus = FocusNode();
  late final TextEditingController _amount;
  bool _allowPop = false;
  bool _asking = false;
  bool _confirmed = false;

  @override
  void initState() {
    super.initState();
    _amount = TextEditingController(
      text:
          widget.initialAmount?.toString() ??
          ref.read(mealBudgetProvider)?.amountBaht.toString() ??
          '',
    );
    _amount.addListener(_changed);
  }

  void _changed() => setState(() => _confirmed = false);

  bool get _dirty {
    final saved = ref.read(mealBudgetProvider);
    if (_amount.text.trim().isEmpty && saved == null) return false;
    final parsed = MealBudget.parseUserInput(_amount.text);
    return !parsed.isValid || parsed.budget != saved;
  }

  void _confirm() {
    if (!_form.currentState!.validate()) {
      _focus.requestFocus();
      return;
    }
    ref.read(mealBudgetProvider.notifier).confirmInput(_amount.text);
    _focus.unfocus();
    setState(() => _confirmed = true);
    unawaited(AppFeedback.confirmed());
    unawaited(
      ref
          .read(telemetryServiceProvider)
          .logEvent(MueNeeAnalyticsEvent.budgetConfirmed),
    );
  }

  Future<void> _leave() async {
    if (_asking) return;
    _asking = true;
    final discard = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ยังไม่ได้ยืนยันงบใหม่'),
        content: const Text('ออกจากหน้านี้โดยใช้ค่างบเดิมหรือไม่?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('แก้ไขต่อ'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('ทิ้งการแก้ไข'),
          ),
        ],
      ),
    );
    _asking = false;
    if (!mounted || discard != true) return;
    setState(() => _allowPop = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.of(context).pop();
    });
  }

  @override
  void dispose() {
    _amount.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final saved = ref.watch(mealBudgetProvider);
    final selected = MealBudget.parseUserInput(_amount.text).budget?.amountBaht;
    return PopScope(
      canPop: _allowPop || !_dirty,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _leave();
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('งบมื้อนี้')),
        body: SafeArea(
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _form,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'มื้ออร่อย ในงบของคุณ',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 8),
                      const Text('กำหนดงบสูงสุดสำหรับอาหารหนึ่งมื้อ'),
                      const SizedBox(height: AppSpacing.large),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: AppRadii.hero,
                          border: Border.all(color: AppTheme.hairline),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            TextFormField(
                              key: const ValueKey('budget-amount'),
                              controller: _amount,
                              focusNode: _focus,
                              keyboardType: TextInputType.number,
                              textInputAction: TextInputAction.done,
                              onFieldSubmitted: (_) => _confirm(),
                              style: Theme.of(context).textTheme.headlineMedium,
                              decoration: const InputDecoration(
                                labelText: 'งบสูงสุด',
                                suffixText: 'บาท',
                                hintText: 'เช่น 80',
                                errorMaxLines: 4,
                              ),
                              validator: (value) =>
                                  switch (MealBudget.parseUserInput(value ?? '')
                                      .error) {
                                    null => null,
                                    BudgetInputError.empty =>
                                      'กรุณาระบุงบมื้อนี้',
                                    BudgetInputError.invalidFormat =>
                                      'กรอกจำนวนเต็ม เช่น 80 หรือ 1,000 บาท',
                                    BudgetInputError.belowMinimum =>
                                      'งบต้องไม่น้อยกว่า 1 บาท',
                                    BudgetInputError.aboveMaximum =>
                                      'งบต้องไม่เกิน 10,000 บาท',
                                  },
                            ),
                            const SizedBox(height: 12),
                            const Text('1–10,000 บาท • จำนวนเต็ม'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      CompanionSectionHeader(
                        title: 'เลือกงบได้เร็วขึ้น',
                        subtitle: 'แตะเพื่อใส่ตัวเลข แล้วกดยืนยัน',
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final amount in [40, 60, 80, 100, 150])
                            CompanionBudgetChip(
                              amount: amount,
                              selected: selected == amount,
                              onTap: () {
                                _amount.text = amount.toString();
                                _form.currentState?.validate();
                                _focus.unfocus();
                              },
                            ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      if (saved != null) ...[
                        const SizedBox(height: 16),
                        Semantics(
                          liveRegion: true,
                          child: Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Text(
                                '${_confirmed ? 'ยืนยันแล้ว' : 'งบที่ยืนยันไว้'}: ไม่เกิน ${saved.amountBaht} บาท',
                                style: const TextStyle(
                                  color: AppTheme.success,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          key: const ValueKey('continue-to-food-preferences'),
                          onPressed: _dirty
                              ? null
                              : () => context.push('/food-settings?flow=meal'),
                          icon: const Icon(Icons.tune),
                          label: const Text('ต่อไป: เลือกอาหารที่กิน'),
                        ),
                      ],
                      const SizedBox(height: 20),
                      const Text(
                        'งบนี้เก็บไว้ชั่วคราว และอาจถูกล้างเมื่อแอปปิด ราคาจริงอาจเปลี่ยนแปลง ควรตรวจสอบกับร้านก่อนสั่ง',
                        style: TextStyle(color: AppTheme.muted),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        bottomNavigationBar: SafeArea(
          minimum: const EdgeInsets.all(16),
          child: FilledButton.icon(
            key: const ValueKey('confirm-meal-budget'),
            onPressed: _confirm,
            icon: const Icon(Icons.check),
            label: Text(
              selected == null ? 'ยืนยันงบมื้อนี้' : 'ใช้งบ $selected บาท',
            ),
          ),
        ),
      ),
    );
  }
}
