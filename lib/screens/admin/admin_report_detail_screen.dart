// admin_report_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/mvp_models.dart';
import '../../providers/app_data_provider.dart';
import '../../widgets/error_banner.dart';

const double _cardRadius = 22;

class AdminReportDetailScreen extends StatefulWidget {
  final int reportId;

  const AdminReportDetailScreen({
    super.key,
    required this.reportId,
  });

  @override
  State<AdminReportDetailScreen> createState() => _AdminReportDetailScreenState();
}

class _AdminReportDetailScreenState extends State<AdminReportDetailScreen> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppDataProvider>().adminLoadReportDetail(widget.reportId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final data = context.watch<AppDataProvider>();
    final report = data.adminReportDetail;
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        title: Text(
          'Report #${widget.reportId}',
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
              onPressed: data.loading ? null : () => data.adminLoadReportDetail(widget.reportId),
              icon: const Icon(Icons.refresh),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => data.adminLoadReportDetail(widget.reportId),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            ErrorBanner(data.error),
            if (report == null)
              const _LoadingCard()
            else ...[
              _ReportHeader(report: report),
              const SizedBox(height: 14),
              _InfoCard(report: report),
              const SizedBox(height: 14),
              _AdminReportTutorCard(report: report),
              const SizedBox(height: 14),
              _ProofImages(report: report),
              const SizedBox(height: 14),
              _AdminActions(report: report),
            ],
          ],
        ),
      ),
    );
  }
}

class _ReportHeader extends StatelessWidget {
  final TutorReportModel report;

  const _ReportHeader({required this.report});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final statusColor = _statusColor(report.status);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            statusColor.withOpacity(0.16),
            colors.primaryContainer.withOpacity(0.55),
          ],
        ),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SoftIcon(
            icon: Icons.report_outlined,
            color: statusColor,
            size: 54,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  report.title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _StatusPill(label: report.status, color: statusColor),
                    _StatusPill(label: report.category, color: colors.primary),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final TutorReportModel report;

  const _InfoCard({required this.report});

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Report information',
      subtitle: 'Core details submitted by the reporter',
      icon: Icons.assignment_outlined,
      children: [
        _InfoRow(label: 'Tutor', value: report.tutorName, icon: Icons.school_outlined),
        _InfoRow(label: 'Reporter', value: report.reporterName, icon: Icons.person_outline),
        _InfoRow(label: 'Booking ID', value: '#${report.bookingId}', icon: Icons.event_note_outlined),
        _InfoRow(label: 'Availability ID', value: '#${report.availabilityId}', icon: Icons.schedule_outlined),
        if (report.lessonId != null)
          _InfoRow(label: 'Lesson ID', value: '#${report.lessonId}', icon: Icons.menu_book_outlined),
        if (report.subjectName != null)
          _InfoRow(label: 'Subject', value: report.subjectName!, icon: Icons.subject_outlined),
        const _CardDivider(),
        _TextBlock(
          title: 'Description',
          text: report.description,
          icon: Icons.description_outlined,
        ),
        if (report.adminNote != null && report.adminNote!.trim().isNotEmpty) ...[
          const _CardDivider(),
          _TextBlock(
            title: 'Admin note',
            text: report.adminNote!,
            icon: Icons.admin_panel_settings_outlined,
          ),
        ],
      ],
    );
  }
}

class _ProofImages extends StatelessWidget {
  final TutorReportModel report;

  const _ProofImages({required this.report});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    if (report.proofImages.isEmpty) {
      return const _EmptyStateCard(
        icon: Icons.image_not_supported_outlined,
        title: 'No proof images',
        subtitle: 'No image proof was submitted for this report.',
      );
    }

