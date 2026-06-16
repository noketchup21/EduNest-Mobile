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

  String roleFilter = 'All';

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
    final reports = data.adminSupportReports;

    return DefaultTabController(
      length: _statuses.length,
      child: Column(
        children: [
          ErrorBanner(data.error),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: search,
                    decoration: InputDecoration(
                      labelText: context.l10n.text('Search support reports'),
                      prefixIcon: const Icon(Icons.search),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 10),
                DropdownButton<String>(
                  value: roleFilter,
                  items: [
                    DropdownMenuItem(
                      value: 'All',
                      child: Text(context.l10n.text('All')),
                    ),
                    DropdownMenuItem(
                      value: 'Tutor',
                      child: Text(context.l10n.tutor),
                    ),
                    DropdownMenuItem(
                      value: 'Learner',
                      child: Text(context.l10n.text('Learner')),
                    ),
                    DropdownMenuItem(
                      value: 'Parent',
                      child: Text(context.l10n.parent),
                    ),
                  ],
                  onChanged: (value) async {
                    if (value == null) return;

                    setState(() => roleFilter = value);

                    await context
                        .read<AppDataProvider>()
                        .adminLoadSupportReports(
                          role: value == 'All' ? null : value,
                        );
                  },
                ),
              ],
            ),
          ),
          TabBar(
            isScrollable: true,
            tabs: [
              for (final status in _statuses)
                Tab(
                  text:
                      '${context.l10n.text(status)} (${_count(reports, status)})',
                ),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                for (final status in _statuses)
                  _AdminSupportReportList(
                    reports: _filter(reports, status, search.text),
                    loading: data.loading,
                    roleFilter: roleFilter,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  int _count(List<SupportReportModel> reports, String status) {
    if (status == 'All') return reports.length;

    return reports
        .where((r) => r.status.toLowerCase() == status.toLowerCase())
        .length;
  }

  List<SupportReportModel> _filter(
    List<SupportReportModel> reports,
    String status,
    String query,
  ) {
    var result = status == 'All'
        ? reports
        : reports
            .where((r) => r.status.toLowerCase() == status.toLowerCase())
            .toList();

    final q = query.trim().toLowerCase();

    if (q.isEmpty) return result;

    return result.where((r) {
      return r.title.toLowerCase().contains(q) ||
          r.description.toLowerCase().contains(q) ||
          r.category.toLowerCase().contains(q) ||
          r.userName.toLowerCase().contains(q) ||
          r.userEmail.toLowerCase().contains(q) ||
          r.supportReportId.toString().contains(q);
    }).toList();
  }
}

const _statuses = ['All', 'Pending', 'Reviewing', 'Resolved', 'Rejected'];

class _AdminSupportReportList extends StatelessWidget {
  final List<SupportReportModel> reports;
  final bool loading;
  final String roleFilter;

  const _AdminSupportReportList({
    required this.reports,
    required this.loading,
    required this.roleFilter,
  });

  @override
  Widget build(BuildContext context) {
    if (loading && reports.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (reports.isEmpty) {
      return Center(
          child: Text(context.l10n.text('No support reports found.')));
    }

    return RefreshIndicator(
      onRefresh: () {
        return context.read<AppDataProvider>().adminLoadSupportReports(
              role: roleFilter == 'All' ? null : roleFilter,
            );
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: reports.length,
        itemBuilder: (context, index) {
          return _AdminSupportReportCard(report: reports[index]);
        },
      ),
    );
  }
}

class _AdminSupportReportCard extends StatelessWidget {
  final SupportReportModel report;

  const _AdminSupportReportCard({
    required this.report,
  });

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(report.status);
    final theme = Theme.of(context);

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
        trailing: _StatusChip(status: report.status),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              report.description,
              style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
            ),
          ),
          const SizedBox(height: 12),
          _InfoRow(label: 'Report ID', value: '#${report.supportReportId}'),
          _InfoRow(label: 'User', value: report.userName),
          _InfoRow(label: 'Email', value: report.userEmail),
          _InfoRow(label: 'Role', value: report.role),
          _InfoRow(
            label: 'Category',
            value: supportCategoryLabel(report.category),
          ),
          if (report.payoutId != null)
            _InfoRow(label: 'Payout', value: '#${report.payoutId}'),
          if (report.bookingId != null)
            _InfoRow(label: 'Booking', value: '#${report.bookingId}'),
          if (report.lessonId != null)
            _InfoRow(label: 'Lesson', value: '#${report.lessonId}'),
          if (report.adminNote != null && report.adminNote!.trim().isNotEmpty)
            _InfoRow(label: 'Admin note', value: report.adminNote!),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => _showStatusDialog(context, report),
              icon: const Icon(Icons.edit_outlined),
              label: Text(context.l10n.text('Update Status')),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showStatusDialog(
    BuildContext context,
    SupportReportModel report,
  ) async {
    final result = await showDialog<_SupportStatusUpdate>(
      context: context,
      builder: (_) => _StatusDialog(report: report),
    );

    if (result == null || !context.mounted) return;

    try {
      await context.read<AppDataProvider>().adminUpdateSupportReportStatus(
            supportReportId: report.supportReportId,
            status: result.status,
            adminNote: result.adminNote,
          );

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(AppStrings.of(context, listen: false)
                .text('Support report updated'))),
      );
    } catch (_) {}
  }
}

