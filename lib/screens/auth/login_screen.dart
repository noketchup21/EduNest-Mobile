import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

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
                const AuthHeader(
                  icon: Icons.waving_hand_rounded,
                  eyebrow: 'Login',
                  title: 'Welcome back',
                ),
                ErrorBanner(auth.error),
                const SizedBox(height: 22),
                AuthChoiceCard(
                  icon: Icons.school_rounded,
                  title: 'Tutor',
                  subtitle: 'Teach',
                  color: authAccentForTutor(true),
                  onTap: () => context.push('/login/tutor'),
                ),
                const SizedBox(height: 12),
                AuthChoiceCard(
                  icon: Icons.groups_2_rounded,
                  title: 'Parent / Student',
                  subtitle: 'Learn',
                  color: authAccentForTutor(false),
                  onTap: () => context.push('/login/learner'),
                ),
                const SizedBox(height: 18),
                Center(
                  child: AuthLinkButton(
                    icon: Icons.person_add_alt_1_rounded,
                    label: 'Sign up',
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
        title: const Text('Login'),
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
                eyebrow: widget.type.title,
                title: 'Login',
                color: accent,
              ),
              ErrorBanner(auth.error),
              const SizedBox(height: 14),
              AuthTextField(
                controller: email,
                labelText: 'Email',
                icon: Icons.alternate_email_rounded,
                keyboardType: TextInputType.emailAddress,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Email is required';
                  }

                  return null;
                },
              ),
              const SizedBox(height: 12),
              AuthTextField(
                controller: password,
                labelText: 'Password',
                icon: Icons.lock_outline_rounded,
                obscureText: !showPassword,
                suffixIcon: IconButton(
                  tooltip: showPassword ? 'Hide password' : 'Show password',
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
                    return 'Password is required';
                  }

                  return null;
                },
              ),
              const SizedBox(height: 20),
              AppButton(
                label: 'Login',
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
                  label: 'Sign up',
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
