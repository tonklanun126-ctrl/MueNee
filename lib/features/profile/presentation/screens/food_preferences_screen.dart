import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../app/motion/app_feedback.dart';
import '../../../../core/monitoring/telemetry_providers.dart';
import '../../../../core/monitoring/telemetry_service.dart';
import '../../models/food_preferences.dart';
import '../../providers/food_preferences_provider.dart';

class FoodPreferencesScreen extends ConsumerWidget {
  const FoodPreferencesScreen({super.key, this.isMealFlow = false});

  final bool isMealFlow;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preferences = ref.watch(foodPreferencesProvider);
    return preferences.when(
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('การตั้งค่าอาหาร')),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        appBar: AppBar(title: const Text('การตั้งค่าอาหาร')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('โหลดการตั้งค่าไม่สำเร็จ ข้อมูลเดิมยังไม่ถูกแก้ไข'),
              TextButton(
                onPressed: () => ref.invalidate(foodPreferencesProvider),
                child: const Text('ลองอีกครั้ง'),
              ),
            ],
          ),
        ),
      ),
      data: (value) =>
          _FoodPreferencesForm(initial: value, isMealFlow: isMealFlow),
    );
  }
}

class _FoodPreferencesForm extends ConsumerStatefulWidget {
  const _FoodPreferencesForm({required this.initial, required this.isMealFlow});

  final FoodPreferences initial;
  final bool isMealFlow;

  @override
  ConsumerState<_FoodPreferencesForm> createState() =>
      _FoodPreferencesFormState();
}

class _FoodPreferencesFormState extends ConsumerState<_FoodPreferencesForm> {
  late FoodPreferences _draft = widget.initial;
  late String _saved = jsonEncode(widget.initial.toJson());
  bool _saving = false;
  bool _allowPop = false;
  bool _confirming = false;
  bool _confirmedForMeal = false;

  bool get _dirty => jsonEncode(_draft.toJson()) != _saved;

  Set<T> _toggle<T>(Set<T> source, T value, bool selected) =>
      selected ? {...source, value} : ({...source}..remove(value));