class _StatusDialog extends StatefulWidget {
  final SupportReportModel report;

  const _StatusDialog({
    required this.report,
  });

  @override
  State<_StatusDialog> createState() => _StatusDialogState();
}

class _StatusDialogState extends State<_StatusDialog> {
  late String status;
  late TextEditingController adminNote;

  @override
  void initState() {
    super.initState();
    status = widget.report.status.isEmpty ? 'Pending' : widget.report.status;
    adminNote = TextEditingController(text: widget.report.adminNote ?? '');
  }

  @override
  void dispose() {
    adminNote.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(context.l10n.text('Update support report')),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<String>(
            value: status,
            decoration: InputDecoration(labelText: context.l10n.text('Status')),
            items: [
              DropdownMenuItem(
                value: 'Pending',
                child: Text(context.l10n.text('Pending')),
              ),
              DropdownMenuItem(
                value: 'Reviewing',
                child: Text(context.l10n.text('Reviewing')),
              ),
              DropdownMenuItem(
                value: 'Resolved',
                child: Text(context.l10n.text('Resolved')),
              ),
              DropdownMenuItem(
                value: 'Rejected',
                child: Text(context.l10n.text('Rejected')),
              ),
            ],
            onChanged: (value) {
              if (value == null) return;
              setState(() => status = value);
            },
          ),
          const SizedBox(height: 12),
          TextField(
            controller: adminNote,
            decoration: InputDecoration(
              labelText: context.l10n.text('Admin note'),
              hintText: context.l10n.text('Explain the result to the tutor'),
            ),
            minLines: 3,
            maxLines: 5,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(context.l10n.cancel),
        ),
        FilledButton(
          onPressed: () {
            Navigator.of(context).pop(
              _SupportStatusUpdate(
                status: status,
                adminNote: adminNote.text.trim(),
              ),
            );
          },
          child: Text(context.l10n.text('Save')),
        ),
      ],
    );
  }
}

class _SupportStatusUpdate {
  final String status;
  final String adminNote;

  const _SupportStatusUpdate({
    required this.status,
    required this.adminNote,
  });
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
            width: 92,
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

class _StatusChip extends StatelessWidget {
  final String status;

  const _StatusChip({
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(status);

    return Chip(
      label: Text(
        context.l10n.status(status),
        style: TextStyle(color: color, fontWeight: FontWeight.w800),
      ),
      backgroundColor: color.withOpacity(0.12),
      side: BorderSide(color: color.withOpacity(0.35)),
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
