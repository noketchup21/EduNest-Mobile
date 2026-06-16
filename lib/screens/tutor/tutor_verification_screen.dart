import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_strings.dart';
import '../../models/mvp_models.dart';
import '../../providers/app_data_provider.dart';
import '../../widgets/bank_bin_field.dart';
import '../../widgets/error_banner.dart';

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
  final List<String> _certificatePaths = [];

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
    final t = context.l10n;
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
        title: Text(t.text('Tutor verification')),
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
                  label: Text(t.text('Go to home')),
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
    final t = context.l10n;

    return Form(
      key: _formKey,
      child: Column(
        children: [
          if ((verification?.verificationStatus.toLowerCase() ?? '') ==
              'rejected')
            Card(
              child: ListTile(
                leading: const Icon(Icons.error_outline),
                title: Text(t.text('Your verification was rejected')),
                subtitle: Text(
                  verification?.verificationRejectReason ??
                      t.text('Please check your documents and submit again.'),
                ),
              ),
            ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _nationalId,
            decoration: InputDecoration(
              labelText: t.text('CCCD number'),
              prefixIcon: const Icon(Icons.badge_outlined),
            ),
            validator: (value) => _requiredValidator(context, value),
          ),
          const SizedBox(height: 12),
          _ImagePickerTile(
            title: t.text('CCCD front image'),
            subtitle: t.text('Upload the front side of your CCCD.'),
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
            title: t.text('CCCD back image'),
            subtitle: t.text('Upload the back side of your CCCD.'),
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
          _MultiImagePickerTile(
            title: t.text('Upload Certificates'),
            subtitle: t.text(
              'Certificate of Enrollment or Academic Transcript',
            ),
            localPaths: _certificatePaths,
            existingUrls: _certificateUrlsFor(verification),
            maxImages: 5,
            onPick: _pickCertificateImages,
            onRemoveLocal: (path) {
              setState(() {
                _certificatePaths.remove(path);
              });
            },
          ),
          const SizedBox(height: 20),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              t.text('Bank information'),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _bankName,
            decoration: InputDecoration(
              labelText: t.text('Bank name'),
              prefixIcon: const Icon(Icons.account_balance_outlined),
            ),
            validator: (value) => _requiredValidator(context, value),
          ),
          const SizedBox(height: 12),
          BankBinField(controller: _bankBin),
          const SizedBox(height: 12),
          TextFormField(
            controller: _accountNumber,
            decoration: InputDecoration(
              labelText: t.text('Account number'),
              prefixIcon: const Icon(Icons.numbers_outlined),
            ),
            keyboardType: TextInputType.number,
            validator: (value) => _requiredValidator(context, value),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _accountHolderName,
            decoration: InputDecoration(
              labelText: t.text('Account holder name'),
              prefixIcon: const Icon(Icons.person_outline),
            ),
            validator: (value) => _requiredValidator(context, value),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _branchName,
            decoration: InputDecoration(
              labelText: t.text('Branch name optional'),
              prefixIcon: const Icon(Icons.location_city_outlined),
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
                data.loading
                    ? t.text('Submitting...')
                    : t.text('Submit verification'),
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
    final t = AppStrings.of(context, listen: false);

    if (!_formKey.currentState!.validate()) return;

    if (_cccdFrontPath == null ||
        _cccdBackPath == null ||
        _certificatePaths.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            t.text(
              'Please upload CCCD front, CCCD back, and at least one certificate.',
            ),
          ),
        ),
      );

      return;
    }

    try {
      await context.read<AppDataProvider>().submitTutorVerification(
            nationalIdNumber: _nationalId.text.trim(),
            cccdFrontPath: _cccdFrontPath!,
            cccdBackPath: _cccdBackPath!,
            certificatePaths: _certificatePaths,
            bankName: _bankName.text.trim(),
            bankBin: _bankBin.text.trim(),
            accountNumber: _accountNumber.text.trim(),
            accountHolderName: _accountHolderName.text.trim(),
            branchName: _branchName.text.trim(),
          );

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            t.text('Verification submitted. Please wait for admin approval.'),
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

  String? _requiredValidator(BuildContext context, String? value) {
    if (value == null || value.trim().isEmpty) {
      return AppStrings.of(context, listen: false).requiredField;
    }

    return null;
  }

  Future<void> _pickCertificateImages() async {
    final t = AppStrings.of(context, listen: false);
    const maxImages = 5;
    final remaining = maxImages - _certificatePaths.length;

    if (remaining <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.text('Maximum 5 certificate images.'))),
      );
      return;
    }

    final files = await _picker.pickMultiImage(
      imageQuality: 80,
      maxWidth: 1600,
    );

    if (files.isEmpty) return;

    final selectedPaths = files.map((file) => file.path).take(remaining);

    setState(() {
      for (final path in selectedPaths) {
        if (!_certificatePaths.contains(path)) {
          _certificatePaths.add(path);
        }
      }
    });

    if (files.length > remaining && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.text('Maximum 5 certificate images.'))),
      );
    }
  }

  List<String> _certificateUrlsFor(TutorVerificationModel? verification) {
    if (verification == null) return const [];

    if (verification.certificateImageUrls.isNotEmpty) {
      return verification.certificateImageUrls;
    }

    final url = verification.certificateImageUrl?.trim() ?? '';

    return url.isEmpty ? const [] : [url];
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
    final t = context.l10n;
    final status = verification?.verificationStatus ?? 'NotSubmitted';

    IconData icon;
    String title;
    String subtitle;

    if (isApproved) {
      icon = Icons.verified;
      title = t.text('Approved');
      subtitle = t
          .text('Your tutor profile is approved. You can create availability.');
    } else if (isPending) {
      icon = Icons.hourglass_top;
      title = t.text('Pending approval');
      subtitle =
          t.text('Your documents are submitted. Please wait for admin review.');
    } else if (status.toLowerCase() == 'rejected') {
      icon = Icons.cancel_outlined;
      title = t.text('Rejected');
      subtitle = verification?.verificationRejectReason ??
          t.text('Please update your documents and submit again.');
    } else {
      icon = Icons.assignment_outlined;
      title = t.text('Verification required');
      subtitle = t.text(
          'Submit your CCCD, certificate, and bank information before creating availability.');
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
                    '${t.text('Status')}: ${t.status(status)}',
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
    final t = context.l10n;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Icon(Icons.schedule, size: 56),
            const SizedBox(height: 12),
            Text(
              t.text('Waiting for admin approval'),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              t.text(
                'You cannot create availability until your tutor profile is approved.',
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () => context.go('/home'),
              icon: const Icon(Icons.home_outlined),
              label: Text(t.text('Go to home')),
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
    final t = context.l10n;
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
                label:
                    Text(t.text(hasLocal || hasExisting ? 'Change' : 'Pick')),
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
                      child: Text(t.text('Unable to load existing image')),
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

class _MultiImagePickerTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<String> localPaths;
  final List<String> existingUrls;
  final int maxImages;
  final VoidCallback onPick;
  final ValueChanged<String> onRemoveLocal;

  const _MultiImagePickerTile({
    required this.title,
    required this.subtitle,
    required this.localPaths,
    required this.existingUrls,
    required this.maxImages,
    required this.onPick,
    required this.onRemoveLocal,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final hasLocal = localPaths.isNotEmpty;
    final count = hasLocal ? localPaths.length : existingUrls.length;
    final canAdd = localPaths.length < maxImages;

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
              subtitle: Text('$subtitle\n${t.text('Maximum 5 images')}'),
              trailing: FilledButton.tonalIcon(
                onPressed: canAdd ? onPick : null,
                icon: const Icon(Icons.collections_outlined),
                label: Text(t.text(hasLocal ? 'Add images' : 'Pick')),
              ),
            ),
            if (count > 0) ...[
              const SizedBox(height: 6),
              Text(
                t.text('{count} image(s) selected').replaceFirst(
                      '{count}',
                      count.toString(),
                    ),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 10),
              _CertificateImageGrid(
                localPaths: localPaths,
                existingUrls: hasLocal ? const [] : existingUrls,
                onRemoveLocal: onRemoveLocal,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CertificateImageGrid extends StatelessWidget {
  final List<String> localPaths;
  final List<String> existingUrls;
  final ValueChanged<String> onRemoveLocal;

  const _CertificateImageGrid({
    required this.localPaths,
    required this.existingUrls,
    required this.onRemoveLocal,
  });

  @override
  Widget build(BuildContext context) {
    final items = [
      ...localPaths.map((path) => _CertificateImageItem.local(path)),
      ...existingUrls.map((url) => _CertificateImageItem.remote(url)),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.1,
      ),
      itemBuilder: (context, index) {
        final item = items[index];

        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (item.isLocal)
                Image.file(
                  File(item.value),
                  fit: BoxFit.cover,
                )
              else
                Image.network(
                  item.value,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) {
                    return ColoredBox(
                      color: Theme.of(context).colorScheme.surfaceContainerHigh,
                      child: Center(
                        child: Text(
                          context.l10n.text('Unable to load existing image'),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  },
                ),
              if (item.isLocal)
                Positioned(
                  top: 6,
                  right: 6,
                  child: IconButton.filledTonal(
                    onPressed: () => onRemoveLocal(item.value),
                    icon: const Icon(Icons.close, size: 18),
                    tooltip: context.l10n.text('Remove'),
                    style: IconButton.styleFrom(
                      minimumSize: const Size(34, 34),
                      fixedSize: const Size(34, 34),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _CertificateImageItem {
  final String value;
  final bool isLocal;

  const _CertificateImageItem._({
    required this.value,
    required this.isLocal,
  });

  factory _CertificateImageItem.local(String path) {
    return _CertificateImageItem._(value: path, isLocal: true);
  }

  factory _CertificateImageItem.remote(String url) {
    return _CertificateImageItem._(value: url, isLocal: false);
  }
}
