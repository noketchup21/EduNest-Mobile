// admin_tutor_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../models/mvp_models.dart';
import '../../providers/app_data_provider.dart';
import '../../widgets/error_banner.dart';

const double _cardRadius = 22;

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
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        title: Text(
          'Tutor #${widget.tutorId}',
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: colors.surface,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: IconButton.filledTonal(
              onPressed: data.loading
                  ? null
                  : () => context.read<AppDataProvider>().adminLoadTutorDetail(widget.tutorId),
              icon: const Icon(Icons.refresh),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await context.read<AppDataProvider>().adminLoadTutorDetail(widget.tutorId);
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            ErrorBanner(data.error),
            if (!isCorrectTutor)
              const _LoadingCard()
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
    final colors = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                colors.primaryContainer.withOpacity(0.82),
                colors.secondaryContainer.withOpacity(0.55),
              ],
            ),
            border: Border.all(color: colors.outlineVariant),
          ),
          child: Column(
            children: [
              CircleAvatar(
                radius: 38,
                backgroundColor: colors.surface.withOpacity(0.88),
                foregroundColor: colors.primary,
                child: Text(
                  detail.tutorName.isEmpty ? '?' : detail.tutorName[0].toUpperCase(),
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                detail.tutorName.isEmpty ? 'Tutor #${detail.tutorId}' : detail.tutorName,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.3,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                detail.email,
                textAlign: TextAlign.center,
                style: TextStyle(color: colors.onSurfaceVariant),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  _StatusPill(
                    label: 'Verification: ${detail.verificationStatus}',
                    color: isApproved ? Colors.green : Colors.orange,
                  ),
                  _StatusPill(
                    label: isActive ? 'Active' : 'Deactivated',
                    color: isActive ? Colors.green : Colors.red,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _AccountStatusCard(
          detail: detail,
          loading: loading,
        ),
        const SizedBox(height: 14),
        _SectionCard(
          title: 'Tutor information',
          subtitle: 'Identity, account, and verification information',
          icon: Icons.badge_outlined,
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
        const SizedBox(height: 14),
        _SectionCard(
          title: 'Bank information',
          subtitle: 'Used for admin payout verification',
          icon: Icons.account_balance_outlined,
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
        const SizedBox(height: 14),
        _DocumentsCard(detail: detail),
        const SizedBox(height: 20),
        if (!isApproved) ...[
          SizedBox(
            height: 50,
            child: FilledButton.icon(
              onPressed: loading ? null : () => _confirmApprove(context, detail.tutorId),
              icon: const Icon(Icons.verified_outlined),
              label: const Text('Approve tutor'),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 50,
            child: OutlinedButton.icon(
              onPressed: loading ? null : () => _showRejectDialog(context, detail.tutorId),
              icon: const Icon(Icons.cancel_outlined),
              label: const Text('Reject tutor'),
            ),
          ),
        ] else
          Card(
            elevation: 0,
            color: colors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(_cardRadius),
              side: BorderSide(color: colors.outlineVariant),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              leading: const _SoftIcon(
                icon: Icons.verified,
                color: Colors.green,
              ),
              title: const Text(
                'Tutor approved',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
              subtitle: const Text(
                'This tutor can create availability and receive bookings while the account is active.',
              ),
              trailing: OutlinedButton(
                onPressed: loading ? null : () => _showRejectDialog(context, detail.tutorId),
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          title: const Text('Reject tutor'),
          content: TextField(
            decoration: _inputDecoration(
              context,
              label: 'Reason optional',
              icon: Icons.edit_note_outlined,
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
    final colors = Theme.of(context).colorScheme;
    final statusColor = isActive ? Colors.green : Colors.red;

    return Card(
      elevation: 0,
      color: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_cardRadius),
        side: BorderSide(color: colors.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            _SoftIcon(
              icon: isActive ? Icons.check_circle_outline : Icons.block,
              color: statusColor,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isActive ? 'Tutor account is active' : 'Tutor account is deactivated',
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isActive
                        ? 'This tutor can login and appear in available courses.'
                        : 'This tutor cannot login or receive new bookings.',
                    style: TextStyle(color: colors.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            FilledButton(
              onPressed: loading
                  ? null
                  : () => _confirmAccountStatus(
                context,
                tutorId: detail.tutorId,
                isActive: !isActive,
              ),
              child: Text(isActive ? 'Deactivate' : 'Activate'),
            ),
          ],
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
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
          content: Text(isActive ? 'Tutor activated' : 'Tutor deactivated'),
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
      subtitle: 'Tap an image to inspect it in detail',
      icon: Icons.folder_copy_outlined,
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
    final colors = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surfaceVariant.withOpacity(0.22),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.outlineVariant.withOpacity(0.75)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _SoftIcon(
                icon: hasImage ? Icons.image_outlined : Icons.image_not_supported_outlined,
                size: 34,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
              _StatusPill(
                label: hasImage ? 'Submitted' : 'Missing',
                color: hasImage ? Colors.green : Colors.orange,
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (!hasImage)
            Container(
              height: 120,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: colors.outlineVariant),
              ),
              child: Text(
                'No image submitted',
                style: TextStyle(color: colors.onSurfaceVariant),
              ),
            )
          else
            InkWell(
              onTap: () => _openImageDialog(context, title, imageUrl!),
              borderRadius: BorderRadius.circular(16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  imageUrl!,
                  height: 190,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) {
                    return Container(
                      height: 120,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: colors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: colors.outlineVariant),
                      ),
                      child: Text(
                        'Unable to load image',
                        style: TextStyle(color: colors.onSurfaceVariant),
                      ),
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          clipBehavior: Clip.antiAlias,
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
  final String subtitle;
  final IconData icon;
  final List<Widget> children;

  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      color: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_cardRadius),
        side: BorderSide(color: colors.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SoftIcon(icon: icon),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
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
    final colors = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: colors.surfaceVariant.withOpacity(0.22),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.outlineVariant.withOpacity(0.75)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: _SoftIcon(icon: icon, size: 38),
        title: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 3),
          child: Text(
            value,
            style: TextStyle(color: colors.onSurfaceVariant),
          ),
        ),
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
      ),
    );
  }
}

class _SoftIcon extends StatelessWidget {
  final IconData icon;
  final Color? color;
  final double size;

  const _SoftIcon({
    required this.icon,
    this.color,
    this.size = 42,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final accent = color ?? colors.primary;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: accent.withOpacity(0.12),
        borderRadius: BorderRadius.circular(size * 0.34),
      ),
      child: Icon(icon, color: accent, size: size * 0.52),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusPill({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      color: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_cardRadius),
        side: BorderSide(color: colors.outlineVariant),
      ),
      child: const Padding(
        padding: EdgeInsets.all(32),
        child: Center(child: CircularProgressIndicator()),
      ),
    );
  }
}

InputDecoration _inputDecoration(
    BuildContext context, {
      required String label,
      required IconData icon,
      String? hintText,
    }) {
  final colors = Theme.of(context).colorScheme;

  return InputDecoration(
    labelText: label,
    hintText: hintText,
    prefixIcon: Icon(icon),
    filled: true,
    fillColor: colors.surfaceVariant.withOpacity(0.22),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: colors.outlineVariant),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: colors.outlineVariant),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: colors.primary, width: 1.6),
    ),
  );
}