import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/mvp_models.dart';
import '../../providers/app_data_provider.dart';
import '../../widgets/error_banner.dart';
import '../../widgets/money_text.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppDataProvider>().adminLoadDashboard();
    });
  }

  @override
  Widget build(BuildContext context) {
    final data = context.watch<AppDataProvider>();
    final dashboard = data.adminDashboard;

    return DefaultTabController(
      length: 5,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Admin'),
          actions: [
            IconButton(
              onPressed: data.loading
                  ? null
                  : () => context.read<AppDataProvider>().adminLoadDashboard(),
              icon: const Icon(Icons.refresh),
            ),
          ],
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'Dashboard'),
              Tab(text: 'Subjects'),
              Tab(text: 'Tutors'),
              Tab(text: 'Payouts'),
              Tab(text: 'Reports'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            RefreshIndicator(
              onRefresh: data.adminLoadDashboard,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  ErrorBanner(data.error),
                  if (dashboard == null)
                    const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else ...[
                    _StatGrid(
                      items: [
                        _StatItem(
                          'Downloads',
                          dashboard.totalDownloads.toString(),
                          Icons.download_outlined,
                        ),
                        _StatItem(
                          'Installs',
                          dashboard.totalInstalls.toString(),
                          Icons.phone_android_outlined,
                        ),
                        _StatItem(
                          'Subjects',
                          dashboard.totalSubjects.toString(),
                          Icons.menu_book_outlined,
                        ),
                        _StatItem(
                          'Tutors',
                          dashboard.totalTutors.toString(),
                          Icons.school_outlined,
                        ),
                        _StatItem(
                          'Pending tutors',
                          dashboard.pendingTutors.toString(),
                          Icons.pending_actions_outlined,
                        ),
                        _StatItem(
                          'Approved tutors',
                          dashboard.approvedTutors.toString(),
                          Icons.verified_outlined,
                        ),
                        _StatItem(
                          'Pending payouts',
                          dashboard.pendingPayouts.toString(),
                          Icons.payments_outlined,
                        ),
                        _StatItem(
                          'Completed lessons',
                          dashboard.completedLessons.toString(),
                          Icons.check_circle_outline,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _MoneyStatCard(
                      title: 'Gross lesson revenue',
                      amount: dashboard.grossLessonRevenue,
                    ),
                    _MoneyStatCard(
                      title: 'Platform revenue 10%',
                      amount: dashboard.platformRevenue,
                    ),
                    _MoneyStatCard(
                      title: 'Tutor revenue 90%',
                      amount: dashboard.tutorRevenue,
                    ),
                    _MoneyStatCard(
                      title: 'Pending payout amount',
                      amount: dashboard.pendingPayoutAmount,
                    ),
                  ],
                ],
              ),
            ),
            const _SubjectsTab(),
            const _TutorsTab(),
            const _PayoutsTab(),
            const _ReportsTab(),
          ],
        ),
      ),
    );
  }
}

class _SubjectsTab extends StatefulWidget {
  const _SubjectsTab();

  @override
  State<_SubjectsTab> createState() => _SubjectsTabState();
}

class _SubjectsTabState extends State<_SubjectsTab> {
  final name = TextEditingController();
  final description = TextEditingController();

