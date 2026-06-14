import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../models/mvp_models.dart';
import '../../providers/app_data_provider.dart';
import '../../widgets/error_banner.dart';
import '../../widgets/bank_bin_field.dart';

class TutorVerificationScreen extends StatefulWidget {
  const TutorVerificationScreen({super.key});

  @override
  State<TutorVerificationScreen> createState() =>
      _TutorVerificationScreenState();
}

class _TutorVerificationScreenState extends State<TutorVerificationScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nationalId = TextEditingController();
  final _bankName = TextEditingController();
  final _accountNumber = TextEditingController();
  final _accountHolderName = TextEditingController();
  final _branchName = TextEditingController();
  final _bankBin = TextEditingController();

  final _picker = ImagePicker();

  String? _cccdFrontPath;
  String? _cccdBackPath;
  String? _certificatePath;

  bool _initializedFields = false;
  bool _handledApprovedRedirect = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppDataProvider>().loadMyTutorVerification();
    });
  }

  @override
  void dispose() {
    _nationalId.dispose();
    _bankName.dispose();
    _accountNumber.dispose();
    _accountHolderName.dispose();
    _branchName.dispose();
    _bankBin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = context.watch<AppDataProvider>();
    final verification = data.tutorVerification;

    _fillExistingDataOnce(verification);

    final status = verification?.verificationStatus.toLowerCase() ?? '';
    final isApproved = verification?.isVerified == true && status == 'approved';
    final isPending = status == 'pending';

    if (isApproved) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _redirectApprovedTutorIfAlreadySeen(verification);
      });
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _goBack,
        ),
        title: const Text('Tutor verification'),
        actions: [
          IconButton(
            onPressed: data.loading
                ? null
                : () =>
                    context.read<AppDataProvider>().loadMyTutorVerification(),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            ErrorBanner(data.error),
            if (data.loading && verification == null)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              )
            else ...[
              _StatusCard(
                verification: verification,
                isApproved: isApproved,
                isPending: isPending,
              ),
              const SizedBox(height: 12),
              if (isApproved)
                FilledButton.icon(
                  onPressed: () => _continueAfterApproval(verification),
                  icon: const Icon(Icons.home),
                  label: const Text('Go to home'),
                )
              else if (isPending)
                const _PendingMessage()
              else
                _buildForm(context, data, verification),
            ],
          ],
        ),
      ),
    );
  }

  void _goBack() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/home');
    }
  }

  Widget _buildForm(
    BuildContext context,
    AppDataProvider data,
    TutorVerificationModel? verification,
  ) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          if ((verification?.verificationStatus.toLowerCase() ?? '') ==
              'rejected')
            Card(
              child: ListTile(
                leading: const Icon(Icons.error_outline),
                title: const Text('Your verification was rejected'),
                subtitle: Text(
                  verification?.verificationRejectReason ??
                      'Please check your documents and submit again.',
                ),
              ),
            ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _nationalId,
            decoration: const InputDecoration(
              labelText: 'CCCD number',
              prefixIcon: Icon(Icons.badge_outlined),
            ),
            validator: _requiredValidator,
          ),
          const SizedBox(height: 12),
          _ImagePickerTile(
            title: 'CCCD front image',
            subtitle: 'Upload the front side of your CCCD.',
            localPath: _cccdFrontPath,
            existingUrl: verification?.cccdFrontImageUrl,
            onPick: () async {
              final path = await _pickImage();
              if (path == null) return;

              setState(() {
                _cccdFrontPath = path;
              });
            },
          ),
          const SizedBox(height: 12),
          _ImagePickerTile(
            title: 'CCCD back image',
            subtitle: 'Upload the back side of your CCCD.',
            localPath: _cccdBackPath,
            existingUrl: verification?.cccdBackImageUrl,
            onPick: () async {
              final path = await _pickImage();
              if (path == null) return;

              setState(() {
                _cccdBackPath = path;
              });
            },
          ),
          const SizedBox(height: 12),
          _ImagePickerTile(
            title: 'Certificate / university document',
            subtitle: 'Upload degree, certificate, or enrollment document.',
            localPath: _certificatePath,
            existingUrl: verification?.certificateImageUrl,
            onPick: () async {
              final path = await _pickImage();
              if (path == null) return;

              setState(() {
                _certificatePath = path;
              });
            },
          ),
          const SizedBox(height: 20),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Bank information',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _bankName,
            decoration: const InputDecoration(
              labelText: 'Bank name',
              prefixIcon: Icon(Icons.account_balance_outlined),
            ),
            validator: _requiredValidator,
          ),
          const SizedBox(height: 12),
          BankBinField(controller: _bankBin),
          const SizedBox(height: 12),
          TextFormField(
            controller: _accountNumber,
            decoration: const InputDecoration(
              labelText: 'Account number',
              prefixIcon: Icon(Icons.numbers_outlined),
            ),
            keyboardType: TextInputType.number,
            validator: _requiredValidator,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _accountHolderName,
            decoration: const InputDecoration(
              labelText: 'Account holder name',
              prefixIcon: Icon(Icons.person_outline),
            ),
            validator: _requiredValidator,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _branchName,
            decoration: const InputDecoration(
              labelText: 'Branch name optional',
              prefixIcon: Icon(Icons.location_city_outlined),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: data.loading ? null : () => _submit(context),
              icon: data.loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.upload_file),
              label: Text(
                data.loading ? 'Submitting...' : 'Submit verification',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _redirectApprovedTutorIfAlreadySeen(
    TutorVerificationModel? verification,
  ) async {
    if (_handledApprovedRedirect || verification == null) return;

    final status = verification.verificationStatus.toLowerCase();
    final isApproved = verification.isVerified && status == 'approved';

    if (!isApproved) return;

    _handledApprovedRedirect = true;

    final alreadySeen = await context
        .read<AppDataProvider>()
        .hasSeenTutorApprovalNotice(verification.tutorId);

    if (!mounted) return;

    if (alreadySeen) {
      context.go('/home');
    }
  }

  Future<void> _continueAfterApproval(
    TutorVerificationModel? verification,
  ) async {
    if (verification != null) {
      await context
          .read<AppDataProvider>()
          .markTutorApprovalNoticeSeen(verification.tutorId);
    }

    if (!mounted) return;

    context.go('/home');
  }

  Future<String?> _pickImage() async {
    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 1600,
    );

    return file?.path;
  }

  Future<void> _submit(BuildContext context) async {
    if (!_formKey.currentState!.validate()) return;

    if (_cccdFrontPath == null ||
        _cccdBackPath == null ||
        _certificatePath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Please upload CCCD front, CCCD back, and certificate.'),
        ),
      );

      return;
    }

    try {
      await context.read<AppDataProvider>().submitTutorVerification(
            nationalIdNumber: _nationalId.text.trim(),
            cccdFrontPath: _cccdFrontPath!,
            cccdBackPath: _cccdBackPath!,
            certificatePath: _certificatePath!,
            bankName: _bankName.text.trim(),
            bankBin: _bankBin.text.trim(),
            accountNumber: _accountNumber.text.trim(),
            accountHolderName: _accountHolderName.text.trim(),
            branchName: _branchName.text.trim(),
          );

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Verification submitted. Please wait for admin approval.',
          ),
        ),
      );
    } catch (_) {}
  }

  void _fillExistingDataOnce(TutorVerificationModel? verification) {
    if (_initializedFields || verification == null) return;

    _nationalId.text = verification.nationalIdNumber ?? '';
    _bankName.text = verification.bankName ?? '';
    _accountNumber.text = verification.accountNumber ?? '';
    _accountHolderName.text = verification.accountHolderName ?? '';
    _branchName.text = verification.branchName ?? '';
    _bankBin.text = verification.bankBin ?? '';

    _initializedFields = true;
  }

  String? _requiredValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'This field is required';
    }

    return null;
  }
}

