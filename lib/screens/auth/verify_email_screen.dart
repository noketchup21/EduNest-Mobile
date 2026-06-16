import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_strings.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/app_button.dart';
import '../../widgets/error_banner.dart';
import 'auth_ui.dart';

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
    final t = AppStrings.of(context, listen: false);

    try {
      await auth.verifyEmail(
        inputEmail: widget.email,
        code: code.text.trim(),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.emailVerified)),
      );

      context.go(loginRoute);
    } catch (_) {}
  }

  Future<void> _resend() async {
    final auth = context.read<AuthProvider>();
    final t = AppStrings.of(context, listen: false);

    setState(() => resendLoading = true);

    try {
      await auth.resendVerificationCode(inputEmail: widget.email);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.verificationCodeResent)),
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
    final t = context.l10n;
    final accent = authAccentForTutor(isTutor);

    return AuthScaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go(loginRoute),
        ),
        title: Text(t.verify),
      ),
      child: AuthPanel(
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AuthHeader(
                icon: Icons.mark_email_read_rounded,
                eyebrow: t.verify,
                title: t.checkYourEmail,
                color: accent,
              ),
              const SizedBox(height: 18),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: accent.withValues(alpha: 0.18)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.mail_outline_rounded, color: accent),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.email,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
              ErrorBanner(auth.error),
              const SizedBox(height: 14),
              AuthTextField(
                controller: code,
                labelText: t.verificationCode,
                hintText: t.code,
                icon: Icons.password_rounded,
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return t.verificationCodeRequired;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              AppButton(
                label: t.verify,
                icon: Icons.verified_rounded,
                loading: auth.isLoading && !resendLoading,
                onPressed: _verify,
              ),
              const SizedBox(height: 10),
              Center(
                child: TextButton.icon(
                  onPressed: resendLoading ? null : _resend,
                  icon: resendLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.refresh_rounded),
                  label: Text(t.resendCode),
                  style: TextButton.styleFrom(
                    textStyle: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
              Center(
                child: AuthLinkButton(
                  icon: Icons.arrow_back_rounded,
                  label: t.login,
                  onPressed: () => context.go(loginRoute),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
