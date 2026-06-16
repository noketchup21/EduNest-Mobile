import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_strings.dart';
import '../../models/mvp_models.dart';
import '../../providers/app_data_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/bank_bin_field.dart';
import '../../widgets/error_banner.dart';
import '../../widgets/language_switcher.dart';

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
    final theme = Theme.of(context);
    final t = context.l10n;
    _fillOnce(profile);
    final isTutor = auth.isTutor || profile?.role == 'Tutor';

    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerLow,
      appBar: AppBar(
        title: Text(
          t.personalProfile,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
        elevation: 0,
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            onPressed: data.loading
                ? null
                : () async {
                    setState(() => initialized = false);
                    await context.read<AppDataProvider>().loadProfile();
                  },
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: data.loadProfile,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          children: [
            ErrorBanner(data.error),
            if (data.loading && profile == null)
              const Padding(
                padding: EdgeInsets.all(48),
                child: Center(child: CircularProgressIndicator()),
              )
            else ...[
              _HeaderCard(
                profile: profile,
                auth: auth,
                loading: data.loading,
                onUploadAvatar: _pickAndUploadAvatar,
                onDeleteAvatar: _deleteAvatar,
              ),
              const SizedBox(height: 20),
              const _LanguagePreferenceCard(),
              const SizedBox(height: 20),
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
                const SizedBox(height: 20),
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
              _LegalAndReportsCard(isTutor: isTutor),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: theme.colorScheme.error,
                    side: BorderSide(
                      color: theme.colorScheme.error.withOpacity(0.5),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () async {
                    await context.read<AuthProvider>().logout();
                    if (!context.mounted) return;
                    context.go('/login');
                  },
                  icon: const Icon(Icons.logout_rounded),
                  label: Text(
                    t.logOut,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
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
      final t = AppStrings.of(context, listen: false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.profileUpdated)),
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
      final t = AppStrings.of(context, listen: false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.bankAccountUpdated)),
      );
    } catch (_) {}
  }

  Future<void> _pickAndUploadAvatar() async {
    final data = context.read<AppDataProvider>();
    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 900,
      );
      if (picked == null) return;
      await data.uploadAvatar(picked.path);
      if (!mounted) return;
      final t = AppStrings.of(context, listen: false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.avatarUpdated)),
      );
    } catch (e) {
      if (!mounted) return;
      final t = AppStrings.of(context, listen: false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.couldNotUploadAvatar(e))),
      );
    }
  }

  Future<void> _deleteAvatar() async {
    final data = context.read<AppDataProvider>();
    final profile = data.profile;
    final avatarUrl = profile?.avatarUrl?.trim() ?? '';
    if (avatarUrl.isEmpty) {
      final t = AppStrings.of(context, listen: false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.noAvatarToDelete)),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final t = AppStrings.of(dialogContext, listen: false);
        return AlertDialog(
          title: Text(t.deleteAvatarTitle),
          content: Text(t.deleteAvatarMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(t.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(t.delete),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;
    try {
      await data.deleteAvatar();
      if (!mounted) return;
      final t = AppStrings.of(context, listen: false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.avatarDeleted)),
      );
    } catch (_) {}
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Header Card
// ─────────────────────────────────────────────────────────────────────────────

class _LanguagePreferenceCard extends StatelessWidget {
  const _LanguagePreferenceCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = context.l10n;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t.languagePreference,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            t.chooseAppLanguage,
            style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 14),
          const LanguageSwitcher(showLabel: true),
        ],
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  final ProfileModel? profile;
  final AuthProvider auth;
  final bool loading;
  final VoidCallback onUploadAvatar;
  final VoidCallback onDeleteAvatar;

  const _HeaderCard({
    required this.profile,
    required this.auth,
    required this.loading,
    required this.onUploadAvatar,
    required this.onDeleteAvatar,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displayName = profile?.name ?? auth.email ?? 'User';
    final role = profile?.role ?? auth.role ?? '';
    final avatarUrl = profile?.avatarUrl?.trim() ?? '';
    final hasAvatar = avatarUrl.isNotEmpty;
    final t = context.l10n;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: theme.colorScheme.primary.withOpacity(0.2),
                    width: 4,
                  ),
                ),
                child: CircleAvatar(
                  radius: 44,
                  backgroundColor: theme.colorScheme.primaryContainer,
                  backgroundImage: hasAvatar ? NetworkImage(avatarUrl) : null,
                  child: hasAvatar
                      ? null
                      : Text(
                          displayName.isEmpty
                              ? '?'
                              : displayName[0].toUpperCase(),
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 32,
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                        ),
                ),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: PopupMenuButton<String>(
                  enabled: !loading,
                  onSelected: (value) {
                    if (value == 'upload') onUploadAvatar();
                    if (value == 'delete') onDeleteAvatar();
                  },
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      value: 'upload',
                      child: Row(
                        children: [
                          const Icon(Icons.upload_outlined),
                          const SizedBox(width: 10),
                          Text(t.uploadUpdateAvatar),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      enabled: hasAvatar,
                      child: Row(
                        children: [
                          const Icon(Icons.delete_outline),
                          const SizedBox(width: 10),
                          Text(t.deleteAvatar),
                        ],
                      ),
                    ),
                  ],
                  child: CircleAvatar(
                    radius: 16,
                    backgroundColor: theme.colorScheme.primary,
                    child: loading
                        ? SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: theme.colorScheme.onPrimary,
                            ),
                          )
                        : Icon(
                            Icons.camera_alt_outlined,
                            size: 17,
                            color: theme.colorScheme.onPrimary,
                          ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            displayName,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            profile?.email ?? auth.email ?? '',
            style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 12),
          Chip(
            label: Text(
              t.role(role),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
            backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
            side: BorderSide.none,
            labelStyle: TextStyle(color: theme.colorScheme.primary),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
          ),
          if (profile?.role == 'Tutor') ...[
            const SizedBox(height: 8),
            _buildVerificationBadge(context, profile?.verificationStatus),
          ],
        ],
      ),
    );
  }

  Widget _buildVerificationBadge(BuildContext context, String? status) {
    final norm = (status ?? 'NotSubmitted').toLowerCase();
    Color baseColor = Colors.orange;
    String text = 'Not Submitted';
    if (norm == 'verified' || norm == 'approved') {
      baseColor = Colors.green;
      text = 'Verified';
    } else if (norm == 'pending') {
      baseColor = Colors.blue;
      text = 'Pending Review';
    } else if (norm == 'rejected' || norm == 'failed') {
      baseColor = Colors.red;
      text = 'Rejected';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: baseColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: baseColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: baseColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Profile Form
// ─────────────────────────────────────────────────────────────────────────────

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
    final theme = Theme.of(context);
    final t = context.l10n;

    InputDecoration inputStyle(
      String label,
      IconData icon, {
      bool enabled = true,
    }) {
      return InputDecoration(
        labelText: label,
        prefixIcon: Icon(
          icon,
          color: enabled ? theme.colorScheme.primary : Colors.grey,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        filled: true,
        fillColor: enabled
            ? theme.colorScheme.surfaceContainerHighest.withOpacity(0.2)
            : theme.colorScheme.surfaceContainerHighest.withOpacity(0.6),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
      ),
      padding: const EdgeInsets.all(20),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.person_pin_rounded,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  t.personalInformation,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            TextFormField(
              initialValue: profile?.email ?? '',
              enabled: false,
              decoration: inputStyle(
                t.emailAddress,
                Icons.email_outlined,
                enabled: false,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: name,
              decoration: inputStyle(t.fullName, Icons.person_outline),
              validator: (value) => _required(context, value),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: phone,
              decoration: inputStyle(t.phoneNumber, Icons.phone_outlined),
              keyboardType: TextInputType.phone,
            ),
            if (isTutor) ...[
              const SizedBox(height: 16),
              TextFormField(
                controller: tutorBio,
                decoration: inputStyle(
                  t.biographyTutor,
                  Icons.description_outlined,
                ),
                minLines: 3,
                maxLines: 5,
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: loading ? null : onSave,
                icon: const Icon(Icons.save_rounded),
                label: Text(
                  t.saveChanges,
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Bank Form
// ─────────────────────────────────────────────────────────────────────────────

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
    final theme = Theme.of(context);
    final t = context.l10n;

    InputDecoration inputStyle(
      String label,
      IconData icon, {
      String? hint,
    }) {
      return InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: theme.colorScheme.secondary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        filled: true,
        fillColor: theme.colorScheme.surfaceContainerHighest.withOpacity(0.2),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
      ),
      padding: const EdgeInsets.all(20),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.account_balance_rounded,
                  color: theme.colorScheme.secondary,
                ),
                const SizedBox(width: 8),
                Text(
                  t.bankAccountDetails,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.secondaryContainer.withOpacity(0.4),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 18,
                    color: theme.colorScheme.onSecondaryContainer,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      t.bankBinInfo,
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.onSecondaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 24),
            TextFormField(
              controller: bankName,
              decoration: inputStyle(
                t.bankName,
                Icons.account_balance_outlined,
              ),
              validator: (value) => _required(context, value),
            ),
            const SizedBox(height: 16),
            BankBinField(controller: bankBin),
            const SizedBox(height: 16),
            TextFormField(
              controller: accountNumber,
              decoration: inputStyle(
                t.accountNumber,
                Icons.numbers_outlined,
              ),
              keyboardType: TextInputType.number,
              validator: (value) => _required(context, value),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: accountHolderName,
              decoration: inputStyle(
                t.accountHolderName,
                Icons.person_pin_outlined,
              ),
              validator: (value) => _required(context, value),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: branchName,
              decoration: inputStyle(
                t.bankBranchOptional,
                Icons.location_city_outlined,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: theme.colorScheme.secondary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: loading ? null : onSave,
                icon: const Icon(Icons.save_rounded),
                label: Text(
                  t.saveBankInformation,
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Legal & Reports Card
// ─────────────────────────────────────────────────────────────────────────────

class _LegalAndReportsCard extends StatelessWidget {
  final bool isTutor;

  const _LegalAndReportsCard({required this.isTutor});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = context.l10n;

    return Card(
      elevation: 0,
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          if (isTutor) ...[
            ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 8,
              ),
              leading: _TileIcon(
                icon: Icons.verified_user_outlined,
                color: theme.colorScheme.errorContainer,
                iconColor: theme.colorScheme.onErrorContainer,
              ),
              title: Text(
                t.reportsAboutMe,
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              subtitle: Text(t.reportsAboutMeSubtitle),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => context.push('/tutor-reports'),
            ),
            const Divider(height: 1),
            ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 8,
              ),
              leading: _TileIcon(
                icon: Icons.support_agent_outlined,
                color: theme.colorScheme.primaryContainer,
                iconColor: theme.colorScheme.onPrimaryContainer,
              ),
              title: Text(
                t.reportIssueToAdmin,
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              subtitle: Text(t.reportIssueToAdminSubtitle),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => context.push('/support-report/create'),
            ),
            const Divider(height: 1),
            ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 8,
              ),
              leading: _TileIcon(
                icon: Icons.manage_search_outlined,
                color: theme.colorScheme.secondaryContainer,
                iconColor: theme.colorScheme.onSecondaryContainer,
              ),
              title: Text(
                t.myAdminSupportReports,
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              subtitle: Text(t.myAdminSupportReportsSubtitle),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => context.push('/support-reports/me'),
            ),
            const Divider(height: 1),
          ],
          if (!isTutor) ...[
            ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 8,
              ),
              leading: _TileIcon(
                icon: Icons.report_gmailerrorred_outlined,
                color: theme.colorScheme.secondaryContainer,
                iconColor: theme.colorScheme.onSecondaryContainer,
              ),
              title: Text(
                t.myReports,
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              subtitle: Text(t.myReportsSubtitle),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => context.push('/my-reports'),
            ),
            const Divider(height: 1),
          ],
          ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 8,
            ),
            leading: _TileIcon(
              icon: Icons.description_outlined,
              color: theme.colorScheme.primaryContainer,
              iconColor: theme.colorScheme.onPrimaryContainer,
            ),
            title: Text(
              t.termsOfService,
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            subtitle: Text(t.termsOfServiceSubtitle),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => context.push('/terms-of-service'),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tile Icon helper
// ─────────────────────────────────────────────────────────────────────────────

class _TileIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color iconColor;

  const _TileIcon({
    required this.icon,
    required this.color,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: color.withOpacity(0.65),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(icon, color: iconColor),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared validator
// ─────────────────────────────────────────────────────────────────────────────

String? _required(BuildContext context, String? value) {
  if (value == null || value.trim().isEmpty) {
    return AppStrings.of(context, listen: false).thisFieldRequired;
  }
  return null;
}