class _StatusCard extends StatelessWidget {
  final TutorVerificationModel? verification;
  final bool isApproved;
  final bool isPending;

  const _StatusCard({
    required this.verification,
    required this.isApproved,
    required this.isPending,
  });

  @override
  Widget build(BuildContext context) {
    final status = verification?.verificationStatus ?? 'NotSubmitted';

    IconData icon;
    String title;
    String subtitle;

    if (isApproved) {
      icon = Icons.verified;
      title = 'Approved';
      subtitle = 'Your tutor profile is approved. You can create availability.';
    } else if (isPending) {
      icon = Icons.hourglass_top;
      title = 'Pending approval';
      subtitle = 'Your documents are submitted. Please wait for admin review.';
    } else if (status.toLowerCase() == 'rejected') {
      icon = Icons.cancel_outlined;
      title = 'Rejected';
      subtitle = verification?.verificationRejectReason ??
          'Please update your documents and submit again.';
    } else {
      icon = Icons.assignment_outlined;
      title = 'Verification required';
      subtitle =
          'Submit your CCCD, certificate, and bank information before creating availability.';
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              child: Icon(icon),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(subtitle),
                  const SizedBox(height: 4),
                  Text(
                    'Status: $status',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PendingMessage extends StatelessWidget {
  const _PendingMessage();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Icon(Icons.schedule, size: 56),
            const SizedBox(height: 12),
            Text(
              'Waiting for admin approval',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'You cannot create availability until your tutor profile is approved.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () => context.go('/home'),
              icon: const Icon(Icons.home_outlined),
              label: const Text('Go to home'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ImagePickerTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? localPath;
  final String? existingUrl;
  final VoidCallback onPick;

  const _ImagePickerTile({
    required this.title,
    required this.subtitle,
    required this.localPath,
    required this.existingUrl,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    final hasLocal = localPath != null && localPath!.isNotEmpty;
    final hasExisting = existingUrl != null && existingUrl!.isNotEmpty;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              subtitle: Text(subtitle),
              trailing: FilledButton.tonalIcon(
                onPressed: onPick,
                icon: const Icon(Icons.image_outlined),
                label: Text(hasLocal || hasExisting ? 'Change' : 'Pick'),
              ),
            ),
            if (hasLocal) ...[
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  File(localPath!),
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ] else if (hasExisting) ...[
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  existingUrl!,
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) {
                    return Container(
                      height: 120,
                      width: double.infinity,
                      alignment: Alignment.center,
                      child: const Text('Unable to load existing image'),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
