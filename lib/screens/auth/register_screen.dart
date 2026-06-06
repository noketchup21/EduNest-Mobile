import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../widgets/app_button.dart';
import '../../widgets/error_banner.dart';
import 'auth_flow_type.dart';

class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create account'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Column(
                  children: [
                    Image.asset(
                      'assets/images/Logo.png',
                      height: 100,
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.school, size: 80, color: Colors.blue),
                    ),
                    const SizedBox(height: 12),
                    Image.asset(
                      'assets/images/Chữ Logo.png',
                      height: 40,
                      errorBuilder: (context, error, stackTrace) => Text(
                        'EduNest',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'Register as',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Choose the account type you want to create.',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 24),

              _RegisterChoiceCard(
                icon: Icons.school,
                title: 'Tutor',
                subtitle: 'Create courses, teach lessons, and receive payouts.',
                onTap: () => context.push('/register/tutor'),
              ),

              const SizedBox(height: 12),

              _RegisterChoiceCard(
                icon: Icons.family_restroom,
                title: 'Parent / Student',
                subtitle: 'Book courses, pay with QR, and join lessons.',
                onTap: () => context.push('/register/learner'),
              ),

              const SizedBox(height: 16),

              Center(
                child: TextButton(
                  onPressed: () => context.go('/login'),
                  child: const Text('Already have an account? Login'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class RoleRegisterScreen extends StatefulWidget {
  final AuthFlowType type;

  const RoleRegisterScreen({
    super.key,
    required this.type,
  });

  @override
  State<RoleRegisterScreen> createState() => _RoleRegisterScreenState();
}

class _RoleRegisterScreenState extends State<RoleRegisterScreen> {
  final formKey = GlobalKey<FormState>();

  final name = TextEditingController();
  final email = TextEditingController();
  final phone = TextEditingController();
  final password = TextEditingController();

  final bio = TextEditingController();
  final school = TextEditingController();
  final address = TextEditingController();

  String learnerRole = 'Parent';

  bool get isTutor => widget.type.isTutor;

  String get role => isTutor ? 'Tutor' : learnerRole;

  String get loginRoute => isTutor ? '/login/tutor' : '/login/learner';

  @override
  void dispose() {
    name.dispose();
    email.dispose();
    phone.dispose();
    password.dispose();
    bio.dispose();
    school.dispose();
    address.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();

    try {
      await auth.register(
        name: name.text.trim(),
        inputEmail: email.text.trim(),
        password: password.text,
        role: role,
        phone: phone.text.trim(),
        bio: isTutor ? _nullableText(bio) : null,
        school: !isTutor && learnerRole == 'Student'
            ? _nullableText(school)
            : null,
        address: !isTutor && learnerRole == 'Parent'
            ? _nullableText(address)
            : null,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$role registered. Please verify your email.'),
        ),
      );

      final encodedEmail = Uri.encodeComponent(email.text.trim());
      final type = isTutor ? 'tutor' : 'learner';

      context.go('/verify-email?email=$encodedEmail&type=$type');
    } catch (_) {
      // AuthProvider already stores error.
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/register'),
        ),
        title: Text('${widget.type.title} register'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Create ${widget.type.title} account',
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

                if (!isTutor) ...[
                  DropdownButtonFormField<String>(
                    value: learnerRole,
                    decoration: const InputDecoration(
                      labelText: 'Register as',
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'Parent',
                        child: Text('Parent'),
                      ),
                      DropdownMenuItem(
                        value: 'Student',
                        child: Text('Student'),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        learnerRole = value ?? 'Parent';
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                ],

                TextFormField(
                  controller: name,
                  decoration: const InputDecoration(
                    labelText: 'Full name',
                  ),
                  validator: _required,
                ),

                const SizedBox(height: 12),

                TextFormField(
                  controller: email,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: _emailValidator,
                ),

                const SizedBox(height: 12),

                TextFormField(
                  controller: phone,
                  decoration: const InputDecoration(
                    labelText: 'Phone',
                  ),
                  keyboardType: TextInputType.phone,
                  validator: _required,
                ),

                const SizedBox(height: 12),

                TextFormField(
                  controller: password,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                  ),
                  obscureText: true,
                  validator: _passwordValidator,
                ),

                const SizedBox(height: 12),

                if (isTutor) ...[
                  TextFormField(
                    controller: bio,
                    decoration: const InputDecoration(
                      labelText: 'Tutor bio',
                      hintText: 'Example: Math tutor with 2 years experience',
                    ),
                    minLines: 2,
                    maxLines: 4,
                  ),
                ] else if (learnerRole == 'Student') ...[
                  TextFormField(
                    controller: school,
                    decoration: const InputDecoration(
                      labelText: 'School',
                    ),
                  ),
                ] else ...[
                  TextFormField(
                    controller: address,
                    decoration: const InputDecoration(
                      labelText: 'Address',
                    ),
                  ),
                ],

                const SizedBox(height: 20),

                AppButton(
                  label: 'Create $role account',
                  loading: auth.isLoading,
                  onPressed: _register,
                ),

                const SizedBox(height: 8),

                Center(
                  child: TextButton(
                    onPressed: () => context.go(loginRoute),
                    child: const Text('Already have an account? Login'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String? _required(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Required';
    }

    return null;
  }

  String? _emailValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }

    if (!value.contains('@')) {
      return 'Invalid email';
    }

    return null;
  }

  String? _passwordValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }

    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }

    return null;
  }

  String? _nullableText(TextEditingController controller) {
    final text = controller.text.trim();
    return text.isEmpty ? null : text;
  }
}

class _RegisterChoiceCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _RegisterChoiceCard({
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