import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_strings.dart';
import '../../models/mvp_models.dart';
import '../../providers/app_data_provider.dart';
import '../../widgets/error_banner.dart';

const double _cardRadius = 22;

class MyReportsScreen extends StatefulWidget {
  const MyReportsScreen({super.key});

  @override
  State<MyReportsScreen> createState() => _MyReportsScreenState();
}

class _MyReportsScreenState extends State<MyReportsScreen> {
  String _statusFilter = 'All';

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppDataProvider>().loadMyReports();
    });
  }

  @override
  Widget build(BuildContext context) {
    final data = context.watch<AppDataProvider>();
    final reports = data.myReports;
    final visibleReports = _filteredReports(reports);
    final categories = _groupByCategory(visibleReports);
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        title: Text(
          context.l10n.myReports,
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
              onPressed: data.loading ? null : data.loadMyReports,
              icon: const Icon(Icons.refresh),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: data.loadMyReports,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            ErrorBanner(data.error),
            _ReportOverviewCard(reports: reports),
            const SizedBox(height: 14),
            _StatusFilterBar(
              selected: _statusFilter,
              reports: reports,
              onChanged: (value) => setState(() => _statusFilter = value),
            ),
            const SizedBox(height: 16),
            if (data.loading && reports.isEmpty)
              const _LoadingCard()
            else if (!data.loading && reports.isEmpty)
              const _EmptyReports()
            else if (visibleReports.isEmpty)
              _EmptyStateCard(
                icon: Icons.filter_alt_off_outlined,
                title: context.l10n.text('No reports found.'),
                subtitle: context.l10n
                    .text('Try another status filter to see more reports.'),
              )
            else
              ...categories.entries.map((entry) {
                return _ReportCategorySection(
                  category: entry.key,
                  reports: entry.value,
                );
              }),
          ],
        ),
      ),
    );
  }

  List<TutorReportModel> _filteredReports(List<TutorReportModel> reports) {
    if (_statusFilter == 'All') return reports;

    return reports.where((report) {
      return report.status.toLowerCase() == _statusFilter.toLowerCase();
    }).toList();
  }

  Map<String, List<TutorReportModel>> _groupByCategory(
    List<TutorReportModel> reports,
  ) {
    final grouped = <String, List<TutorReportModel>>{};

    for (final report in reports) {
      final category =
          report.category.trim().isEmpty ? 'Other' : report.category;
      grouped.putIfAbsent(category, () => []).add(report);
    }

    return grouped;
  }
}

class _ReportOverviewCard extends StatelessWidget {
  final List<TutorReportModel> reports;

  const _ReportOverviewCard({required this.reports});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final t = context.l10n;
    final pending = _countStatus(reports, 'Pending');
    final reviewing = _countStatus(reports, 'Reviewing');
    final resolved = _countStatus(reports, 'Resolved');
    final rejected = _countStatus(reports, 'Rejected');

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        color: colors.surface,
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _SoftIcon(icon: Icons.manage_search_outlined, size: 54),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.text('Report center'),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      t.text(
                        'Track tutor reports by review stage, category, proof, and admin response.',
                      ),
                      style: TextStyle(
                        height: 1.35,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.8,
            children: [
              _OverviewMetric(
                  label: t.text('Total'),
                  value: reports.length,
                  color: colors.primary),
              _OverviewMetric(
                  label: t.text('Pending'),
                  value: pending,
                  color: Colors.orange),
              _OverviewMetric(
                  label: t.text('Reviewing'),
                  value: reviewing,
                  color: Colors.blue),
              _OverviewMetric(
                label: t.text('Closed'),
                value: resolved + rejected,
                color: Colors.green,
              ),
            ],
          ),
        ],
      ),
    );
  }

  int _countStatus(List<TutorReportModel> reports, String status) {
    return reports.where((report) {
      return report.status.toLowerCase() == status.toLowerCase();
    }).length;
  }
}

class _OverviewMetric extends StatelessWidget {
  final String label;
  final int value;
  final Color color;

