import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../models/mvp_models.dart';
import '../../providers/app_data_provider.dart';
import '../../widgets/error_banner.dart';

class AdminTutorDetailScreen extends StatefulWidget {
  final int tutorId;

  const AdminTutorDetailScreen({
    super.key,
    required this.tutorId,
  });

  @override
  State<AdminTutorDetailScreen> createState() => _AdminTutorDetailScreenState();
}

class _AdminTutorDetailScreenState extends State<AdminTutorDetailScreen> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppDataProvider>().adminLoadTutorDetail(widget.tutorId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final data = context.watch<AppDataProvider>();
    final detail = data.adminTutorDetail;

    final isCorrectTutor = detail?.tutorId == widget.tutorId;

    return Scaffold(
      appBar: AppBar(
        title: Text('Tutor #${widget.tutorId}'),
        actions: [
          IconButton(
            onPressed: data.loading
                ? null
                : () => context
                .read<AppDataProvider>()
                .adminLoadTutorDetail(widget.tutorId),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await context
              .read<AppDataProvider>()
              .adminLoadTutorDetail(widget.tutorId);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            ErrorBanner(data.error),
            if (!isCorrectTutor)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              )
            else
              _TutorDetailContent(
                detail: detail!,
                loading: data.loading,
              ),
          ],
        ),
      ),
    );
  }
}

class _TutorDetailContent extends StatelessWidget {
  final TutorVerificationModel detail;
  final bool loading;

  const _TutorDetailContent({
    required this.detail,
    required this.loading,
  });

