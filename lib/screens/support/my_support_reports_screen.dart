import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/mvp_models.dart';
import '../../providers/app_data_provider.dart';
import '../../utils/support_report_categories.dart';
import '../../widgets/error_banner.dart';

class MySupportReportsScreen extends StatefulWidget {
  const MySupportReportsScreen({super.key});

  @override
  State<MySupportReportsScreen> createState() => _MySupportReportsScreenState();
}

class _MySupportReportsScreenState extends State<MySupportReportsScreen> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppDataProvider>().loadMySupportReports();
    });
  }

  @override
  Widget build(BuildContext context) {
    final data = context.watch<AppDataProvider>();
    final reports = data.supportReports;

    return DefaultTabController(
      length: _statuses.length,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'My Admin Support Reports',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          actions: [
            IconButton(
              onPressed: data.loading ? null : data.loadMySupportReports,
              icon: const Icon(Icons.refresh_rounded),
            ),
          ],
          bottom: TabBar(
            isScrollable: true,
            tabs: [
              for (final status in _statuses)
                Tab(text: '$status (${_count(reports, status)})'),
            ],
          ),
        ),
        body: Column(
          children: [
            ErrorBanner(data.error),
            Expanded(
              child: TabBarView(
                children: [
                  for (final status in _statuses)
                    _SupportReportList(
                      reports: _filter(reports, status),
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

  int _count(List<SupportReportModel> reports, String status) {
    if (status == 'All') return reports.length;

    return reports
        .where((r) => r.status.toLowerCase() == status.toLowerCase())
        .length;
  }

  List<SupportReportModel> _filter(
      List<SupportReportModel> reports,
      String status,
      ) {
    if (status == 'All') return reports;

    return reports
        .where((r) => r.status.toLowerCase() == status.toLowerCase())
        .toList();
  }
}

const _statuses = ['All', 'Pending', 'Reviewing', 'Resolved', 'Rejected'];

class _SupportReportList extends StatelessWidget {
  final List<SupportReportModel> reports;
  final bool loading;

  const _SupportReportList({
    required this.reports,
    required this.loading,
  });

  @override
  Widget build(BuildContext context) {
    if (loading && reports.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (reports.isEmpty) {
      return const Center(
        child: Text('No support reports found.'),
      );
    }

    return RefreshIndicator(
      onRefresh: () => context.read<AppDataProvider>().loadMySupportReports(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: reports.length,
        itemBuilder: (context, index) {
          return _SupportReportCard(report: reports[index]);
        },
      ),
    );
  }
}

class _SupportReportCard extends StatelessWidget {
  final SupportReportModel report;

  const _SupportReportCard({
    required this.report,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
          '${supportCategoryLabel(report.category)} • ${_formatDate(report.createdAt)}',
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
          _RelatedIds(report: report),
          const SizedBox(height: 12),
          _ProgressBox(status: report.status),
          if (report.adminNote != null &&
              report.adminNote!.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            _AdminNote(note: report.adminNote!),
          ],
        ],
      ),
    );
  }
}

class _RelatedIds extends StatelessWidget {
  final SupportReportModel report;

  const _RelatedIds({
    required this.report,
  });

  @override
  Widget build(BuildContext context) {
    final items = <String>[
      if (report.payoutId != null) 'Payout #${report.payoutId}',
      if (report.bookingId != null) 'Booking #${report.bookingId}',
      if (report.lessonId != null) 'Lesson #${report.lessonId}',
    ];

    if (items.isEmpty) {
      return const Align(
        alignment: Alignment.centerLeft,
        child: Text('No related IDs provided'),
      );
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final item in items)
            Chip(
              label: Text(item),
              avatar: const Icon(Icons.link_outlined, size: 16),
            ),
        ],
      ),
    );
  }
}

class _ProgressBox extends StatelessWidget {
  final String status;

  const _ProgressBox({
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final text = switch (status.toLowerCase()) {
      'pending' => 'Waiting for admin to review.',
      'reviewing' => 'Admin is checking your issue.',
      'resolved' => 'Admin has resolved this issue.',
      'rejected' => 'Admin rejected this report.',
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
              style: TextStyle(color: color, fontWeight: FontWeight.w700),
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
      child: Text('Admin note: $note'),
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

String _formatDate(DateTime value) {
  final d = value.toLocal();

  String two(int n) => n.toString().padLeft(2, '0');

  return '${two(d.day)}/${two(d.month)}/${d.year}';
}