  @override
  void dispose() {
    name.dispose();
    description.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = context.watch<AppDataProvider>();

    return RefreshIndicator(
      onRefresh: data.adminLoadDashboard,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ErrorBanner(data.error),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextField(
                    controller: name,
                    decoration: const InputDecoration(
                      labelText: 'Subject name',
                      prefixIcon: Icon(Icons.menu_book_outlined),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: description,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      prefixIcon: Icon(Icons.description_outlined),
                    ),
                    minLines: 1,
                    maxLines: 3,
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: data.loading ? null : _submit,
                      icon: data.loading
                          ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                          : const Icon(Icons.add),
                      label: const Text('Add subject'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (data.subjects.isEmpty && !data.loading)
            const Card(
              child: ListTile(
                title: Text('No subjects yet'),
                subtitle: Text('Add your first subject above.'),
              ),
            ),
          ...data.subjects.map((subject) {
            return Card(
              child: ListTile(
                leading: const CircleAvatar(
                  child: Icon(Icons.menu_book_outlined),
                ),
                title: Text(
                  subject.name,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                subtitle: Text(
                  subject.description.isEmpty
                      ? 'No description'
                      : subject.description,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    final subjectName = name.text.trim();
    final subjectDescription = description.text.trim();

    if (subjectName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Subject name is required')),
      );
      return;
    }

    try {
      await context.read<AppDataProvider>().adminCreateSubject(
        name: subjectName,
        description: subjectDescription,
      );

      if (!mounted) return;

      name.clear();
      description.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Subject added')),
      );
    } catch (_) {}
  }
}

class _TutorsTab extends StatelessWidget {
  const _TutorsTab();

  @override
  Widget build(BuildContext context) {
    final data = context.watch<AppDataProvider>();

    final pending = data.adminTutors.where((t) {
      return t.verificationStatus.toLowerCase() == 'pending';
    }).toList();

    final rejected = data.adminTutors.where((t) {
      return t.verificationStatus.toLowerCase() == 'rejected';
    }).toList();

    final approved = data.adminTutors.where((t) {
      final status = t.verificationStatus.toLowerCase();
      return t.isVerified || status == 'approved';
    }).toList();

    final notSubmitted = data.adminTutors.where((t) {
      final status = t.verificationStatus.toLowerCase().replaceAll(' ', '');
      return status == 'notsubmitted' || status.isEmpty;
    }).toList();

    final others = data.adminTutors.where((t) {
      final status = t.verificationStatus.toLowerCase().replaceAll(' ', '');

      final isPending = status == 'pending';
      final isRejected = status == 'rejected';
      final isApproved = t.isVerified || status == 'approved';
      final isNotSubmitted = status == 'notsubmitted' || status.isEmpty;

      return !isPending && !isRejected && !isApproved && !isNotSubmitted;
    }).toList();

    return RefreshIndicator(
      onRefresh: data.adminLoadDashboard,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ErrorBanner(data.error),

          if (data.adminTutors.isEmpty && data.loading)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator()),
            ),

          if (data.adminTutors.isEmpty && !data.loading)
            const Card(
              child: ListTile(
                leading: Icon(Icons.school_outlined),
                title: Text('No tutors found'),
                subtitle: Text('Tutor accounts will appear here.'),
              ),
            ),

          _TutorStatusSection(
            title: 'Pending approval',
            icon: Icons.pending_actions_outlined,
            tutors: pending,
            emptyText: 'No pending tutors.',
            statusColor: Colors.orange,
            initiallyExpanded: true,
          ),

          _TutorStatusSection(
            title: 'Rejected',
            icon: Icons.cancel_outlined,
            tutors: rejected,
            emptyText: 'No rejected tutors.',
            statusColor: Colors.red,
          ),

          _TutorStatusSection(
            title: 'Approved',
            icon: Icons.verified_outlined,
            tutors: approved,
            emptyText: 'No approved tutors.',
            statusColor: Colors.green,
          ),

          _TutorStatusSection(
            title: 'Not submitted',
            icon: Icons.assignment_outlined,
            tutors: notSubmitted,
            emptyText: 'No not-submitted tutors.',
            statusColor: Colors.grey,
          ),

          if (others.isNotEmpty)
            _TutorStatusSection(
              title: 'Other status',
              icon: Icons.help_outline,
              tutors: others,
              emptyText: 'No tutors in this group.',
              statusColor: Colors.blueGrey,
            ),
        ],
      ),
    );
  }
}

class _TutorStatusSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<TutorVerificationModel> tutors;
  final String emptyText;
  final Color statusColor;
  final bool initiallyExpanded;

  const _TutorStatusSection({
    required this.title,
    required this.icon,
    required this.tutors,
    required this.emptyText,
    required this.statusColor,
    this.initiallyExpanded = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: ExpansionTile(
        initiallyExpanded: initiallyExpanded,
        leading: Icon(icon),
        title: Text(
          '$title (${tutors.length})',
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        children: [
          if (tutors.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(emptyText),
              ),
            ),
          ...tutors.map((tutor) {
            return _TutorListItem(
              tutor: tutor,
              statusColor: statusColor,
            );
          }),
        ],
      ),
    );
  }
}

class _TutorListItem extends StatelessWidget {
  final TutorVerificationModel tutor;
  final Color statusColor;

  const _TutorListItem({
    required this.tutor,
    required this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    final status = tutor.verificationStatus.isEmpty
        ? 'NotSubmitted'
        : tutor.verificationStatus;

    final lowerStatus = status.toLowerCase();
    final isPending = lowerStatus == 'pending';

    return ListTile(
      leading: CircleAvatar(
        child: Text(
          tutor.tutorName.isEmpty ? '?' : tutor.tutorName[0].toUpperCase(),
        ),
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              tutor.tutorName.isEmpty
                  ? 'Tutor #${tutor.tutorId}'
                  : tutor.tutorName,
              style: const TextStyle(fontWeight: FontWeight.w800),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          _StatusChip(
            label: status,
            color: statusColor,
          ),
        ],
      ),
      subtitle: Text(
        '${tutor.email}\n'
            'CCCD: ${tutor.nationalIdNumber ?? 'Not provided'}\n'
            'Bank: ${tutor.bankName ?? 'Not provided'}',
      ),
      isThreeLine: true,
      trailing: isPending
          ? PopupMenuButton<String>(
        onSelected: (value) {
          if (value == 'detail') {
            context.push('/admin/tutor/${tutor.tutorId}');
          }

          if (value == 'approve') {
            _confirmApprove(context, tutor.tutorId);
          }

          if (value == 'reject') {
            _showRejectDialog(context, tutor.tutorId);
          }
        },
        itemBuilder: (_) => const [
          PopupMenuItem(
            value: 'detail',
            child: Text('View detail'),
          ),
          PopupMenuItem(
            value: 'approve',
            child: Text('Approve'),
          ),
          PopupMenuItem(
            value: 'reject',
            child: Text('Reject'),
          ),
        ],
      )
          : const Icon(Icons.chevron_right),
      onTap: () => context.push('/admin/tutor/${tutor.tutorId}'),
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

    try {
      await context.read<AppDataProvider>().adminRejectTutor(
        tutorId: tutorId,
        reason: reason,
      );

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tutor rejected')),
      );
    } catch (_) {}
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusChip({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Chip(
      visualDensity: VisualDensity.compact,
      label: Text(
        label,
        style: const TextStyle(fontSize: 11),
      ),
      avatar: Icon(
        Icons.circle,
        size: 10,
        color: color,
      ),
    );
  }
}

class _PayoutsTab extends StatelessWidget {
  const _PayoutsTab();

  @override
  Widget build(BuildContext context) {
    final data = context.watch<AppDataProvider>();

    return RefreshIndicator(
      onRefresh: data.adminLoadDashboard,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ErrorBanner(data.error),
          if (data.adminPayouts.isEmpty && !data.loading)
            const Card(
              child: ListTile(
                leading: Icon(Icons.payments_outlined),
                title: Text('No payouts'),
                subtitle: Text('Tutor payout requests will appear here.'),
              ),
            ),
          ...data.adminPayouts.map((payout) {
            final isPending = payout.status.toLowerCase() == 'pending';

            return Card(
              child: ListTile(
                leading: const CircleAvatar(
                  child: Icon(Icons.payments_outlined),
                ),
                title: Text(
                  'Payout #${payout.payoutId}',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                subtitle: Text(
                  'Tutor #${payout.tutorId}\n'
                      'Status: ${payout.status}',
                ),
                isThreeLine: true,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    MoneyText(payout.amount),
                    const SizedBox(width: 8),
                    Icon(
                      isPending
                          ? Icons.pending_actions_outlined
                          : Icons.chevron_right,
                    ),
                  ],
                ),
                onTap: () => context.push('/admin/payout/${payout.payoutId}'),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _ReportsTab extends StatelessWidget {
  const _ReportsTab();

  @override
  Widget build(BuildContext context) {
    final data = context.watch<AppDataProvider>();

    return RefreshIndicator(
      onRefresh: () => data.adminLoadReports(),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ErrorBanner(data.error),
          if (data.adminReports.isEmpty && !data.loading)
            const Card(
              child: ListTile(
                leading: Icon(Icons.report_outlined),
                title: Text('No reports'),
                subtitle: Text('Tutor reports will appear here.'),
              ),
            ),
          ...data.adminReports.map((report) {
            final status = report.status.toLowerCase();

            return Card(
              child: ListTile(
                leading: CircleAvatar(
                  child: Icon(
                    status == 'pending'
                        ? Icons.pending_actions_outlined
                        : status == 'resolved'
                        ? Icons.check_circle_outline
                        : Icons.report_outlined,
                  ),
                ),
                title: Text(
                  report.title,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                subtitle: Text(
                  'Tutor: ${report.tutorName}\n'
                      'Reporter: ${report.reporterName}\n'
                      'Status: ${report.status}',
                ),
                isThreeLine: true,
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/admin/report/${report.tutorReportId}'),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _MoneyStatCard extends StatelessWidget {
  final String title;
  final double amount;

  const _MoneyStatCard({
    required this.title,
    required this.amount,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const CircleAvatar(
          child: Icon(Icons.attach_money),
        ),
        title: Text(title),
        trailing: MoneyText(amount),
      ),
    );
  }
}

class _StatGrid extends StatelessWidget {
  final List<_StatItem> items;

  const _StatGrid({
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      itemCount: items.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisExtent: 125,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemBuilder: (context, index) {
        final item = items[index];

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(item.icon, size: 22),
                const SizedBox(height: 6),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    item.value,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _StatItem {
  final String label;
  final String value;
  final IconData icon;

  _StatItem(
      this.label,
      this.value,
      this.icon,
      );
}