import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/mvp_models.dart';
import '../../providers/app_data_provider.dart';
import '../../widgets/error_banner.dart';

class AdminReportDetailScreen extends StatefulWidget {
  final int reportId;

  const AdminReportDetailScreen({
    super.key,
    required this.reportId,
  });

  @override
  State<AdminReportDetailScreen> createState() =>
      _AdminReportDetailScreenState();
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

    return Scaffold(
      appBar: AppBar(
        title: Text('Report #${widget.reportId}'),
        actions: [
          IconButton(
            onPressed: data.loading
                ? null
                : () => data.adminLoadReportDetail(widget.reportId),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => data.adminLoadReportDetail(widget.reportId),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            ErrorBanner(data.error),
            if (report == null)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              )
            else ...[
              _ReportHeader(report: report),
              const SizedBox(height: 12),
              _InfoCard(report: report),
              const SizedBox(height: 12),
              _AdminReportTutorCard(report: report),
              const SizedBox(height: 12),
              _ProofImages(report: report),
              const SizedBox(height: 12),
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
    return Card(
      child: ListTile(
        leading: const CircleAvatar(
          child: Icon(Icons.report_outlined),
        ),
        title: Text(
          report.title,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        subtitle: Text(
          'Status: ${report.status}\nCategory: ${report.category}',
        ),
        isThreeLine: true,
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final TutorReportModel report;

  const _InfoCard({required this.report});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _row('Tutor', report.tutorName),
            _row('Reporter', report.reporterName),
            _row('Booking ID', '#${report.bookingId}'),
            _row('Availability ID', '#${report.availabilityId}'),
            if (report.lessonId != null)
              _row('Lesson ID', '#${report.lessonId}'),
            if (report.subjectName != null)
              _row('Subject', report.subjectName!),
            const Divider(height: 24),
            const Text(
              'Description',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(report.description),
            if (report.adminNote != null &&
                report.adminNote!.trim().isNotEmpty) ...[
              const Divider(height: 24),
              const Text(
                'Admin note',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              Text(report.adminNote!),
            ],
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

class _ProofImages extends StatelessWidget {
  final TutorReportModel report;

  const _ProofImages({required this.report});

  @override
  Widget build(BuildContext context) {
    if (report.proofImages.isEmpty) {
      return const Card(
        child: ListTile(
          leading: Icon(Icons.image_not_supported_outlined),
          title: Text('No proof images'),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: report.proofImages.map((img) {
            return ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                img.imageUrl,
                width: 120,
                height: 120,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) {
                  return Container(
                    width: 120,
                    height: 120,
                    alignment: Alignment.center,
                    child: const Icon(Icons.broken_image_outlined),
                  );
                },
              ),
            );
          }).toList(),
        ),
      ),
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

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _note,
              decoration: const InputDecoration(
                labelText: 'Admin note optional',
                prefixIcon: Icon(Icons.note_alt_outlined),
              ),
              minLines: 1,
              maxLines: 4,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: data.loading
                        ? null
                        : () => _update(context, 'Reviewing'),
                    child: const Text('Reviewing'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton(
                    onPressed: data.loading
                        ? null
                        : () => _update(context, 'Resolved'),
                    child: const Text('Resolved'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: data.loading
                    ? null
                    : () => _update(context, 'Rejected'),
                icon: const Icon(Icons.close),
                label: const Text('Reject report'),
              ),
            ),
          ],
        ),
      ),
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

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Reported tutor',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 12),

            _row('Tutor name', report.tutorName),
            _row('Tutor ID', '#${report.tutorId}'),
            _row('Tutor user ID', '#${report.tutorUserId}'),

            if (report.tutorEmail != null)
              _row('Email', report.tutorEmail!),

            if (report.tutorPhone != null)
              _row('Phone', report.tutorPhone!),

            if (report.tutorVerificationStatus != null)
              _row('Verification', report.tutorVerificationStatus!),

            _row(
              'Account status',
              isActive ? 'Active' : 'Deactivated',
            ),

            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: data.loading
                    ? null
                    : () => _confirmTutorAccountStatus(
                  context,
                  report: report,
                  isActive: !isActive,
                ),
                icon: Icon(
                  isActive ? Icons.block : Icons.check_circle_outline,
                ),
                label: Text(
                  isActive ? 'Deactivate tutor account' : 'Activate tutor account',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
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
          title: Text(
            isActive ? 'Activate tutor?' : 'Deactivate tutor?',
          ),
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
          content: Text(
            isActive
                ? 'Tutor account activated'
                : 'Tutor account deactivated',
          ),
        ),
      );
    } catch (_) {}
  }
}