import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_theme.dart';
import '../../../app/theme/app_tokens.dart';
import '../../../app/widgets/main_navigation_bar.dart';
import '../../auth/auth_repository.dart';
import '../models/food_scan_result.dart';
import '../providers/food_scan_provider.dart';
import '../services/food_image_picker.dart';

class FoodScanScreen extends ConsumerStatefulWidget {
  const FoodScanScreen({super.key});

  @override
  ConsumerState<FoodScanScreen> createState() => _FoodScanScreenState();
}

class _FoodScanScreenState extends ConsumerState<FoodScanScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(foodScanProvider.notifier).recoverLostImage();
    });
  }

  @override
  Widget build(BuildContext context) {
    final account = ref.watch(accountProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('สแกนอาหาร')),
      bottomNavigationBar: const MainNavigationBar(selectedIndex: 2),
      body: account.when(
        loading: () => const _CenteredState(
          icon: Icons.hourglass_top,
          title: 'กำลังตรวจสอบบัญชี',
        ),
        error: (error, stack) => _CenteredState(
          icon: Icons.cloud_off_outlined,
          title: 'ตรวจสอบบัญชีไม่สำเร็จ',
          supportingText: 'ลองเชื่อมต่ออีกครั้งก่อนเริ่มสแกนอาหาร',
          actionLabel: 'ลองอีกครั้ง',
          onAction: () => ref.invalidate(accountProvider),
        ),
        data: (account) {
          final userId = account?.uid?.trim();
          if (account == null) {
            return _CenteredState(
              icon: Icons.lock_outline,
              title: 'เข้าสู่ระบบก่อนสแกนอาหาร',
              supportingText:
                  'ผลวิเคราะห์จะยังไม่ถูกบันทึก จนกว่าคุณตรวจแก้และกดยืนยัน',
              actionLabel: 'เข้าสู่ระบบ',
              onAction: () => context.push('/account'),
            );
          }
          if (userId == null || userId.isEmpty) {
            return _CenteredState(
              icon: Icons.sync_problem_outlined,
              title: 'เซสชันบัญชียังไม่พร้อม',
              actionLabel: 'ตรวจสอบอีกครั้ง',
              onAction: () => ref.invalidate(accountProvider),
            );
          }
          return _SignedInFoodScan(userId: userId);
        },
      ),
    );
  }
}

class _SignedInFoodScan extends ConsumerWidget {
  const _SignedInFoodScan({required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(foodScanProvider);
    final controller = ref.read(foodScanProvider.notifier);
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 96),
          children: [
            const _EstimateNotice(),
            const SizedBox(height: 14),
            if (state.image == null)
              _ImageStartCard(
                busy: state.status == FoodScanStatus.picking,
                onPick: controller.pick,
              )
            else
              _ImagePreview(
                image: state.image!,
                busy:
                    state.status == FoodScanStatus.picking ||
                    state.status == FoodScanStatus.analyzing ||
                    state.status == FoodScanStatus.saving,
                onPick: controller.pick,
              ),
            if (state.message != null) ...[
              const SizedBox(height: 12),
              _InlineMessage(message: state.message!),
            ],
            if (state.status == FoodScanStatus.ready) ...[
              const SizedBox(height: 16),
              FilledButton.icon(
                key: const ValueKey('analyze-food-image'),
                onPressed: controller.analyze,
                icon: const Icon(Icons.auto_awesome),
                label: const Text('วิเคราะห์ภาพด้วย AI'),
              ),
            ],
            if (state.status == FoodScanStatus.analyzing) ...[
              const SizedBox(height: 20),
              const LinearProgressIndicator(),
              const SizedBox(height: 10),
              const Text(
                'กำลังประเมินอาหารและปริมาณในภาพ…',
                textAlign: TextAlign.center,
              ),
            ],
            if ((state.status == FoodScanStatus.review ||
                    state.status == FoodScanStatus.saving) &&
                state.result != null) ...[
              const SizedBox(height: 18),
              _FoodReviewForm(
                key: ValueKey(state.revision),
                result: state.result!,
                saving: state.status == FoodScanStatus.saving,
                onConfirm:
                    ({
                      required foodName,
                      required calories,
                      required proteinGrams,
                      required carbsGrams,
                      required fatGrams,
                    }) => controller.confirmAndSave(
                      userId: userId,
                      foodName: foodName,
                      calories: calories,
                      proteinGrams: proteinGrams,
                      carbsGrams: carbsGrams,
                      fatGrams: fatGrams,
                    ),
              ),
            ],
            if (state.status == FoodScanStatus.saved) ...[
              const SizedBox(height: 18),
              _SavedCard(
                onTracking: () => context.go('/tracking'),
                onReset: controller.reset,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _EstimateNotice extends StatelessWidget {
  const _EstimateNotice();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppTheme.lilacSoft,
      borderRadius: AppRadii.button,
      border: Border.all(color: AppTheme.ink, width: .8),
    ),
    child: const Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.info_outline, color: AppTheme.warning),
        SizedBox(width: 12),
        Expanded(
          child: Text(
            'AI ให้ค่าประมาณจากภาพ ไม่ใช่ผลตรวจทางการแพทย์ '
            'ตรวจและแก้ข้อมูลก่อนยืนยันทุกครั้ง ภาพจะถูกส่งให้บริการ AI '
            'เมื่อกดวิเคราะห์ และ MueNee จะไม่เก็บรูปไว้ในบันทึก',
          ),
        ),
      ],
    ),
  );
}

