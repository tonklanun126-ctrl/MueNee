import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/app_theme.dart';
import '../../app/widgets/brand_mark.dart';
import 'auth_repository.dart';

enum _Mode { signIn, register, reset }

class AccountScreen extends ConsumerStatefulWidget {
  const AccountScreen({super.key});
  @override
  ConsumerState<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends ConsumerState<AccountScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  _Mode _mode = _Mode.signIn;
  bool _busy = false;
  bool _obscure = true;
  String? _message;
  bool _error = false;
  DateTime? _verificationSent;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  void _changeMode(_Mode mode) {
    final email = _email.text;
    FocusScope.of(context).unfocus();
    setState(() {
      _mode = mode;
      _message = null;
      _password.clear();
      _confirm.clear();
      _form.currentState?.reset();
      _email.text = email;
      _obscure = true;
    });
  }

  Future<void> _run(
    Future<void> Function(AuthRepository) action, {
    String? success,
  }) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      await action(await ref.read(authRepositoryProvider.future));
      if (!mounted) return;
      _password.clear();
      _confirm.clear();
      setState(() {
        _message = success;
        _error = false;
      });
    } catch (error) {
      if (mounted) {
        setState(() {
          _message = authErrorMessage(error);
          _error = true;
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _submit() {
    if (!_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    final email = _email.text.trim();
    final password = _password.text;
    switch (_mode) {
      case _Mode.signIn:
        _run((repo) => repo.signIn(email, password));
      case _Mode.register:
        _run((repo) => repo.register(email, password));
      case _Mode.reset:
        _run(
          (repo) => repo.resetPassword(email),
          success: 'หากอีเมลนี้มีบัญชี คุณจะได้รับลิงก์รีเซ็ตรหัสผ่าน โปรดตรวจสอบกล่องจดหมายและสแปม',
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final account = ref.watch(accountProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('บัญชี MueNee')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.coralSoft,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                      children: [
                        const ExcludeSemantics(child: BrandMark(size: 64)),
                        const SizedBox(height: 16),
                        Text(
                          'ทุกมื้อ เริ่มที่คุณ',
                          style: Theme.of(context).textTheme.headlineSmall,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          account.value == null
                              ? 'เข้าสู่ระบบเพื่อจัดการบัญชีของคุณ'
                              : 'จัดการบัญชีและการยืนยันอีเมล',
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  account.when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (error, stack) => Column(
                      children: [
                        const Text('โหลดบัญชีไม่สำเร็จ กรุณาลองอีกครั้ง'),
                        TextButton(
                          onPressed: () {
                            ref.invalidate(authRepositoryProvider);
                            ref.invalidate(accountProvider);
                          },
                          child: const Text('ลองอีกครั้ง'),
                        ),
                      ],
                    ),
                    data: (user) =>
                        user == null ? _credentials() : _signedIn(user),
                  ),
                  if (_busy)
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  if (_message != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Semantics(
                        liveRegion: true,
                        child: Text(
                          _message!,
                          style: TextStyle(
                            color: _error
                                ? Theme.of(context).colorScheme.error
                                : null,
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                  const Text(
                    'โปรไฟล์และการตั้งค่าอาหารยังเก็บบนอุปกรณ์นี้ และใช้ร่วมกันบนเครื่อง แม้สลับบัญชี',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _signedIn(Account user) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text('ยินดีต้อนรับ', style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 8),
      Text(user.email),
      const SizedBox(height: 16),
      Text(user.verified ? 'ยืนยันอีเมลแล้ว' : 'ยังไม่ได้ยืนยันอีเมล'),
      if (!user.verified) ...[
        const SizedBox(height: 12),
        FilledButton(
          onPressed: _busy
              ? null
              : () {
                  if (_verificationSent != null &&
                      DateTime.now().difference(_verificationSent!).inSeconds <
                          60) {
                    setState(() {
                      _message = 'กรุณารอ 1 นาทีก่อนส่งอีกครั้ง';
                      _error = false;
                    });
                    return;
                  }
                  _run((repo) async {
                    await repo.verifyEmail();
                    _verificationSent = DateTime.now();
                  }, success: 'ส่งลิงก์แล้ว โปรดเปิดอีเมลเพื่อยืนยันบัญชี');
                },
          child: const Text('ส่งอีเมลยืนยัน'),
        ),
        TextButton(
          onPressed: _busy ? null : () => _run((repo) => repo.reload()),
          child: const Text('ยืนยันแล้ว ตรวจสอบอีกครั้ง'),
        ),
      ],
      const SizedBox(height: 16),
      OutlinedButton(
        onPressed: _busy
            ? null
            : () => _run((repo) async {
                await repo.signOut();
                _verificationSent = null;
                _mode = _Mode.signIn;
                _obscure = true;
              }),
        child: const Text('ออกจากระบบ'),
      ),
    ],
  );

  Widget _credentials() {
    final title = switch (_mode) {
      _Mode.signIn => 'เข้าสู่ระบบ',
      _Mode.register => 'สร้างบัญชี',
      _Mode.reset => 'รีเซ็ตรหัสผ่าน',
    };
    return AutofillGroup(
      child: Form(
        key: _form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 20),
            TextFormField(
              controller: _email,
              enabled: !_busy,
              keyboardType: TextInputType.emailAddress,
              textInputAction: _mode == _Mode.reset
                  ? TextInputAction.done
                  : TextInputAction.next,
              onFieldSubmitted: (_) {
                if (_mode == _Mode.reset && !_busy) _submit();
              },
              autofillHints: const [AutofillHints.email],
              autocorrect: false,
              decoration: const InputDecoration(
                errorMaxLines: 3,
                labelText: 'อีเมล',
                prefixIcon: Icon(Icons.mail_outline),
              ),
              validator: (value) =>
                  RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
                      .hasMatch(value?.trim() ?? '')
                  ? null
                  : 'กรุณากรอกอีเมลให้ถูกต้อง',
            ),
            if (_mode != _Mode.reset) ...[
              const SizedBox(height: 16),
              TextFormField(
                controller: _password,
                enabled: !_busy,
                obscureText: _obscure,
                autocorrect: false,
                enableSuggestions: false,
                textInputAction: _mode == _Mode.register
                    ? TextInputAction.next
                    : TextInputAction.done,
                onFieldSubmitted: (_) {
                  if (_mode == _Mode.signIn && !_busy) _submit();
                },
                autofillHints: [
                  _mode == _Mode.register
                      ? AutofillHints.newPassword
                      : AutofillHints.password,
                ],
                decoration: InputDecoration(
                  errorMaxLines: 3,
                  helperMaxLines: 3,
                  labelText: 'รหัสผ่าน',
                  helperText: _mode == _Mode.register
                      ? 'อย่างน้อย 8 ตัวอักษร'
                      : null,
                  suffixIcon: IconButton(
                    tooltip: _obscure ? 'แสดงรหัสผ่าน' : 'ซ่อนรหัสผ่าน',
                    onPressed: _busy
                        ? null
                        : () => setState(() => _obscure = !_obscure),
                    icon: Icon(
                      _obscure
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                  ),
                ),
                validator: (value) => (value ?? '').isEmpty
                    ? 'กรุณากรอกรหัสผ่าน'
                    : _mode == _Mode.register && value!.length < 8
                    ? 'ใช้รหัสผ่านอย่างน้อย 8 ตัวอักษร'
                    : null,
              ),
            ],
            if (_mode == _Mode.register) ...[
              const SizedBox(height: 16),
              TextFormField(
                controller: _confirm,
                enabled: !_busy,
                obscureText: true,
                autocorrect: false,
                enableSuggestions: false,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) {
                  if (!_busy) _submit();
                },
                decoration: const InputDecoration(
                  labelText: 'ยืนยันรหัสผ่าน',
                  errorMaxLines: 3,
                ),
                validator: (value) =>
                    value == _password.text ? null : 'รหัสผ่านไม่ตรงกัน',
              ),
            ],
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _busy ? null : _submit,
              child: Text(_mode == _Mode.reset ? 'ส่งลิงก์รีเซ็ต' : title),
            ),
            if (_mode == _Mode.signIn)
              TextButton(
                onPressed: _busy ? null : () => _changeMode(_Mode.reset),
                child: const Text('ลืมรหัสผ่าน?'),
              ),
            TextButton(
              onPressed: _busy
                  ? null
                  : () => _changeMode(
                      _mode == _Mode.signIn ? _Mode.register : _Mode.signIn,
                    ),
              child: Text(
                _mode == _Mode.signIn
                    ? 'ยังไม่มีบัญชี? สร้างบัญชี'
                    : 'กลับไปเข้าสู่ระบบ',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