  const _OverviewMetric({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value.toString(),
            style: TextStyle(
              color: color,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color.withOpacity(0.85),
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusFilterBar extends StatelessWidget {
  final String selected;
  final List<TutorReportModel> reports;
  final ValueChanged<String> onChanged;

  const _StatusFilterBar({
    required this.selected,
    required this.reports,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    const statuses = ['All', 'Pending', 'Reviewing', 'Resolved', 'Rejected'];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final status in statuses) ...[
            ChoiceChip(
              selected: selected == status,
              label: Text('${t.text(status)} ${_count(status)}'),
              avatar: Icon(
                _statusIcon(status),
                size: 16,
                color: selected == status ? null : _statusColor(status),
              ),
              onSelected: (_) => onChanged(status),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }

  int _count(String status) {
    if (status == 'All') return reports.length;

    return reports.where((report) {
      return report.status.toLowerCase() == status.toLowerCase();
    }).length;
  }
}

class _ReportCategorySection extends StatelessWidget {
  final String category;
  final List<TutorReportModel> reports;

  const _ReportCategorySection({
    required this.category,
    required this.reports,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final t = context.l10n;

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  t.text(category),
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
              ),
              _MiniBadge(
                label: '${reports.length}',
                color: colors.primary,
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...reports.map((report) => _ReportCard(report: report)),
        ],
      ),
    );
  }
}

class _EmptyReports extends StatelessWidget {
  const _EmptyReports();

  @override
  Widget build(BuildContext context) {
    return _EmptyStateCard(
      icon: Icons.report_gmailerrorred_outlined,
      title: context.l10n.text('No reports yet'),
      subtitle: context.l10n.text(
        'Reports you submit about tutors will appear here with review progress.',
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  final TutorReportModel report;

  const _ReportCard({required this.report});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final t = context.l10n;
    final status = report.status.toLowerCase();
    final statusColor = _statusColor(status);

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
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
                _SoftIcon(icon: _statusIcon(status), color: statusColor),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        report.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        report.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          height: 1.35,
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _MiniBadge(
                  label: context.l10n.status(report.status),
                  color: statusColor,
                ),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _MetaChip(icon: Icons.school_outlined, label: report.tutorName),
                _MetaChip(
                  icon: Icons.menu_book_outlined,
                  label: report.subjectName ?? t.text('Unknown subject'),
                ),
                _MetaChip(
                    icon: Icons.event_note_outlined,
                    label: '${t.text('Booking')} #${report.bookingId}'),
                _MetaChip(
                    icon: Icons.image_outlined,
                    label: t.isVi
                        ? '${report.proofImages.length} bằng chứng'
                        : '${report.proofImages.length} proof${report.proofImages.length == 1 ? '' : 's'}'),
              ],
            ),
            const SizedBox(height: 16),
            _ReportProgress(status: status),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _DateTile(
                    label: t.text('Submitted'),
                    value: _formatDate(report.createdAt),
                    icon: Icons.schedule_outlined,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _DateTile(
                    label: report.reviewedAt == null
                        ? t.text('Last update')
                        : t.text('Reviewed'),
                    value: report.reviewedAt == null
                        ? t.text('Waiting')
                        : _formatDate(report.reviewedAt!),
                    icon: Icons.fact_check_outlined,
                  ),
                ),
              ],
            ),
            if (report.adminNote != null &&
                report.adminNote!.trim().isNotEmpty) ...[
              const SizedBox(height: 14),
              _AdminNote(note: report.adminNote!),
            ],
            if (report.proofImages.isNotEmpty) ...[
              const SizedBox(height: 14),
              _ProofImages(images: report.proofImages),
            ],
          ],
        ),
      ),
    );
  }
}

class _ReportProgress extends StatelessWidget {
  final String status;

  const _ReportProgress({required this.status});

  @override
  Widget build(BuildContext context) {
    final steps = _stepsForStatus(status);

    return Row(
      children: [
        for (var i = 0; i < steps.length; i++) ...[
          Expanded(child: _ProgressStep(step: steps[i])),
          if (i != steps.length - 1)
            Container(
              width: 16,
              height: 2,
              color: steps[i + 1].isActive
                  ? _statusColor(steps[i + 1].status)
                  : Colors.grey.shade300,
            ),
        ],
      ],
    );
  }

