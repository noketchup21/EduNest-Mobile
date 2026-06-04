import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../widgets/app_button.dart';
import '../../widgets/error_banner.dart';
import 'auth_flow_type.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    _showAuthMessageIfNeeded(context, auth);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome back',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Choose your account type to continue.',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                ErrorBanner(auth.error),
                const SizedBox(height: 24),
                _AuthChoiceCard(
                  icon: Icons.school,
                  title: 'Tutor login',
                  subtitle:
                  'Create courses, manage lessons, wallet, and payouts.',
                  onTap: () => context.push('/login/tutor'),
                ),
                const SizedBox(height: 12),
                _AuthChoiceCard(
                  icon: Icons.family_restroom,
                  title: 'Parent / Student login',
                  subtitle: 'Book tutors, pay by QR, view lessons, and chat.',
                  onTap: () => context.push('/login/learner'),
                ),
                const SizedBox(height: 16),
                Center(
                  child: TextButton(
                    onPressed: () => context.go('/register'),
                    child: const Text('Create an account'),
                  ),
                ),
              ],
            ),
          ),
        ),
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

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    _showAuthMessageIfNeeded(context, auth);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/login'),
        ),
        title: Text('${widget.type.title} login'),
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
                    '${widget.type.title} account',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.type.subtitle,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  ErrorBanner(auth.error),
                  TextFormField(
                    controller: email,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Email is required';
                      }

                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: password,
                    decoration: const InputDecoration(
                      labelText: 'Password',
                    ),
                    obscureText: true,
                    validator: (v) {
                      if (v == null || v.isEmpty) {
                        return 'Password is required';
                      }

                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  AppButton(
                    label: 'Login as ${widget.type.title}',
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
                  const SizedBox(height: 8),
                  Center(
                    child: TextButton(
                      onPressed: () {
                        if (widget.type.isTutor) {
                          context.go('/register/tutor');
                        } else {
                          context.go('/register/learner');
                        }
                      },
                      child: const Text('Create an account'),
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

class _AuthChoiceCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _AuthChoiceCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              CircleAvatar(
                radius: 26,
                child: Icon(icon),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style:
                      Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(subtitle),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
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