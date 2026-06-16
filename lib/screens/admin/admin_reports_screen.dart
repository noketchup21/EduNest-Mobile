import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_strings.dart';
import '../../models/mvp_models.dart';
import '../../providers/app_data_provider.dart';
import '../../widgets/error_banner.dart';

class AdminReportsScreen extends StatelessWidget {
  const AdminReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.text('Manage Reports')),
      ),
      body: const AdminReportsPanel(),
    );
  }
}

class AdminReportsPanel extends StatefulWidget {
  const AdminReportsPanel({super.key});

  @override
  State<AdminReportsPanel> createState() => _AdminReportsPanelState();
}

class _AdminReportsPanelState extends State<AdminReportsPanel> {
  final search = TextEditingController();

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppDataProvider>().adminLoadReports();
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
    final reports = data.adminReports;

    return DefaultTabController(
      length: _tabs.length,
      child: Column(
        children: [
          ErrorBanner(data.error),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: _SummaryRow(reports: reports),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: TextField(
              controller: search,
              decoration: InputDecoration(
                labelText: context.l10n.text('Search reports'),
                hintText: context.l10n.text(
                  'Search tutor, reporter, category, title, booking...',
                ),
                prefixIcon: const Icon(Icons.search),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          TabBar(
            isScrollable: true,
            tabs: [
              for (final tab in _tabs)
                Tab(
                  text:
                      '${context.l10n.text(tab.label)} (${_count(reports, tab.status)})',
                ),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                for (final tab in _tabs)
                  _AdminReportList(
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
          r.tutorName.toLowerCase().contains(q) ||
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

class _SummaryRow extends StatelessWidget {
  final List<TutorReportModel> reports;

  const _SummaryRow({
    required this.reports,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 82,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _SummaryCard(
            label: context.l10n.text('Total'),
            value: reports.length,
            icon: Icons.assignment_outlined,
            color: Colors.blueGrey,
          ),
          _SummaryCard(
            label: context.l10n.text('Pending'),
            value: _count('pending'),
            icon: Icons.pending_actions_outlined,
            color: Colors.orange,
          ),
          _SummaryCard(
            label: context.l10n.text('Reviewing'),
            value: _count('reviewing'),
            icon: Icons.manage_search_outlined,
            color: Colors.blue,
          ),
          _SummaryCard(
            label: context.l10n.text('Resolved'),
            value: _count('resolved'),
            icon: Icons.check_circle_outline,
            color: Colors.green,
          ),
          _SummaryCard(
            label: context.l10n.text('Rejected'),
            value: _count('rejected'),
            icon: Icons.cancel_outlined,
            color: Colors.red,
          ),
        ],
      ),
    );
  }

  int _count(String status) {
    return reports
        .where((r) => r.status.toLowerCase() == status.toLowerCase())
        .length;
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final int value;
  final IconData icon;
  final Color color;

  const _SummaryCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 136,
      margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withOpacity(0.14),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value.toString(),
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                  ),
                ),
                Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminReportList extends StatelessWidget {
  final List<TutorReportModel> reports;
  final bool loading;

  const _AdminReportList({
    required this.reports,
    required this.loading,
  });

  @override
  Widget build(BuildContext context) {
    if (loading && reports.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (reports.isEmpty) {
      return Center(
        child: Text(context.l10n.text('No reports found.')),
      );
    }

    return RefreshIndicator(
      onRefresh: () => context.read<AppDataProvider>().adminLoadReports(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: reports.length,
        itemBuilder: (context, index) {
          return _AdminReportCard(report: reports[index]);
        },
      ),
    );
  }
}

class _AdminReportCard extends StatelessWidget {
  final TutorReportModel report;

  const _AdminReportCard({
    required this.report,
  });

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(report.status);
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          context.push('/admin/report/${report.tutorReportId}');
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: color.withOpacity(0.12),
                    child: Icon(
                      Icons.report_outlined,
                      color: color,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      report.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  _StatusChip(status: report.status),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                report.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _MiniInfo(
                    icon: Icons.person_outline,
                    text: '${context.l10n.tutor}: ${report.tutorName}',
                  ),
                  _MiniInfo(
                    icon: Icons.account_circle_outlined,
                    text:
                        '${context.l10n.text('Reporter')}: ${report.reporterName}',
                  ),
                  _MiniInfo(
                    icon: Icons.category_outlined,
                    text: report.category,
                  ),
                  _MiniInfo(
                    icon: Icons.receipt_long_outlined,
                    text: context.l10n.bookingNumber(report.bookingId),
                  ),
                  _MiniInfo(
                    icon: Icons.schedule_outlined,
                    text: _formatDate(report.createdAt),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _formatDate(DateTime value) {
    final d = value.toLocal();

    String two(int n) => n.toString().padLeft(2, '0');

    return '${two(d.day)}/${two(d.month)}/${d.year}';
  }
}

class _MiniInfo extends StatelessWidget {
  final IconData icon;
  final String text;

  const _MiniInfo({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.6),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15),
          const SizedBox(width: 5),
          Text(
            text,
            style: const TextStyle(fontSize: 12),
          ),
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