  List<_ProgressStepData> _stepsForStatus(String status) {
    if (status == 'rejected') {
      return const [
        _ProgressStepData(
            label: 'Submitted', status: 'pending', isActive: true),
        _ProgressStepData(
            label: 'Reviewing', status: 'reviewing', isActive: true),
        _ProgressStepData(
            label: 'Rejected', status: 'rejected', isActive: true),
      ];
    }

    final currentIndex = switch (status) {
      'reviewing' => 1,
      'resolved' => 2,
      _ => 0,
    };

    const labels = [
      ('Submitted', 'pending'),
      ('Reviewing', 'reviewing'),
      ('Resolved', 'resolved'),
    ];

    return [
      for (var i = 0; i < labels.length; i++)
        _ProgressStepData(
          label: labels[i].$1,
          status: labels[i].$2,
          isActive: i <= currentIndex,
        ),
    ];
  }
}

class _ProgressStep extends StatelessWidget {
  final _ProgressStepData step;

  const _ProgressStep({required this.step});

  @override
  Widget build(BuildContext context) {
    final color = step.isActive ? _statusColor(step.status) : Colors.grey;

    return Column(
      children: [
        CircleAvatar(
          radius: 14,
          backgroundColor: color.withOpacity(0.14),
          child: Icon(
            step.isActive ? Icons.check_rounded : Icons.circle_outlined,
            size: 17,
            color: color,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          context.l10n.text(step.label),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 11,
            fontWeight: step.isActive ? FontWeight.w800 : FontWeight.w500,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _ProgressStepData {
  final String label;
  final String status;
  final bool isActive;

  const _ProgressStepData({
    required this.label,
    required this.status,
    required this.isActive,
  });
}

class _AdminNote extends StatelessWidget {
  final String note;

  const _AdminNote({required this.note});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withOpacity(0.45),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant),
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
              note,
              style: TextStyle(color: theme.colorScheme.onPrimaryContainer),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProofImages extends StatelessWidget {
  final List<TutorReportProofImageModel> images;

  const _ProofImages({required this.images});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 76,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: images.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final image = images[index];

          return InkWell(
            onTap: () => _openImage(context, image.imageUrl),
            borderRadius: BorderRadius.circular(14),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.network(
                image.imageUrl,
                width: 76,
                height: 76,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) {
                  return Container(
                    width: 76,
                    height: 76,
                    color: Colors.grey.shade200,
                    child: const Icon(Icons.broken_image_outlined),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }

  void _openImage(BuildContext context, String url) {
    showDialog(
      context: context,
      builder: (_) {
        return Dialog(
          insetPadding: const EdgeInsets.all(16),
          child: InteractiveViewer(
            child: Image.network(
              url,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) {
                return Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(context.l10n.text('Could not load image')),
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class _DateTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _DateTile({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surfaceVariant.withOpacity(0.25),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: colors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: colors.onSurfaceVariant,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w900),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MetaChip({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: colors.surfaceVariant.withOpacity(0.25),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: colors.primary),
          const SizedBox(width: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 170),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _MiniBadge({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
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
                  Text(title,
                      style: const TextStyle(fontWeight: FontWeight.w900)),
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

IconData _statusIcon(String status) {
  switch (status.toLowerCase()) {
    case 'resolved':
      return Icons.check_circle_outline;
    case 'reviewing':
      return Icons.rate_review_outlined;
    case 'rejected':
      return Icons.cancel_outlined;
    case 'pending':
      return Icons.pending_actions_outlined;
    default:
      return Icons.report_outlined;
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
      return Colors.orange;
    default:
      return Colors.blueGrey;
  }
}

String _formatDate(DateTime value) {
  final date = value.toLocal();

  String two(int n) => n.toString().padLeft(2, '0');

  return '${two(date.day)}/${two(date.month)}/${date.year} '
      '${two(date.hour)}:${two(date.minute)}';
}
