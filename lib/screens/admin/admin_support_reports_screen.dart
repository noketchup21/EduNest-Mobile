import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_strings.dart';
import '../../models/mvp_models.dart';
import '../../providers/app_data_provider.dart';
import '../../utils/support_report_categories.dart';
import '../../widgets/error_banner.dart';

class AdminSupportReportsScreen extends StatelessWidget {
  const AdminSupportReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.text('Support Reports')),
      ),
      body: const AdminSupportReportsPanel(),
    );
  }
}

class AdminSupportReportsPanel extends StatefulWidget {
  const AdminSupportReportsPanel({super.key});

  @override
  State<AdminSupportReportsPanel> createState() =>
      _AdminSupportReportsPanelState();
}

class _AdminSupportReportsPanelState extends State<AdminSupportReportsPanel> {
  final search = TextEditingController();

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppDataProvider>().adminLoadSupportReports();
    });
  }

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = context.watch<AppDataProvider>();
    final reports = _filtered(data.adminSupportReports);

    return Column(
      children: [
        ErrorBanner(data.error),
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            controller: search,
            decoration: InputDecoration(
              labelText: context.l10n.text('Search tutor support reports'),
              prefixIcon: const Icon(Icons.search),
            ),
            onChanged: (_) => setState(() {}),
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () =>
                context.read<AppDataProvider>().adminLoadSupportReports(),
            child: data.loading && reports.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : reports.isEmpty
                    ? Center(
                        child: Text(
                            context.l10n.text('No support reports found.')),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: reports.length,
                        itemBuilder: (context, index) {
                          return _SupportReportCard(report: reports[index]);
                        },
                      ),
          ),
        ),
      ],
    );
  }

  List<SupportReportModel> _filtered(List<SupportReportModel> reports) {
    final q = search.text.trim().toLowerCase();

    if (q.isEmpty) return reports;

    return reports.where((r) {
      return r.title.toLowerCase().contains(q) ||
          r.description.toLowerCase().contains(q) ||
          r.category.toLowerCase().contains(q) ||
          r.status.toLowerCase().contains(q) ||
          r.userName.toLowerCase().contains(q) ||
          r.userEmail.toLowerCase().contains(q) ||
          r.supportReportId.toString().contains(q);
    }).toList();
  }
}

class _SupportReportCard extends StatelessWidget {
  final SupportReportModel report;

  const _SupportReportCard({
    required this.report,
  });

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(report.status);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.12),
          child: Icon(Icons.support_agent_outlined, color: color),
        ),
        title: Text(
          report.title,
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        subtitle: Text(
          '${report.role} • ${supportCategoryLabel(report.category)} • ${report.userName}',
        ),
        trailing: Chip(
          label: Text(context.l10n.status(report.status)),
          backgroundColor: color.withOpacity(0.12),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(report.description),
          ),
          const SizedBox(height: 12),
          _InfoRow(
              label: context.l10n.text('Report ID'),
              value: '#${report.supportReportId}'),
          _InfoRow(
              label: context.l10n.text('Tutor/User'), value: report.userName),
          _InfoRow(label: context.l10n.text('Email'), value: report.userEmail),
          _InfoRow(
              label: context.l10n.text('Category'),
              value: supportCategoryLabel(report.category)),
          if (report.payoutId != null)
            _InfoRow(
                label: context.l10n.text('Payout'),
                value: '#${report.payoutId}'),
          if (report.bookingId != null)
            _InfoRow(
                label: context.l10n.text('Booking'),
                value: '#${report.bookingId}'),
          if (report.lessonId != null)
            _InfoRow(
                label: context.l10n.text('Lesson'),
                value: '#${report.lessonId}'),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => _showUpdateDialog(context),
              icon: const Icon(Icons.edit_outlined),
              label: Text(context.l10n.text('Update Status')),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showUpdateDialog(BuildContext context) async {
    var status = report.status.isEmpty ? 'Pending' : report.status;
    final note = TextEditingController(text: report.adminNote ?? '');

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(AppStrings.of(context, listen: false)
                  .text('Update Support Report')),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: status,
                    decoration: InputDecoration(
                        labelText: AppStrings.of(context, listen: false)
                            .text('Status')),
                    items: [
                      DropdownMenuItem(
                        value: 'Pending',
                        child: Text(AppStrings.of(context, listen: false)
                            .text('Pending')),
                      ),
                      DropdownMenuItem(
                        value: 'Reviewing',
                        child: Text(AppStrings.of(context, listen: false)
                            .text('Reviewing')),
                      ),
                      DropdownMenuItem(
                        value: 'Resolved',
                        child: Text(AppStrings.of(context, listen: false)
                            .text('Resolved')),
                      ),
                      DropdownMenuItem(
                        value: 'Rejected',
                        child: Text(AppStrings.of(context, listen: false)
                            .text('Rejected')),
                      ),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      setDialogState(() => status = value);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: note,
                    decoration: InputDecoration(
                      labelText: AppStrings.of(context, listen: false)
                          .text('Admin note'),
                    ),
                    minLines: 3,
                    maxLines: 5,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: Text(AppStrings.of(context, listen: false).cancel),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  child:
                      Text(AppStrings.of(context, listen: false).text('Save')),
                ),
              ],
            );
          },
        );
      },
    );

    if (confirmed != true || !context.mounted) return;

    await context.read<AppDataProvider>().adminUpdateSupportReportStatus(
          supportReportId: report.supportReportId,
          status: status,
          adminNote: note.text.trim(),
        );

    note.dispose();
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

Color _statusColor(String status) {
  switch (status.toLowerCase()) {
    case 'resolved':
      return Colors.green;
    case 'reviewing':
      return Colors.blue;
    case 'rejected':
      return Colors.red;
    case 'pending':
    default:
      return Colors.orange;
  }
}