  Future<void> _save() async {
    final submitted = _draft;
    setState(() => _saving = true);
    try {
      await ref.read(foodPreferencesProvider.notifier).save(submitted);
      if (!mounted) return;
      setState(() {
        _saved = jsonEncode(submitted.toJson());
        _confirmedForMeal = widget.isMealFlow;
      });
      if (widget.isMealFlow) _recordMealConfirmation();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('บันทึกการตั้งค่าอาหารแล้ว')),
      );
    } catch (error, stack) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stack,
          library: 'food preferences',
          context: ErrorDescription('while saving local preferences'),
        ),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('บันทึกไม่สำเร็จ กรุณาลองอีกครั้ง')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _confirmForMeal() async {
    if (_dirty) {
      await _save();
      return;
    }
    setState(() => _confirmedForMeal = true);
    _recordMealConfirmation();
  }

  void _recordMealConfirmation() {
    unawaited(AppFeedback.confirmed());
    unawaited(
      ref
          .read(telemetryServiceProvider)
          .logEvent(MueNeeAnalyticsEvent.preferencesConfirmed),
    );
  }

  void _updateDraft(FoodPreferences value) {
    setState(() {
      _draft = value;
      _confirmedForMeal = false;
    });
  }

  Future<void> _confirmLeave() async {
    if (_saving || _confirming) return;
    _confirming = true;
    final discard = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ยังไม่ได้บันทึกการเปลี่ยนแปลง'),
        content: const Text(
          'ต้องการออกจากหน้านี้และทิ้งการเปลี่ยนแปลงหรือไม่?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('แก้ไขต่อ'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('ทิ้งการเปลี่ยนแปลง'),
          ),
        ],
      ),
    );
    _confirming = false;
    if (!mounted || discard != true) return;
    setState(() => _allowPop = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.of(context).pop();
    });
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: _allowPop || (!_dirty && !_saving),
    onPopInvokedWithResult: (didPop, result) {
      if (!didPop) _confirmLeave();
    },
    child: Scaffold(
      appBar: AppBar(title: const Text('การตั้งค่าอาหาร')),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: AbsorbPointer(
            absorbing: _saving,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                if (widget.isMealFlow) ...[
                  const _MealFlowHeader(),
                  const SizedBox(height: 24),
                ],
                Text(
                  'เลือกให้ตรงกับมื้อของคุณ',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                const Text('บันทึกไว้ในเครื่องนี้ เพื่อใช้คัดเมนูที่ตรงกับคุณ'),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.coralSoft,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'ข้อจำกัด ${_draft.restrictions.length} • อาหารที่แพ้ ${_draft.allergies.length} • ไม่ชอบ ${_draft.dislikes.length}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: 24),
                const _SectionTitle('ไม่กิน / ข้อจำกัดอาหาร'),
                const Text(
                  'กรองเมนูที่ไม่ตรงเงื่อนไข หรือข้อมูลไม่พอยืนยันออก',
                ),
                for (final option in DietaryRestriction.values)
                  CheckboxListTile(
                    key: ValueKey('restriction-${option.name}'),
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    title: Text(option.label),
                    subtitle: switch (option) {
                      DietaryRestriction.vegetarian => const Text(
                        'ไม่กินเนื้อสัตว์ รวมปลาและอาหารทะเล แต่กินไข่และนมได้',
                      ),
                      DietaryRestriction.halalOnly => const Text(
                        'ต้องมีข้อมูลยืนยันฮาลาล ไม่ใช้แค่การไม่มีหมู',
                      ),
                      _ => null,
                    },
                    value: _draft.restrictions.contains(option),
                    onChanged: (selected) => _updateDraft(
                      _draft.copyWith(
                        restrictions: _toggle(
                          _draft.restrictions,
                          option,
                          selected!,
                        ),
                      ),
                    ),
                  ),
                const Divider(height: 32),
                const _SectionTitle('อาหารที่แพ้'),
                const Text(
                  'เลือกรายการที่แพ้จากตัวเลือกที่รองรับ แยกจากอาหารที่ไม่ชอบ',
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final option in FoodAllergen.values)
                      FilterChip(
                        key: ValueKey('allergy-${option.name}'),
                        label: Text(option.label),
                        selected: _draft.allergies.contains(option),
                        onSelected: (selected) => _updateDraft(
                          _draft.copyWith(
                            allergies: _toggle(
                              _draft.allergies,
                              option,
                              selected,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'เมนูที่มีสารก่อภูมิแพ้ที่เลือกหรือข้อมูลไม่ครบจะถูกซ่อน '
                  'การกรองไม่รับรองว่าปลอดสารก่อภูมิแพ้ กรุณายืนยันกับร้านก่อนสั่ง',
                ),
                const Divider(height: 32),
                ExpansionTile(
                  initiallyExpanded: true,
                  maintainState: true,
                  tilePadding: EdgeInsets.zero,
                  title: const Text('อาหารที่ไม่ชอบ'),
                  subtitle: Text(
                    _draft.dislikes.isEmpty
                        ? 'ยังไม่ได้เลือก • ${_draft.hideDisliked ? 'ซ่อนทั้งหมด' : 'จัดไว้ท้ายรายการ'}'
                        : '${_draft.dislikes.map((item) => item.label).join(' · ')}\n${_draft.hideDisliked ? 'ซ่อนทั้งหมด' : 'จัดไว้ท้ายรายการ'}',
                  ),
                  children: [
                    const Text('เมนูที่มีส่วนผสมเหล่านี้จะแสดงท้ายรายการ'),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final option in FoodIngredient.values)
                          FilterChip(
                            key: ValueKey('dislike-${option.name}'),
                            label: Text(option.label),
                            selected: _draft.dislikes.contains(option),
                            onSelected: (selected) => _updateDraft(
                              _draft.copyWith(
                                dislikes: _toggle(
                                  _draft.dislikes,
                                  option,
                                  selected,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    SwitchListTile(
                      key: const ValueKey('hide-disliked'),
                      contentPadding: EdgeInsets.zero,
                      title: const Text('ซ่อนอาหารที่ไม่ชอบทั้งหมด'),
                      subtitle: const Text('รวมเมนูที่ข้อมูลส่วนผสมไม่ครบ'),
                      value: _draft.hideDisliked,
                      onChanged: (value) =>
                          _updateDraft(_draft.copyWith(hideDisliked: value)),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () => _updateDraft(FoodPreferences()),
                  child: const Text('ล้างตัวเลือกทั้งหมด (ต้องกดบันทึก)'),
                ),
                if (widget.isMealFlow && _confirmedForMeal) ...[
                  const SizedBox(height: 12),
                  const _MealReadyCard(),
                ],
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(16),
        child: FilledButton.icon(
          key: ValueKey(
            widget.isMealFlow ? 'confirm-food-for-meal' : 'save-food-settings',
          ),
          onPressed: _saving
              ? null
              : widget.isMealFlow
              ? (_confirmedForMeal
                    ? () => context.push('/recommendations')
                    : _confirmForMeal)
              : (_dirty ? _save : null),
          icon: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.check),
          label: Text(
            _saving
                ? 'กำลังบันทึก…'
                : widget.isMealFlow
                ? (_confirmedForMeal
                      ? 'ดูเมนูแนะนำ'
                      : _dirty
                      ? 'บันทึกและยืนยันสำหรับมื้อนี้'
                      : 'ใช้การตั้งค่านี้สำหรับมื้อนี้')
                : 'บันทึกการตั้งค่า',
          ),
        ),
      ),
    ),
  );
}

class _MealFlowHeader extends StatelessWidget {
  const _MealFlowHeader();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppTheme.coralSoft,
      borderRadius: BorderRadius.circular(16),
    ),
    child: const Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.restaurant_menu, color: AppTheme.coralActive),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ตั้งค่าสำหรับมื้อนี้',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              SizedBox(height: 4),
              Text('ข้อจำกัดและอาหารที่แพ้จะใช้เป็นตัวกรองแบบเคร่งครัด'),
            ],
          ),
        ),
      ],
    ),
  );
}

class _MealReadyCard extends StatelessWidget {
  const _MealReadyCard();

  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    child: Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.check_circle, color: AppTheme.success),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'พร้อมแล้ว การตั้งค่านี้จะใช้ค้นหาเมนูในขั้นตอนถัดไป',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.success,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);
  final String title;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(title, style: Theme.of(context).textTheme.titleLarge),
  );
}
