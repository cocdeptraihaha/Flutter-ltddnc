import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/api_client.dart';
import '../providers/auth_providers.dart';
import '../features/admin/presentation/admin_shell_screen.dart';
import 'not_authorized_screen.dart';

/// OTP kích hoạt tài khoản (6 số, hết hạn 90s theo backend mặc định).
class VerifyOtpScreen extends ConsumerStatefulWidget {
  const VerifyOtpScreen({super.key, required this.email});

  final String email;

  @override
  ConsumerState<VerifyOtpScreen> createState() => _VerifyOtpScreenState();
}

class _VerifyOtpScreenState extends ConsumerState<VerifyOtpScreen> {
  static const int _otpExpireSeconds = 90;

  final _otpController = TextEditingController();
  Timer? _tick;
  int _secondsLeft = _otpExpireSeconds;
  bool _submitting = false;
  bool _resending = false;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() {
    _tick?.cancel();
    setState(() => _secondsLeft = _otpExpireSeconds);
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (_secondsLeft <= 1) {
        _tick?.cancel();
        setState(() => _secondsLeft = 0);
        return;
      }
      setState(() => _secondsLeft--);
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _resend() async {
    if (_secondsLeft > 0) return;
    setState(() => _resending = true);
    try {
      await ref.read(authServiceProvider).resendOtp(widget.email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã gửi lại mã OTP (nếu tài khoản chưa kích hoạt).')),
      );
      _startCountdown();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(dioErrorMessage(e))),
      );
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  Future<void> _verify() async {
    final code = _otpController.text.trim();
    if (code.length != 6 || int.tryParse(code) == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nhập mã OTP 6 chữ số')),
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      final result = await ref
          .read(authNotifierProvider.notifier)
          .verifyActivation(widget.email, code);
      if (!mounted) return;
      switch (result) {
        case AuthActionAdminOk():
          await Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute<void>(builder: (_) => const AdminShellScreen()),
            (_) => false,
          );
        case AuthActionBlockedUser():
          await Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute<void>(builder: (_) => const NotAuthorizedScreen()),
            (_) => false,
          );
        case AuthActionFailed(:final message):
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message)),
          );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Xác nhận OTP')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Mã OTP đã gửi tới:',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 4),
            Text(
              widget.email,
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _otpController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
              ],
              decoration: const InputDecoration(
                labelText: 'Mã OTP (6 số)',
                counterText: '',
                prefixIcon: Icon(Icons.pin_outlined),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _secondsLeft > 0
                  ? 'Mã hết hạn sau: $_secondsLeft giây'
                  : 'Mã đã hết hạn — có thể gửi lại',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _submitting ? null : _verify,
              child: _submitting
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Xác nhận'),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: (_secondsLeft > 0 || _resending) ? null : _resend,
              child: _resending
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Gửi lại OTP'),
            ),
          ],
        ),
      ),
    );
  }
}