class _ImageStartCard extends StatelessWidget {
  const _ImageStartCard({required this.busy, required this.onPick});

  final bool busy;
  final Future<void> Function(FoodImageSource) onPick;

  @override
  Widget build(BuildContext context) => Card(
    color: AppTheme.yellowSoft,
    shape: RoundedRectangleBorder(
      borderRadius: AppRadii.hero,
      side: const BorderSide(color: AppTheme.ink, width: 1),
    ),
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: AppTheme.yellow,
              borderRadius: AppRadii.card,
              border: Border.all(color: AppTheme.ink, width: 1),
            ),
            child: const Icon(Icons.photo_camera_outlined, size: 38),
          ),
          const SizedBox(height: 12),
          Text(
            'เพิ่มภาพมื้ออาหาร',
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          const Text(
            'ถ่ายให้เห็นอาหารและปริมาณชัดเจน ไม่ต้องมีใบหน้าหรือข้อมูลส่วนตัว',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 18),
          _PickButtons(busy: busy, onPick: onPick),
        ],
      ),
    ),
  );
}

class _ImagePreview extends StatelessWidget {
  const _ImagePreview({
    required this.image,
    required this.busy,
    required this.onPick,
  });

  final FoodScanImage image;
  final bool busy;
  final Future<void> Function(FoodImageSource) onPick;

