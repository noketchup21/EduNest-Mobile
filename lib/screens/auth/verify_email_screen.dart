import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../widgets/app_button.dart';
import '../../widgets/error_banner.dart';

class VerifyEmailScreen extends StatefulWidget {
  final String email;
  final String type;

  const VerifyEmailScreen({
    super.key,
    required this.email,
    required this.type,
  });

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  final code = TextEditingController();
  final formKey = GlobalKey<FormState>();

  bool resendLoading = false;

  bool get isTutor => widget.type.toLowerCase() == 'tutor';

  String get loginRoute => isTutor ? '/login/tutor' : '/login/learner';

  @override
  void dispose() {
    code.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    if (!formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();

    try {
      await auth.verifyEmail(
        inputEmail: widget.email,
        code: code.text.trim(),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email verified successfully. Please login.')),
      );

      context.go(loginRoute);
    } catch (_) {}
  }

  Future<void> _resend() async {
    final auth = context.read<AuthProvider>();

    setState(() => resendLoading = true);

    try {
      await auth.resendVerificationCode(inputEmail: widget.email);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Verification code resent. Check your email.')),
      );
    } catch (_) {
      // AuthProvider already stores error.
    } finally {
      if (mounted) setState(() => resendLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(loginRoute),
        ),
        title: const Text('Verify email'),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Enter verification code',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'We sent a verification code to:',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.email,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ErrorBanner(auth.error),
                  TextFormField(
                    controller: code,
                    decoration: const InputDecoration(
                      labelText: 'Verification code',
                      hintText: 'Enter code from email',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Verification code is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  AppButton(
                    label: 'Verify email',
                    loading: auth.isLoading && !resendLoading,
                    onPressed: _verify,
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: TextButton.icon(
                      onPressed: resendLoading ? null : _resend,
                      icon: resendLoading
                          ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                          : const Icon(Icons.refresh),
                      label: const Text('Resend verification code'),
                    ),
                  ),
                  Center(
                    child: TextButton(
                      onPressed: () => context.go(loginRoute),
                      child: const Text('Back to login'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}