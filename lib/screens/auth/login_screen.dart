import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_strings.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/app_button.dart';
import '../../widgets/error_banner.dart';
import 'auth_flow_type.dart';
import 'auth_ui.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final t = context.l10n;

    _showAuthMessageIfNeeded(context, auth);

    return AuthScaffold(
      child: Column(
        children: [
          const AuthLogoLockup(),
          const SizedBox(height: 24),
          AuthPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AuthHeader(
                  icon: Icons.waving_hand_rounded,
                  eyebrow: t.login,
                  title: t.welcomeBack,
                ),
                ErrorBanner(auth.error),
                const SizedBox(height: 22),
                AuthChoiceCard(
                  icon: Icons.school_rounded,
                  title: t.tutor,
                  subtitle: t.teach,
                  color: authAccentForTutor(true),
                  onTap: () => context.push('/login/tutor'),
                ),
                const SizedBox(height: 12),
                AuthChoiceCard(
                  icon: Icons.groups_2_rounded,
                  title: t.parentStudent,
                  subtitle: t.learn,
                  color: authAccentForTutor(false),
                  onTap: () => context.push('/login/learner'),
                ),
                const SizedBox(height: 18),
                Center(
                  child: AuthLinkButton(
                    icon: Icons.person_add_alt_1_rounded,
                    label: t.signUp,
                    onPressed: () => context.go('/register'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class RoleLoginScreen extends StatefulWidget {
  final AuthFlowType type;

  const RoleLoginScreen({
    super.key,
    required this.type,
  });

  @override
  State<RoleLoginScreen> createState() => _RoleLoginScreenState();
}

class _RoleLoginScreenState extends State<RoleLoginScreen> {
  final email = TextEditingController();
  final password = TextEditingController();
  final formKey = GlobalKey<FormState>();
  bool showPassword = false;

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final t = context.l10n;
    final accent = authAccentForTutor(widget.type.isTutor);

    _showAuthMessageIfNeeded(context, auth);

    return AuthScaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go('/login'),
        ),
        title: Text(t.login),
      ),
      child: AuthPanel(
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AuthHeader(
                icon: widget.type.isTutor
                    ? Icons.school_rounded
                    : Icons.groups_2_rounded,
                eyebrow: t.authFlowTitle(widget.type.isTutor),
                title: t.login,
                color: accent,
              ),
              ErrorBanner(auth.error),
              const SizedBox(height: 14),
              AuthTextField(
                controller: email,
                labelText: t.email,
                icon: Icons.alternate_email_rounded,
                keyboardType: TextInputType.emailAddress,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return t.emailRequired;
                  }

                  return null;
                },
              ),
              const SizedBox(height: 12),
              AuthTextField(
                controller: password,
                labelText: t.password,
                icon: Icons.lock_outline_rounded,
                obscureText: !showPassword,
                suffixIcon: IconButton(
                  tooltip: showPassword ? t.hidePassword : t.showPassword,
                  icon: Icon(
                    showPassword
                        ? Icons.visibility_off_rounded
                        : Icons.visibility_rounded,
                  ),
                  onPressed: () {
                    setState(() => showPassword = !showPassword);
                  },
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) {
                    return t.passwordRequired;
                  }

                  return null;
                },
              ),
              const SizedBox(height: 20),
              AppButton(
                label: t.login,
                icon: Icons.login_rounded,
                loading: auth.isLoading,
                onPressed: () async {
                  if (!formKey.currentState!.validate()) return;

                  try {
                    await auth.login(
                      email.text.trim(),
                      password.text,
                      allowedRoles: widget.type.allowedRoles,
                    );

                    if (!context.mounted) return;

                    if (auth.isAdmin) {
                      context.go('/admin');
                    } else if (auth.isTutor) {
                      context.go('/tutor-verification');
                    } else {
                      context.go('/home');
                    }
                  } catch (_) {}
                },
              ),
              const SizedBox(height: 10),
              Center(
                child: AuthLinkButton(
                  icon: Icons.person_add_alt_1_rounded,
                  label: t.signUp,
                  onPressed: () {
                    if (widget.type.isTutor) {
                      context.go('/register/tutor');
                    } else {
                      context.go('/register/learner');
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void _showAuthMessageIfNeeded(BuildContext context, AuthProvider auth) {
  final message = auth.authMessage;

  if (message == null || message.trim().isEmpty) {
    return;
  }

  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );

    context.read<AuthProvider>().clearAuthMessage();
  });
}