  @override
  Widget build(BuildContext context) => Card(
    color: Colors.white,
    clipBehavior: Clip.antiAlias,
    child: Column(
      children: [
        Semantics(
          label: 'ภาพอาหารที่เลือก',
          image: true,
          child: AspectRatio(
            aspectRatio: 4 / 3,
            child: Image.memory(
              image.bytes,
              fit: BoxFit.cover,
              gaplessPlayback: true,
              errorBuilder: (context, error, stack) => const ColoredBox(
                color: AppTheme.canvas,
                child: Center(child: Icon(Icons.broken_image_outlined)),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(14),
          child: _PickButtons(busy: busy, onPick: onPick, compact: true),
        ),
      ],
    ),
  );
}

class _PickButtons extends StatelessWidget {
  const _PickButtons({
    required this.busy,
    required this.onPick,
    this.compact = false,
  });

  final bool busy;
  final bool compact;
  final Future<void> Function(FoodImageSource) onPick;

  @override
  Widget build(BuildContext context) => Wrap(
    alignment: WrapAlignment.center,
    spacing: 10,
    runSpacing: 10,
    children: [
      FilledButton.tonalIcon(
        key: const ValueKey('pick-food-camera'),
        onPressed: busy ? null : () => onPick(FoodImageSource.camera),
        icon: const Icon(Icons.photo_camera_outlined),
        label: Text(compact ? 'ถ่ายใหม่' : 'ถ่ายภาพ'),
      ),
      OutlinedButton.icon(
        key: const ValueKey('pick-food-gallery'),
        onPressed: busy ? null : () => onPick(FoodImageSource.gallery),
        icon: const Icon(Icons.photo_library_outlined),
        label: Text(compact ? 'เปลี่ยนภาพ' : 'เลือกจากเครื่อง'),
      ),
    ],
  );
}

typedef ConfirmFoodScan = Future<bool> Function({
  required String foodName,
  required int calories,
  required double proteinGrams,
  required double carbsGrams,
  required double fatGrams,
});

class _FoodReviewForm extends StatefulWidget {
  const _FoodReviewForm({
    required this.result,
    required this.saving,
    required this.onConfirm,
    super.key,
  });

  final FoodScanResult result;
  final bool saving;
  final ConfirmFoodScan onConfirm;

  @override
  State<_FoodReviewForm> createState() => _FoodReviewFormState();
}

class _FoodReviewFormState extends State<_FoodReviewForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _calories;
  late final TextEditingController _protein;
  late final TextEditingController _carbs;
  late final TextEditingController _fat;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.result.foodName);
    _calories = TextEditingController(
      text: widget.result.nutrition.calories.toString(),
    );
    _protein = TextEditingController(
      text: _number(widget.result.nutrition.proteinGrams),
    );
    _carbs = TextEditingController(
      text: _number(widget.result.nutrition.carbsGrams),
    );
    _fat = TextEditingController(
      text: _number(widget.result.nutrition.fatGrams),
    );
  }

  @override
  void dispose() {
    _name.dispose();
    _calories.dispose();
    _protein.dispose();
    _carbs.dispose();
    _fat.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Card(
    shape: RoundedRectangleBorder(
      borderRadius: AppRadii.hero,
      side: const BorderSide(color: AppTheme.ink, width: 1),
    ),
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'ตรวจและแก้ค่าประมาณ',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.yellow,
                borderRadius: AppRadii.button,
                border: Border.all(color: AppTheme.ink, width: .8),
              ),
              child: const Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 6,
                children: [
                  Icon(Icons.edit_outlined, size: 17),
                  Text('ค่าประมาณ · แก้ไขได้'),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text('ปริมาณที่ประเมิน: ${widget.result.assumption}'),
            const SizedBox(height: 16),
            TextFormField(
              key: const ValueKey('food-name-field'),
              controller: _name,
              enabled: !widget.saving,
              textInputAction: TextInputAction.next,
              maxLength: 160,
              decoration: const InputDecoration(labelText: 'ชื่ออาหาร'),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'กรอกชื่ออาหาร'
                  : null,
            ),
            _NutritionFields(
              calories: _calories,
              protein: _protein,
              carbs: _carbs,
              fat: _fat,
              enabled: !widget.saving,
            ),
            const SizedBox(height: 18),
            const Text(
              'ตรวจชื่ออาหารและปริมาณอีกครั้งก่อนบันทึกมื้อนี้',
              style: TextStyle(color: AppTheme.body),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              key: const ValueKey('confirm-food-scan'),
              onPressed: widget.saving ? null : _submit,
              icon: widget.saving
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check_circle_outline),
              label: Text(
                widget.saving ? 'กำลังบันทึก…' : 'ยืนยันและบันทึกมื้อนี้',
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    await widget.onConfirm(
      foodName: _name.text.trim(),
      calories: int.parse(_calories.text),
      proteinGrams: double.parse(_protein.text),
      carbsGrams: double.parse(_carbs.text),
      fatGrams: double.parse(_fat.text),
    );
  }

  static String? _validateInt(String? value, int maximum) {
    final parsed = int.tryParse(value ?? '');
    if (parsed == null || parsed < 0 || parsed > maximum) {
      return 'กรอก 0–$maximum';
    }
    return null;
  }

  static String _number(double value) => value == value.roundToDouble()
      ? value.round().toString()
      : value.toStringAsFixed(1);
}

class _NutritionFields extends StatelessWidget {
  const _NutritionFields({
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.enabled,
  });

  final TextEditingController calories;
  final TextEditingController protein;
  final TextEditingController carbs;
  final TextEditingController fat;
  final bool enabled;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final largeText = MediaQuery.textScalerOf(context).scale(1) >= 1.6;
      final fieldWidth = largeText
          ? constraints.maxWidth
          : (constraints.maxWidth - 10) / 2;
      return Wrap(
        spacing: 10,
        runSpacing: 12,
        children: [
          _NutritionField(
            fieldKey: const ValueKey('calories-field'),
            controller: calories,
            label: 'พลังงาน',
            suffix: 'kcal',
            color: AppTheme.yellow,
            enabled: enabled,
            width: fieldWidth,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            validator: (value) =>
                _FoodReviewFormState._validateInt(value, 10000),
          ),
          _NutritionField(
            fieldKey: const ValueKey('protein-field'),
            controller: protein,
            label: 'โปรตีน',
            suffix: 'กรัม',
            color: AppTheme.coralSoft,
            enabled: enabled,
            width: fieldWidth,
          ),
          _NutritionField(
            fieldKey: const ValueKey('carbs-field'),
            controller: carbs,
            label: 'คาร์บ',
            suffix: 'กรัม',
            color: AppTheme.lilac,
            enabled: enabled,
            width: fieldWidth,
          ),
          _NutritionField(
            fieldKey: const ValueKey('fat-field'),
            controller: fat,
            label: 'ไขมัน',
            suffix: 'กรัม',
            color: AppTheme.orangeSoft,
            enabled: enabled,
            width: fieldWidth,
          ),
        ],
      );
    },
  );
}

