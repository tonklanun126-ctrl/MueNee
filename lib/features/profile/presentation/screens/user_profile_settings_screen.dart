import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/user_profile.dart';
import '../../providers/user_profile_provider.dart';

class UserProfileSettingsScreen extends ConsumerWidget {
  const UserProfileSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider);
    return profile.when(
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('ตั้งค่าโปรไฟล์')),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        appBar: AppBar(title: const Text('ตั้งค่าโปรไฟล์')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('โหลดโปรไฟล์ไม่สำเร็จ ข้อมูลเดิมยังไม่ถูกแก้ไข'),
              TextButton(
                onPressed: () => ref.invalidate(userProfileProvider),
                child: const Text('ลองอีกครั้ง'),
              ),
            ],
          ),
        ),
      ),
      data: (value) => _UserProfileForm(initial: value),
    );
  }
}

class _UserProfileForm extends ConsumerStatefulWidget {
  const _UserProfileForm({required this.initial});

  final UserProfile initial;

  @override
  ConsumerState<_UserProfileForm> createState() => _UserProfileFormState();
}

class _UserProfileFormState extends ConsumerState<_UserProfileForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _ageController;
  late final TextEditingController _heightController;
  late final TextEditingController _weightController;
  late ActivityLevel? _activityLevel = widget.initial.activityLevel;
  late String _saved = jsonEncode(widget.initial.toJson());
  bool _saving = false;
  bool _allowPop = false;
  bool _confirming = false;

  @override
  void initState() {
    super.initState();
    _ageController = TextEditingController(
      text: _formatInt(widget.initial.age),
    );
    _heightController = TextEditingController(
      text: _formatNumber(widget.initial.heightCm),
    );
    _weightController = TextEditingController(
      text: _formatNumber(widget.initial.weightKg),
    );
    for (final controller in [
      _ageController,
      _heightController,
      _weightController,
    ]) {
      controller.addListener(_onTextChanged);
    }
  }

  @override
  void dispose() {
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  UserProfile get _draft => UserProfile(
    age: _validAge(int.tryParse(_ageController.text.trim())),
    heightCm: _validHeight(_parseDouble(_heightController.text)),
    weightKg: _validWeight(_parseDouble(_weightController.text)),
    activityLevel: _activityLevel,
  );

  bool get _dirty => jsonEncode(_draft.toJson()) != _saved;

  void _onTextChanged() {
    if (mounted) setState(() {});
  }

  static String _formatInt(int? value) => value?.toString() ?? '';

  static String _formatNumber(double? value) {
    if (value == null) return '';
    return value == value.roundToDouble()
        ? value.toInt().toString()
        : value.toString();
  }

  static double? _parseDouble(String value) =>
      double.tryParse(value.trim().replaceAll(',', '.'));

  static int? _validAge(int? value) =>
      value != null &&
          value >= UserProfile.minAge &&
          value <= UserProfile.maxAge
      ? value
      : null;

  static double? _validHeight(double? value) =>
      value != null &&
          value >= UserProfile.minHeightCm &&
          value <= UserProfile.maxHeightCm
      ? value
      : null;

  static double? _validWeight(double? value) =>
      value != null &&
          value >= UserProfile.minWeightKg &&
          value <= UserProfile.maxWeightKg
      ? value
      : null;

  String? _validateAge(String? value) {
    final age = int.tryParse(value?.trim() ?? '');
    if (value == null || value.trim().isEmpty) return 'กรุณากรอกอายุ';
    if (age == null) return 'กรุณากรอกอายุเป็นจำนวนเต็ม';
    if (age < UserProfile.minAge || age > UserProfile.maxAge) {
      return 'อายุต้องอยู่ระหว่าง ${UserProfile.minAge}–${UserProfile.maxAge} ปี';
    }
    return null;
  }

  String? _validateHeight(String? value) {
    final height = _parseDouble(value ?? '');
    if (value == null || value.trim().isEmpty) return 'กรุณากรอกส่วนสูง';
    if (height == null) return 'กรุณากรอกส่วนสูงเป็นตัวเลข';
    if (height < UserProfile.minHeightCm || height > UserProfile.maxHeightCm) {
      return 'ส่วนสูงต้องอยู่ระหว่าง ${UserProfile.minHeightCm.toInt()}–${UserProfile.maxHeightCm.toInt()} ซม.';
    }
    return null;
  }

  String? _validateWeight(String? value) {
    final weight = _parseDouble(value ?? '');
    if (value == null || value.trim().isEmpty) return 'กรุณากรอกน้ำหนัก';
    if (weight == null) return 'กรุณากรอกน้ำหนักเป็นตัวเลข';
    if (weight < UserProfile.minWeightKg || weight > UserProfile.maxWeightKg) {
      return 'น้ำหนักต้องอยู่ระหว่าง ${UserProfile.minWeightKg.toInt()}–${UserProfile.maxWeightKg.toInt()} กก.';
    }
    return null;
  }

  String? _validateActivity(ActivityLevel? value) =>
      value == null ? 'กรุณาเลือกระดับกิจกรรม' : null;

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _activityLevel == null) {
      setState(() {});
      return;
    }
    final submitted = _draft;
    setState(() => _saving = true);
    try {
      await ref.read(userProfileProvider.notifier).save(submitted);
      if (!mounted) return;
      setState(() => _saved = jsonEncode(submitted.toJson()));
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('บันทึกโปรไฟล์แล้ว')));
    } catch (error, stack) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stack,
          library: 'user profile',
          context: ErrorDescription('while saving local profile'),
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
      appBar: AppBar(title: const Text('ตั้งค่าโปรไฟล์')),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: AbsorbPointer(
            absorbing: _saving,
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Text(
                    'ข้อมูลพื้นฐานของคุณ',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'บันทึกไว้ในเครื่องนี้ เพื่อเตรียมใช้ประกอบการแนะนำอาหาร',
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    key: const ValueKey('profile-age'),
                    controller: _ageController,
                    decoration: const InputDecoration(
                      labelText: 'อายุ',
                      suffixText: 'ปี',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.next,
                    validator: _validateAge,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    key: const ValueKey('profile-height'),
                    controller: _heightController,
                    decoration: const InputDecoration(
                      labelText: 'ส่วนสูง',
                      suffixText: 'ซม.',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    textInputAction: TextInputAction.next,
                    validator: _validateHeight,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    key: const ValueKey('profile-weight'),
                    controller: _weightController,
                    decoration: const InputDecoration(
                      labelText: 'น้ำหนัก',
                      suffixText: 'กก.',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    textInputAction: TextInputAction.next,
                    validator: _validateWeight,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<ActivityLevel>(
                    key: const ValueKey('profile-activity'),
                    initialValue: _activityLevel,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'ระดับกิจกรรม',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      for (final option in ActivityLevel.values)
                        DropdownMenuItem(
                          value: option,
                          child: Text(option.label),
                        ),
                    ],
                    onChanged: (value) => setState(() {
                      _activityLevel = value;
                    }),
                    validator: _validateActivity,
                  ),
                  if (_activityLevel != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      _activityLevel!.description,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                  const SizedBox(height: 16),
                  const Text(
                    'ข้อมูลนี้ยังไม่ใช้คำนวณเป้าหมายโภชนาการ คุณสามารถกลับมาแก้ไขได้เสมอ',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(16),
        child: FilledButton.icon(
          onPressed: _saving || !_dirty ? null : _save,
          icon: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.check),
          label: Text(_saving ? 'กำลังบันทึก…' : 'บันทึกโปรไฟล์'),
        ),
      ),
    ),
  );
}
