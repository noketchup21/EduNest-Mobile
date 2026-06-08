import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/mvp_models.dart';
import '../../providers/app_data_provider.dart';
import '../../widgets/error_banner.dart';

class TutorReportsScreen extends StatefulWidget {
  const TutorReportsScreen({super.key});

  @override
  State<TutorReportsScreen> createState() => _TutorReportsScreenState();
}

class _TutorReportsScreenState extends State<TutorReportsScreen> {
  final search = TextEditingController();

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppDataProvider>().loadTutorReports();
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
    final reports = data.tutorReports;

    return DefaultTabController(
      length: _tabs.length,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Reports About Me',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          actions: [
            IconButton(
              onPressed: data.loading ? null : data.loadTutorReports,
              icon: const Icon(Icons.refresh_rounded),
            ),
          ],
          bottom: TabBar(
            isScrollable: true,
            tabs: [
              for (final tab in _tabs)
                Tab(
                  text: '${tab.label} (${_count(reports, tab.status)})',
                ),
            ],
          ),
        ),
        body: Column(
          children: [
            ErrorBanner(data.error),
            Padding(
              padding: const EdgeInsets.all(12),
              child: TextField(
                controller: search,
                decoration: const InputDecoration(
                  labelText: 'Search reports',
                  hintText: 'Search by title, category, reporter, booking...',
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  for (final tab in _tabs)
                    _ReportList(
                      reports: _filter(
                        reports,
                        status: tab.status,
                        query: search.text,
                      ),
                      loading: data.loading,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<TutorReportModel> _filter(
      List<TutorReportModel> reports, {
        required String status,
        required String query,
      }) {
    var result = status == 'all'
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
          r.reporterName.toLowerCase().contains(q) ||
          r.bookingId.toString().contains(q) ||
          r.tutorReportId.toString().contains(q);
    }).toList();
  }

  int _count(List<TutorReportModel> reports, String status) {
    if (status == 'all') return reports.length;

    return reports
        .where((r) => r.status.toLowerCase() == status.toLowerCase())
        .length;
  }
}

const _tabs = [
  _ReportTab('All', 'all'),
  _ReportTab('Pending', 'pending'),
  _ReportTab('Reviewing', 'reviewing'),
  _ReportTab('Resolved', 'resolved'),
  _ReportTab('Rejected', 'rejected'),
];

class _ReportTab {
  final String label;
  final String status;

  const _ReportTab(this.label, this.status);
}

class _ReportList extends StatelessWidget {
  final List<TutorReportModel> reports;
  final bool loading;

  const _ReportList({
    required this.reports,
    required this.loading,
  });

  @override
  Widget build(BuildContext context) {
    if (loading && reports.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (reports.isEmpty) {
      return const _EmptyReports();
    }

    return RefreshIndicator(
      onRefresh: () => context.read<AppDataProvider>().loadTutorReports(),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
        itemCount: reports.length,
        itemBuilder: (context, index) {
          return _TutorReportCard(report: reports[index]);
        },
      ),
    );
  }
}

class _EmptyReports extends StatelessWidget {
  const _EmptyReports();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Icon(
                  Icons.verified_user_outlined,
                  size: 56,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: 12),
                Text(
                  'No reports found',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Reports submitted by learners about your tutoring sessions will appear here.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _TutorReportCard extends StatelessWidget {
  final TutorReportModel report;

  const _TutorReportCard({
    required this.report,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = report.status.toLowerCase();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        leading: CircleAvatar(
          backgroundColor: _statusColor(status).withOpacity(0.12),
          child: Icon(
            Icons.report_outlined,
            color: _statusColor(status),
          ),
        ),
        title: Text(
          report.title,
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        subtitle: Text(
          '${report.category} • Booking #${report.bookingId}',
        ),
        trailing: _StatusChip(status: report.status),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              report.description,
              style: TextStyle(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(height: 12),
          _InfoRow(
            icon: Icons.person_outline,
            label: 'Reporter',
            value: report.reporterName,
          ),
          _InfoRow(
            icon: Icons.menu_book_outlined,
            label: 'Subject',
            value: report.subjectName ?? 'Unknown subject',
          ),
          _InfoRow(
            icon: Icons.schedule_outlined,
            label: 'Submitted',
            value: _formatDate(report.createdAt),
          ),
          if (report.reviewedAt != null)
            _InfoRow(
              icon: Icons.fact_check_outlined,
              label: 'Reviewed',
              value: _formatDate(report.reviewedAt!),
            ),
          const SizedBox(height: 12),
          _ProgressBox(status: status),
          if (report.adminNote != null &&
              report.adminNote!.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            _AdminNote(note: report.adminNote!),
          ],
        ],
      ),
    );
  }

  static String _formatDate(DateTime value) {
    final d = value.toLocal();

    String two(int n) => n.toString().padLeft(2, '0');

    return '${two(d.day)}/${two(d.month)}/${d.year} '
        '${two(d.hour)}:${two(d.minute)}';
  }
}

class _ProgressBox extends StatelessWidget {
  final String status;

  const _ProgressBox({
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final text = switch (status) {
      'pending' => 'Waiting for admin review.',
      'reviewing' => 'Admin is reviewing the evidence.',
      'resolved' => 'The report has been processed.',
      'rejected' => 'The report was rejected.',
      _ => 'Current status: $status',
    };

    final color = _statusColor(status);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.timeline_outlined, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminNote extends StatelessWidget {
  final String note;

  const _AdminNote({
    required this.note,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withOpacity(0.45),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.admin_panel_settings_outlined,
            color: theme.colorScheme.onPrimaryContainer,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Admin note: $note',
              style: TextStyle(
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 84,
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
        status,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
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