class _NutritionField extends StatelessWidget {
  const _NutritionField({
    required this.fieldKey,
    required this.controller,
    required this.label,
    required this.suffix,
    required this.color,
    required this.enabled,
    required this.width,
    this.keyboardType = const TextInputType.numberWithOptions(decimal: true),
    this.inputFormatters = const [],
    this.validator,
  });

  final Key fieldKey;
  final TextEditingController controller;
  final String label;
  final String suffix;
  final Color color;
  final bool enabled;
  final double width;
  final TextInputType keyboardType;
  final List<TextInputFormatter> inputFormatters;
  final FormFieldValidator<String>? validator;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: width,
    child: TextFormField(
      key: fieldKey,
      controller: controller,
      enabled: enabled,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters.isEmpty
          ? [
              FilteringTextInputFormatter.allow(
                RegExp(r'^\d{0,4}([.]\d{0,1})?'),
              ),
            ]
          : inputFormatters,
      decoration: InputDecoration(
        labelText: label,
        suffixText: suffix,
        filled: true,
        fillColor: color,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 14,
        ),
        border: const OutlineInputBorder(
          borderRadius: AppRadii.button,
          borderSide: BorderSide.none,
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: AppRadii.button,
          borderSide: BorderSide.none,
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: AppRadii.button,
          borderSide: BorderSide(color: AppTheme.coralActive, width: 2),
        ),
        errorBorder: const OutlineInputBorder(
          borderRadius: AppRadii.button,
          borderSide: BorderSide(color: AppTheme.error),
        ),
      ),
      validator:
          validator ??
          (value) {
            final parsed = double.tryParse(value ?? '');
            if (parsed == null ||
                !parsed.isFinite ||
                parsed < 0 ||
                parsed > 1000) {
              return 'กรอก 0–1000';
            }
            return null;
          },
    ),
  );
}

class _InlineMessage extends StatelessWidget {
  const _InlineMessage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(message),
    ),
  );
}

class _SavedCard extends StatelessWidget {
  const _SavedCard({required this.onTracking, required this.onReset});

  final VoidCallback onTracking;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) => Card(
    color: AppTheme.coralSoft,
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const Icon(Icons.check_circle, size: 48, color: AppTheme.coralActive),
          const SizedBox(height: 10),
          Text(
            'บันทึกมื้อนี้แล้ว',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: onTracking,
            child: const Text('ดูบันทึกวันนี้'),
          ),
          TextButton(onPressed: onReset, child: const Text('สแกนมื้ออื่น')),
        ],
      ),
    ),
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