    return _SectionCard(
      title: 'Proof images',
      subtitle: '${report.proofImages.length} image(s) attached for review',
      icon: Icons.image_outlined,
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: report.proofImages.map((img) {
            return Container(
              width: 122,
              height: 122,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: colors.outlineVariant),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(17),
                child: Image.network(
                  img.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) {
                    return Container(
                      color: colors.surfaceVariant.withOpacity(0.35),
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.broken_image_outlined,
                        color: colors.onSurfaceVariant,
                      ),
                    );
                  },
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _AdminActions extends StatefulWidget {
  final TutorReportModel report;

  const _AdminActions({required this.report});

  @override
  State<_AdminActions> createState() => _AdminActionsState();
}

class _AdminActionsState extends State<_AdminActions> {
  final _note = TextEditingController();

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = context.watch<AppDataProvider>();

    return _SectionCard(
      title: 'Admin actions',
      subtitle: 'Update the review status and leave an optional internal note',
      icon: Icons.rule_outlined,
      children: [
        TextField(
          controller: _note,
          decoration: _inputDecoration(
            context,
            label: 'Admin note optional',
            icon: Icons.note_alt_outlined,
          ),
          minLines: 1,
          maxLines: 4,
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: data.loading ? null : () => _update(context, 'Reviewing'),
                icon: const Icon(Icons.rate_review_outlined),
                label: const Text('Reviewing'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton.icon(
                onPressed: data.loading ? null : () => _update(context, 'Resolved'),
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('Resolved'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: data.loading ? null : () => _update(context, 'Rejected'),
            icon: const Icon(Icons.close),
            label: const Text('Reject report'),
          ),
        ),
      ],
    );
  }

  Future<void> _update(BuildContext context, String status) async {
    try {
      await context.read<AppDataProvider>().adminUpdateReportStatus(
        reportId: widget.report.tutorReportId,
        status: status,
        adminNote: _note.text.trim(),
      );

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Report marked as $status')),
      );
    } catch (_) {}
  }
}

class _AdminReportTutorCard extends StatelessWidget {
  final TutorReportModel report;

  const _AdminReportTutorCard({
    required this.report,
  });

  @override
  Widget build(BuildContext context) {
    final data = context.watch<AppDataProvider>();
    final isActive = report.tutorIsActive ?? true;
    final accountColor = isActive ? Colors.green : Colors.red;

    return _SectionCard(
      title: 'Reported tutor',
      subtitle: 'Account and verification details for the reported tutor',
      icon: Icons.school_outlined,
      children: [
        _InfoRow(label: 'Tutor name', value: report.tutorName, icon: Icons.person_outline),
        _InfoRow(label: 'Tutor ID', value: '#${report.tutorId}', icon: Icons.badge_outlined),
        _InfoRow(label: 'Tutor user ID', value: '#${report.tutorUserId}', icon: Icons.account_circle_outlined),
        if (report.tutorEmail != null)
          _InfoRow(label: 'Email', value: report.tutorEmail!, icon: Icons.email_outlined),
        if (report.tutorPhone != null)
          _InfoRow(label: 'Phone', value: report.tutorPhone!, icon: Icons.phone_outlined),
        if (report.tutorVerificationStatus != null)
          _InfoRow(
            label: 'Verification',
            value: report.tutorVerificationStatus!,
            icon: Icons.verified_outlined,
          ),
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            children: [
              _SoftIcon(
                icon: isActive ? Icons.check_circle_outline : Icons.block,
                color: accountColor,
                size: 38,
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Account status',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              _StatusPill(
                label: isActive ? 'Active' : 'Deactivated',
                color: accountColor,
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: FilledButton.icon(
            onPressed: data.loading
                ? null
                : () => _confirmTutorAccountStatus(
              context,
              report: report,
              isActive: !isActive,
            ),
            icon: Icon(isActive ? Icons.block : Icons.check_circle_outline),
            label: Text(isActive ? 'Deactivate tutor account' : 'Activate tutor account'),
          ),
        ),
      ],
    );
  }

  Future<void> _confirmTutorAccountStatus(
      BuildContext context, {
        required TutorReportModel report,
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
                : 'This tutor will not be able to login or receive new bookings. You should only do this if the report proof is serious enough.',
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
        tutorId: report.tutorId,
        isActive: isActive,
      );

      if (!context.mounted) return;

      await data.adminLoadReportDetail(report.tutorReportId);

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isActive ? 'Tutor account activated' : 'Tutor account deactivated'),
        ),
      );
    } catch (_) {}
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
        padding: const EdgeInsets.all(16),
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
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _InfoRow({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          _SoftIcon(icon: icon, size: 38),
          const SizedBox(width: 12),
          SizedBox(
            width: 115,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(color: colors.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }
}

class _TextBlock extends StatelessWidget {
  final String title;
  final String text;
  final IconData icon;

  const _TextBlock({
    required this.title,
    required this.text,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surfaceVariant.withOpacity(0.25),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.outlineVariant.withOpacity(0.75)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: colors.primary),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            text,
            style: TextStyle(
              height: 1.45,
              color: colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _CardDivider extends StatelessWidget {
  const _CardDivider();

  @override
  Widget build(BuildContext context) {
    return const Divider(height: 24);
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

class _EmptyStateCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _EmptyStateCard({
    required this.icon,
    required this.title,
    required this.subtitle,
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
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            _SoftIcon(icon: icon),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(color: colors.onSurfaceVariant),
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

InputDecoration _inputDecoration(
    BuildContext context, {
      required String label,
      required IconData icon,
    }) {
  final colors = Theme.of(context).colorScheme;

  return InputDecoration(
    labelText: label,
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

Color _statusColor(String status) {
  final normalized = status.toLowerCase();
  if (normalized == 'pending' || normalized == 'reviewing') return Colors.orange;
  if (normalized == 'resolved' || normalized == 'approved' || normalized == 'completed') {
    return Colors.green;
  }
  if (normalized == 'rejected' || normalized == 'cancelled') return Colors.red;
  return Colors.blueGrey;
}