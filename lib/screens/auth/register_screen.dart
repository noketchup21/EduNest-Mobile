import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_strings.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/app_button.dart';
import '../../widgets/error_banner.dart';
import 'auth_flow_type.dart';
import 'auth_ui.dart';

class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;

    return AuthScaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(t.signUp),
      ),
      child: Column(
        children: [
          const AuthLogoLockup(),
          const SizedBox(height: 24),
          AuthPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AuthHeader(
                  icon: Icons.auto_awesome_rounded,
                  eyebrow: t.signUp,
                  title: t.chooseYourRole,
                ),
                const SizedBox(height: 22),
                AuthChoiceCard(
                  icon: Icons.school_rounded,
                  title: t.tutor,
                  subtitle: t.teach,
                  color: authAccentForTutor(true),
                  onTap: () => context.push('/register/tutor'),
                ),
                const SizedBox(height: 12),
                AuthChoiceCard(
                  icon: Icons.groups_2_rounded,
                  title: t.parentStudent,
                  subtitle: t.learn,
                  color: authAccentForTutor(false),
                  onTap: () => context.push('/register/learner'),
                ),
                const SizedBox(height: 18),
                Center(
                  child: AuthLinkButton(
                    icon: Icons.login_rounded,
                    label: t.login,
                    onPressed: () => context.go('/login'),
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
  bool showPassword = false;

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
    final t = AppStrings.of(context, listen: false);

    try {
      await auth.register(
        name: name.text.trim(),
        inputEmail: email.text.trim(),
        password: password.text,
        role: role,
        phone: phone.text.trim(),
        bio: isTutor ? _nullableText(bio) : null,
        school:
            !isTutor && learnerRole == 'Student' ? _nullableText(school) : null,
        address:
            !isTutor && learnerRole == 'Parent' ? _nullableText(address) : null,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${_roleLabel(role, t)} ${t.verifyYourEmail}'),
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
    final t = context.l10n;
    final accent = authAccentForTutor(isTutor);

    return AuthScaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go('/register'),
        ),
        title: Text(t.signUp),
      ),
      child: AuthPanel(
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AuthHeader(
                icon: isTutor ? Icons.school_rounded : Icons.groups_2_rounded,
                eyebrow: t.authFlowTitle(widget.type.isTutor),
                title: t.createAccount,
                color: accent,
              ),
              ErrorBanner(auth.error),
              const SizedBox(height: 14),
              if (!isTutor) ...[
                Text(
                  t.registerAs,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<String>(
                    segments: [
                      ButtonSegment(
                        value: 'Parent',
                        icon: const Icon(Icons.supervisor_account_rounded),
                        label: Text(t.parent),
                      ),
                      ButtonSegment(
                        value: 'Student',
                        icon: const Icon(Icons.menu_book_rounded),
                        label: Text(t.student),
                      ),
                    ],
                    selected: {learnerRole},
                    onSelectionChanged: (value) {
                      setState(() {
                        learnerRole = value.first;
                      });
                    },
                  ),
                ),
                const SizedBox(height: 12),
              ],
              AuthTextField(
                controller: name,
                labelText: t.fullName,
                icon: Icons.badge_outlined,
                validator: _required,
              ),
              const SizedBox(height: 12),
              AuthTextField(
                controller: email,
                labelText: t.email,
                icon: Icons.alternate_email_rounded,
                keyboardType: TextInputType.emailAddress,
                validator: _emailValidator,
              ),
              const SizedBox(height: 12),
              AuthTextField(
                controller: phone,
                labelText: t.phone,
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                validator: _required,
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
                validator: _passwordValidator,
              ),
              const SizedBox(height: 12),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: isTutor
                    ? AuthTextField(
                        key: const ValueKey('bio'),
                        controller: bio,
                        labelText: t.tutorBio,
                        hintText: t.shortIntro,
                        icon: Icons.edit_note_rounded,
                        minLines: 2,
                        maxLines: 4,
                      )
                    : learnerRole == 'Student'
                        ? AuthTextField(
                            key: const ValueKey('school'),
                            controller: school,
                            labelText: t.school,
                            icon: Icons.apartment_rounded,
                          )
                        : AuthTextField(
                            key: const ValueKey('address'),
                            controller: address,
                            labelText: t.address,
                            icon: Icons.location_on_outlined,
                          ),
              ),
              const SizedBox(height: 20),
              AppButton(
                label: t.createAccount,
                icon: Icons.person_add_alt_1_rounded,
                loading: auth.isLoading,
                onPressed: _register,
              ),
              const SizedBox(height: 10),
              Center(
                child: AuthLinkButton(
                  icon: Icons.login_rounded,
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

  String? _required(String? value) {
    if (value == null || value.trim().isEmpty) {
      return AppStrings.of(context, listen: false).requiredField;
    }

    return null;
  }

  String? _emailValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return AppStrings.of(context, listen: false).emailRequired;
    }

    if (!value.contains('@')) {
      return AppStrings.of(context, listen: false).invalidEmail;
    }

    return null;
  }

  String? _passwordValidator(String? value) {
    if (value == null || value.isEmpty) {
      return AppStrings.of(context, listen: false).passwordRequired;
    }

    if (value.length < 6) {
      return AppStrings.of(context, listen: false).passwordTooShort;
    }

    return null;
  }

  String? _nullableText(TextEditingController controller) {
    final text = controller.text.trim();
    return text.isEmpty ? null : text;
  }

  String _roleLabel(String role, AppStrings t) {
    switch (role.toLowerCase()) {
      case 'tutor':
        return t.tutor;
      case 'parent':
        return t.parent;
      case 'student':
        return t.student;
      default:
        return role;
    }
  }
}
