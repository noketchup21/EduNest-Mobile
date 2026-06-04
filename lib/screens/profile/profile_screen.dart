import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/mvp_models.dart';
import '../../providers/app_data_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/error_banner.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final profileFormKey = GlobalKey<FormState>();
  final bankFormKey = GlobalKey<FormState>();

  final name = TextEditingController();
  final phone = TextEditingController();
  final tutorBio = TextEditingController();

  final bankName = TextEditingController();
  final bankBin = TextEditingController();
  final accountNumber = TextEditingController();
  final accountHolderName = TextEditingController();
  final branchName = TextEditingController();

  bool initialized = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppDataProvider>().loadProfile();
    });
  }

  @override
  void dispose() {
    name.dispose();
    phone.dispose();
    tutorBio.dispose();

    bankName.dispose();
    bankBin.dispose();
    accountNumber.dispose();
    accountHolderName.dispose();
    branchName.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = context.watch<AppDataProvider>();
    final auth = context.watch<AuthProvider>();
    final profile = data.profile;

    _fillOnce(profile);

    final isTutor = auth.isTutor || profile?.role == 'Tutor';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            onPressed: data.loading
                ? null
                : () async {
              setState(() => initialized = false);
              await context.read<AppDataProvider>().loadProfile();
            },
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: data.loadProfile,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            ErrorBanner(data.error),

            if (data.loading && profile == null)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              )
            else ...[
              _HeaderCard(profile: profile, auth: auth),
              const SizedBox(height: 12),
              _ProfileForm(
                formKey: profileFormKey,
                profile: profile,
                isTutor: isTutor,
                name: name,
                phone: phone,
                tutorBio: tutorBio,
                loading: data.loading,
                onSave: _saveProfile,
              ),
              if (isTutor) ...[
                const SizedBox(height: 12),
                _BankForm(
                  formKey: bankFormKey,
                  bankName: bankName,
                  bankBin: bankBin,
                  accountNumber: accountNumber,
                  accountHolderName: accountHolderName,
                  branchName: branchName,
                  loading: data.loading,
                  onSave: _saveBank,
                ),
              ],
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: () async {
                  await context.read<AuthProvider>().logout();

                  if (!context.mounted) return;

                  context.go('/login');
                },
                icon: const Icon(Icons.logout),
                label: const Text('Logout'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _fillOnce(ProfileModel? profile) {
    if (initialized || profile == null) return;

    name.text = profile.name;
    phone.text = profile.phone ?? '';
    tutorBio.text = profile.tutorBio ?? '';

    bankName.text = profile.bankName ?? '';
    bankBin.text = profile.bankBin ?? '';
    accountNumber.text = profile.accountNumber ?? '';
    accountHolderName.text = profile.accountHolderName ?? '';
    branchName.text = profile.branchName ?? '';

    initialized = true;
  }

  Future<void> _saveProfile() async {
    if (!profileFormKey.currentState!.validate()) return;

    try {
      await context.read<AppDataProvider>().updateProfile(
        name: name.text.trim(),
        phone: phone.text.trim(),
        tutorBio: tutorBio.text.trim(),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated')),
      );
    } catch (_) {}
  }

  Future<void> _saveBank() async {
    if (!bankFormKey.currentState!.validate()) return;

    try {
      await context.read<AppDataProvider>().updateTutorBankAccount(
        bankName: bankName.text.trim(),
        bankBin: bankBin.text.trim(),
        accountNumber: accountNumber.text.trim(),
        accountHolderName: accountHolderName.text.trim(),
        branchName: branchName.text.trim(),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bank account updated')),
      );
    } catch (_) {}
  }
}

class _HeaderCard extends StatelessWidget {
  final ProfileModel? profile;
  final AuthProvider auth;

  const _HeaderCard({
    required this.profile,
    required this.auth,
  });

  @override
  Widget build(BuildContext context) {
    final displayName = profile?.name ?? auth.email ?? 'User';
    final role = profile?.role ?? auth.role ?? '';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            CircleAvatar(
              radius: 36,
              child: Text(
                displayName.isEmpty ? '?' : displayName[0].toUpperCase(),
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 28,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              displayName,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 4),
            Text(profile?.email ?? auth.email ?? ''),
            const SizedBox(height: 8),
            Chip(label: Text(role.isEmpty ? 'User' : role)),
            if (profile?.role == 'Tutor') ...[
              const SizedBox(height: 8),
              Text(
                'Verification: ${profile?.verificationStatus ?? 'NotSubmitted'}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ProfileForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final ProfileModel? profile;
  final bool isTutor;
  final TextEditingController name;
  final TextEditingController phone;
  final TextEditingController tutorBio;
  final bool loading;
  final VoidCallback onSave;

  const _ProfileForm({
    required this.formKey,
    required this.profile,
    required this.isTutor,
    required this.name,
    required this.phone,
    required this.tutorBio,
    required this.loading,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: formKey,
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Personal information',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                initialValue: profile?.email ?? '',
                enabled: false,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: name,
                decoration: const InputDecoration(
                  labelText: 'Full name',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: _required,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: phone,
                decoration: const InputDecoration(
                  labelText: 'Phone',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
                keyboardType: TextInputType.phone,
              ),
              if (isTutor) ...[
                const SizedBox(height: 12),
                TextFormField(
                  controller: tutorBio,
                  decoration: const InputDecoration(
                    labelText: 'Tutor bio',
                    prefixIcon: Icon(Icons.description_outlined),
                  ),
                  minLines: 3,
                  maxLines: 5,
                ),
              ],
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: loading ? null : onSave,
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('Save profile'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BankForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController bankName;
  final TextEditingController bankBin;
  final TextEditingController accountNumber;
  final TextEditingController accountHolderName;
  final TextEditingController branchName;
  final bool loading;
  final VoidCallback onSave;

  const _BankForm({
    required this.formKey,
    required this.bankName,
    required this.bankBin,
    required this.accountNumber,
    required this.accountHolderName,
    required this.branchName,
    required this.loading,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: formKey,
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Tutor bank account',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Bank BIN is optional. Enter it to enable quick payout QR for admin transfer.',
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: bankName,
                decoration: const InputDecoration(
                  labelText: 'Bank name',
                  prefixIcon: Icon(Icons.account_balance_outlined),
                ),
                validator: _required,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: bankBin,
                decoration: const InputDecoration(
                  labelText: 'Bank BIN optional',
                  hintText: 'Example: 970422',
                  prefixIcon: Icon(Icons.qr_code_2_outlined),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: accountNumber,
                decoration: const InputDecoration(
                  labelText: 'Account number',
                  prefixIcon: Icon(Icons.numbers_outlined),
                ),
                keyboardType: TextInputType.number,
                validator: _required,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: accountHolderName,
                decoration: const InputDecoration(
                  labelText: 'Account holder name',
                  prefixIcon: Icon(Icons.person_pin_outlined),
                ),
                validator: _required,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: branchName,
                decoration: const InputDecoration(
                  labelText: 'Branch name optional',
                  prefixIcon: Icon(Icons.location_city_outlined),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: loading ? null : onSave,
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('Save bank account'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String? _required(String? value) {
  if (value == null || value.trim().isEmpty) {
    return 'This field is required';
  }

  return null;
}