  @override
  Widget build(BuildContext context) {
    final status = detail.verificationStatus.toLowerCase();
    final isApproved = detail.isVerified && status == 'approved';
    final isActive = detail.isActive;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 36,
                  child: Text(
                    detail.tutorName.isEmpty
                        ? '?'
                        : detail.tutorName[0].toUpperCase(),
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  detail.tutorName.isEmpty
                      ? 'Tutor #${detail.tutorId}'
                      : detail.tutorName,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  detail.email,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: [
                    Chip(
                      avatar: Icon(
                        isApproved
                            ? Icons.verified_outlined
                            : Icons.pending_actions_outlined,
                        size: 18,
                      ),
                      label: Text('Verification: ${detail.verificationStatus}'),
                    ),
                    Chip(
                      avatar: Icon(
                        isActive ? Icons.check_circle_outline : Icons.block,
                        size: 18,
                      ),
                      label: Text(isActive ? 'Active' : 'Deactivated'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 12),

        _AccountStatusCard(
          detail: detail,
          loading: loading,
        ),

        const SizedBox(height: 12),

        _SectionCard(
          title: 'Tutor information',
          children: [
            _InfoTile(
              icon: Icons.badge_outlined,
              label: 'Tutor ID',
              value: detail.tutorId.toString(),
            ),
            _InfoTile(
              icon: Icons.person_outline,
              label: 'User ID',
              value: detail.userId.toString(),
            ),
            _InfoTile(
              icon: Icons.email_outlined,
              label: 'Email',
              value: detail.email,
              copyable: true,
            ),
            _InfoTile(
              icon: Icons.credit_card_outlined,
              label: 'CCCD number',
              value: detail.nationalIdNumber ?? 'Not provided',
              copyable: detail.nationalIdNumber != null,
            ),
            if ((detail.verificationRejectReason ?? '').isNotEmpty)
              _InfoTile(
                icon: Icons.error_outline,
                label: 'Reject reason',
                value: detail.verificationRejectReason!,
              ),
          ],
        ),

        const SizedBox(height: 12),

        _SectionCard(
          title: 'Bank information',
          children: [
            _InfoTile(
              icon: Icons.account_balance_outlined,
              label: 'Bank name',
              value: detail.bankName ?? 'Not provided',
              copyable: detail.bankName != null,
            ),
            _InfoTile(
              icon: Icons.pin_outlined,
              label: 'Bank BIN',
              value: detail.bankBin ?? 'Not provided',
              copyable: detail.bankBin != null,
            ),
            _InfoTile(
              icon: Icons.numbers_outlined,
              label: 'Account number',
              value: detail.accountNumber ?? 'Not provided',
              copyable: detail.accountNumber != null,
            ),
            _InfoTile(
              icon: Icons.person_pin_outlined,
              label: 'Account holder',
              value: detail.accountHolderName ?? 'Not provided',
              copyable: detail.accountHolderName != null,
            ),
            _InfoTile(
              icon: Icons.location_city_outlined,
              label: 'Branch',
              value: detail.branchName ?? 'Not provided',
              copyable: detail.branchName != null,
            ),
          ],
        ),

        const SizedBox(height: 12),

        _DocumentsCard(detail: detail),

        const SizedBox(height: 20),

        if (!isApproved) ...[
          FilledButton.icon(
            onPressed:
            loading ? null : () => _confirmApprove(context, detail.tutorId),
            icon: const Icon(Icons.verified_outlined),
            label: const Text('Approve tutor'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed:
            loading ? null : () => _showRejectDialog(context, detail.tutorId),
            icon: const Icon(Icons.cancel_outlined),
            label: const Text('Reject tutor'),
          ),
        ] else
          Card(
            child: ListTile(
              leading: const Icon(Icons.verified),
              title: const Text('Tutor approved'),
              subtitle: const Text(
                'This tutor can create availability and receive bookings while the account is active.',
              ),
              trailing: OutlinedButton(
                onPressed:
                loading ? null : () => _showRejectDialog(context, detail.tutorId),
                child: const Text('Reject'),
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _confirmApprove(BuildContext context, int tutorId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Approve tutor?'),
          content: const Text(
            'This tutor will be able to create availability and receive bookings.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Approve'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !context.mounted) return;

    try {
      await context.read<AppDataProvider>().adminApproveTutor(tutorId);

      if (!context.mounted) return;

      await context.read<AppDataProvider>().adminLoadTutorDetail(tutorId);

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tutor approved')),
      );
    } catch (_) {}
  }

  Future<void> _showRejectDialog(BuildContext context, int tutorId) async {
    String reason = '';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Reject tutor'),
          content: TextField(
            decoration: const InputDecoration(
              labelText: 'Reason optional',
              hintText: 'Example: CCCD image is unclear',
            ),
            minLines: 2,
            maxLines: 4,
            onChanged: (value) {
              reason = value.trim();
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Reject'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !context.mounted) return;

    final data = context.read<AppDataProvider>();

    try {
      await data.adminRejectTutor(
        tutorId: tutorId,
        reason: reason,
      );

      if (!context.mounted) return;

      await data.adminLoadTutorDetail(tutorId);

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tutor rejected')),
      );
    } catch (_) {}
  }
}

class _AccountStatusCard extends StatelessWidget {
  final TutorVerificationModel detail;
  final bool loading;

  const _AccountStatusCard({
    required this.detail,
    required this.loading,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = detail.isActive;

    return Card(
      child: ListTile(
        leading: Icon(
          isActive ? Icons.check_circle_outline : Icons.block,
        ),
        title: Text(
          isActive ? 'Tutor account is active' : 'Tutor account is deactivated',
        ),
        subtitle: Text(
          isActive
              ? 'This tutor can login and appear in available courses.'
              : 'This tutor cannot login or receive new bookings.',
        ),
        trailing: FilledButton(
          onPressed: loading
              ? null
              : () => _confirmAccountStatus(
            context,
            tutorId: detail.tutorId,
            isActive: !isActive,
          ),
          child: Text(isActive ? 'Deactivate' : 'Activate'),
        ),
      ),
    );
  }

  Future<void> _confirmAccountStatus(
      BuildContext context, {
        required int tutorId,
        required bool isActive,
      }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(isActive ? 'Activate tutor?' : 'Deactivate tutor?'),
          content: Text(
            isActive
                ? 'This tutor will be able to login and use tutor features again.'
                : 'This tutor will not be able to login. Their courses should also be hidden from learners.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(isActive ? 'Activate' : 'Deactivate'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !context.mounted) return;

    final data = context.read<AppDataProvider>();

    try {
      await data.adminUpdateTutorAccountStatus(
        tutorId: tutorId,
        isActive: isActive,
      );

      if (!context.mounted) return;

      await data.adminLoadTutorDetail(tutorId);

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isActive ? 'Tutor activated' : 'Tutor deactivated',
          ),
        ),
      );
    } catch (_) {}
  }
}

class _DocumentsCard extends StatelessWidget {
  final TutorVerificationModel detail;

  const _DocumentsCard({
    required this.detail,
  });

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Submitted documents',
      children: [
        _ImageDocumentTile(
          title: 'CCCD front',
          imageUrl: detail.cccdFrontImageUrl,
        ),
        _ImageDocumentTile(
          title: 'CCCD back',
          imageUrl: detail.cccdBackImageUrl,
        ),
        _ImageDocumentTile(
          title: 'Certificate / university document',
          imageUrl: detail.certificateImageUrl,
        ),
      ],
    );
  }
}

class _ImageDocumentTile extends StatelessWidget {
  final String title;
  final String? imageUrl;

  const _ImageDocumentTile({
    required this.title,
    required this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage = imageUrl != null && imageUrl!.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          if (!hasImage)
            Container(
              height: 120,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).dividerColor,
                ),
              ),
              child: const Text('No image submitted'),
            )
          else
            InkWell(
              onTap: () => _openImageDialog(context, title, imageUrl!),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  imageUrl!,
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) {
                    return Container(
                      height: 120,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Theme.of(context).dividerColor,
                        ),
                      ),
                      child: const Text('Unable to load image'),
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _openImageDialog(
      BuildContext context,
      String title,
      String url,
      ) {
    showDialog(
      context: context,
      builder: (_) {
        return Dialog(
          insetPadding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppBar(
                title: Text(title),
                automaticallyImplyLeading: false,
                actions: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              Flexible(
                child: InteractiveViewer(
                  child: Image.network(
                    url,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) {
                      return const Padding(
                        padding: EdgeInsets.all(32),
                        child: Text('Unable to load image'),
                      );
                    },
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

class _SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SectionCard({
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.only(top: 12, bottom: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(height: 8),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool copyable;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
    this.copyable = false,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      subtitle: Text(value),
      trailing: copyable
          ? IconButton(
        icon: const Icon(Icons.copy),
        onPressed: () async {
          await Clipboard.setData(
            ClipboardData(text: value),
          );

          if (!context.mounted) return;

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Copied $label'),
            ),
          );
        },
      )
          : null,
    );
  }
}