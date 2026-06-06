// admin_screen.dart
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/mvp_models.dart';
import '../../providers/app_data_provider.dart';
import '../../widgets/error_banner.dart';
import '../../widgets/money_text.dart';

const double _cardRadius = 22;

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
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return DefaultTabController(
      length: 5,
      child: Scaffold(
        backgroundColor: colors.surface,
        appBar: AppBar(
          title: const Text(
            'Admin Console',
            style: TextStyle(fontWeight: FontWeight.w900),
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
                    : () => context.read<AppDataProvider>().adminLoadDashboard(),
                icon: const Icon(Icons.refresh),
              ),
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(62),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Container(
                height: 50,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: colors.surfaceVariant.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: TabBar(
                  isScrollable: false,
                  dividerColor: Colors.transparent,
                  indicator: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: colors.outlineVariant),
                    boxShadow: [
                      BoxShadow(
                        color: colors.shadow.withOpacity(0.06),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  labelColor: colors.primary,
                  unselectedLabelColor: colors.onSurfaceVariant,
                  labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                  unselectedLabelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                  tabs: const [
                    Tab(icon: Icon(Icons.dashboard_outlined, size: 18), text: 'Dashboard'),
                    Tab(icon: Icon(Icons.menu_book_outlined, size: 18), text: 'Subjects'),
                    Tab(icon: Icon(Icons.school_outlined, size: 18), text: 'Tutors'),
                    Tab(icon: Icon(Icons.payments_outlined, size: 18), text: 'Payouts'),
                    Tab(icon: Icon(Icons.report_outlined, size: 18), text: 'Reports'),
                  ],
                ),
              ),
            ),
          ),
        ),
        body: TabBarView(
          children: [
            RefreshIndicator(
              onRefresh: data.adminLoadDashboard,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                children: [
                  ErrorBanner(data.error),
                  if (dashboard == null)
                    const _LoadingCard()
                  else ...[
                    // ── Key metrics ──────────────────────────────────────
                    const _DashSectionLabel(label: 'Key metrics'),
                    const SizedBox(height: 8),
                    Builder(
                      builder: (context) {
                        final metricCards = [
                          _MetricCard(
                            icon: Icons.download_outlined,
                            iconColor: const Color(0xFF534AB7),
                            iconBg: const Color(0xFFEEEDFE),
                            label: 'Downloads',
                            value: dashboard.totalDownloads.toString(),
                          ),
                          _MetricCard(
                            icon: Icons.phone_android_outlined,
                            iconColor: const Color(0xFF0F6E56),
                            iconBg: const Color(0xFFE1F5EE),
                            label: 'Installs',
                            value: dashboard.totalInstalls.toString(),
                          ),
                          _MetricCard(
                            icon: Icons.pending_actions_outlined,
                            iconColor: const Color(0xFF854F0B),
                            iconBg: const Color(0xFFFAEEDA),
                            label: 'Pending tutors',
                            value: dashboard.pendingTutors.toString(),
                            badge: dashboard.pendingTutors > 0 ? 'Needs review' : null,
                            badgeColor: const Color(0xFF854F0B),
                            badgeBg: const Color(0xFFFAEEDA),
                          ),
                          _MetricCard(
                            icon: Icons.payments_outlined,
                            iconColor: const Color(0xFFA32D2D),
                            iconBg: const Color(0xFFFCEBEB),
                            label: 'Pending payouts',
                            value: dashboard.pendingPayouts.toString(),
                            badge: dashboard.pendingPayouts > 0 ? 'Action needed' : null,
                            badgeColor: const Color(0xFFA32D2D),
                            badgeBg: const Color(0xFFFCEBEB),
                          ),
                        ];

                        return GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: metricCards.length,
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisExtent: 148,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                          ),
                          itemBuilder: (context, index) {
                            return metricCards[index];
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 20),

                    // ── Revenue breakdown ────────────────────────────────
                    _DashCard(
                      title: 'Revenue breakdown',
                      subtitle: 'Gross · platform 10% · tutor 90%',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              _RevStat(
                                label: 'Gross revenue',
                                value: dashboard.grossLessonRevenue,
                              ),
                              _RevStat(
                                label: 'Platform (10%)',
                                value: dashboard.platformRevenue,
                                color: const Color(0xFF534AB7),
                              ),
                              _RevStat(
                                label: 'Pending payout',
                                value: dashboard.pendingPayoutAmount,
                                color: const Color(0xFF854F0B),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            height: 160,
                            child: _RevenueBarChart(
                              gross: dashboard.grossLessonRevenue,
                              platform: dashboard.platformRevenue,
                              tutor: dashboard.tutorRevenue,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ── Tutor status ─────────────────────────────────────
                    _DashCard(
                      title: 'Tutor verification status',
                      subtitle: 'Across all registered tutors',
                      child: Row(
                        children: [
                          SizedBox(
                            width: 110,
                            height: 110,
                            child: _TutorDonutChart(
                              approved: dashboard.approvedTutors,
                              pending: dashboard.pendingTutors,
                              total: dashboard.totalTutors,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _TutorStatusBars(
                              total: dashboard.totalTutors,
                              approved: dashboard.approvedTutors,
                              pending: dashboard.pendingTutors,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ── Completed lessons ────────────────────────────────
                    _DashCard(
                      title: 'Lesson activity',
                      subtitle: 'Completed lessons total',
                      child: Row(
                        children: [
                          _BigStat(
                            value: dashboard.completedLessons.toString(),
                            label: 'completed lessons',
                            icon: Icons.check_circle_outline,
                            color: const Color(0xFF534AB7),
                          ),
                          const SizedBox(width: 16),
                          _BigStat(
                            value: dashboard.totalSubjects.toString(),
                            label: 'subjects active',
                            icon: Icons.menu_book_outlined,
                            color: const Color(0xFF0F6E56),
                          ),
                        ],
                      ),
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
    final colors = Theme.of(context).colorScheme;

    return RefreshIndicator(
      onRefresh: data.adminLoadDashboard,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          ErrorBanner(data.error),
          _AdminHeroCard(
            title: 'Subject management',
            subtitle: 'Create and review subjects that tutors can teach on the platform.',
            icon: Icons.menu_book_outlined,
            trailing: _CountBadge(count: data.subjects.length, label: 'subjects'),
          ),
          const SizedBox(height: 16),
          _PanelCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const _SectionTitle(
                  title: 'Add new subject',
                  subtitle: 'Keep names short and descriptions clear',
                  icon: Icons.add_circle_outline,
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: name,
                  decoration: _adminInputDecoration(
                    context,
                    label: 'Subject name',
                    icon: Icons.menu_book_outlined,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: description,
                  decoration: _adminInputDecoration(
                    context,
                    label: 'Description',
                    icon: Icons.description_outlined,
                  ),
                  minLines: 1,
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 50,
                  child: FilledButton.icon(
                    onPressed: data.loading ? null : _submit,
                    style: FilledButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    icon: data.loading
                        ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                        : const Icon(Icons.add),
                    label: const Text(
                      'Add subject',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const _SectionTitle(
            title: 'Current subjects',
            subtitle: 'Subjects available in the platform catalog',
            icon: Icons.list_alt_outlined,
          ),
          const SizedBox(height: 10),
          if (data.subjects.isEmpty && !data.loading)
            const _EmptyStateCard(
              icon: Icons.menu_book_outlined,
              title: 'No subjects yet',
              subtitle: 'Add your first subject above.',
            ),
          ...data.subjects.map((subject) {
            return Card(
              elevation: 0,
              margin: const EdgeInsets.only(bottom: 10),
              color: colors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(_cardRadius),
                side: BorderSide(color: colors.outlineVariant),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: _SoftIcon(icon: Icons.menu_book_outlined),
                title: Text(
                  subject.name,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    subject.description.isEmpty ? 'No description' : subject.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
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
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          ErrorBanner(data.error),
          _AdminHeroCard(
            title: 'Tutor verification',
            subtitle: 'Review submitted tutors, approve valid profiles, or reject incomplete applications.',
            icon: Icons.school_outlined,
            trailing: _CountBadge(count: data.adminTutors.length, label: 'tutors'),
          ),
          const SizedBox(height: 16),
          if (data.adminTutors.isEmpty && data.loading) const _LoadingCard(),
          if (data.adminTutors.isEmpty && !data.loading)
            const _EmptyStateCard(
              icon: Icons.school_outlined,
              title: 'No tutors found',
              subtitle: 'Tutor accounts will appear here.',
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
    final colors = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      color: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_cardRadius),
        side: BorderSide(color: colors.outlineVariant),
      ),
      child: ExpansionTile(
        initiallyExpanded: initiallyExpanded,
        leading: _SoftIcon(icon: icon, color: statusColor),
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        title: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
            _StatusPill(
              label: tutors.length.toString(),
              color: statusColor,
            ),
          ],
        ),
        children: [
          if (tutors.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 14),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  emptyText,
                  style: TextStyle(color: colors.onSurfaceVariant),
                ),
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
    final colors = Theme.of(context).colorScheme;
    final status = tutor.verificationStatus.isEmpty ? 'NotSubmitted' : tutor.verificationStatus;
    final lowerStatus = status.toLowerCase();
    final isPending = lowerStatus == 'pending';

    return Container(
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: colors.surfaceVariant.withOpacity(0.28),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.outlineVariant.withOpacity(0.75)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        leading: _InitialAvatar(
          text: tutor.tutorName.isEmpty ? '?' : tutor.tutorName[0].toUpperCase(),
          color: statusColor,
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                tutor.tutorName.isEmpty ? 'Tutor #${tutor.tutorId}' : tutor.tutorName,
                style: const TextStyle(fontWeight: FontWeight.w900),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            _StatusPill(label: status, color: statusColor),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(
            '${tutor.email}\nCCCD: ${tutor.nationalIdNumber ?? 'Not provided'}\nBank: ${tutor.bankName ?? 'Not provided'}',
            style: TextStyle(
              height: 1.35,
              color: colors.onSurfaceVariant,
            ),
          ),
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
      ),
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
            decoration: _adminInputDecoration(
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

class _PayoutsTab extends StatelessWidget {
  const _PayoutsTab();

  @override
  Widget build(BuildContext context) {
    final data = context.watch<AppDataProvider>();

    final pending = data.adminPayouts
        .where((p) => p.status.toLowerCase() == 'pending')
        .toList();
    final paid = data.adminPayouts
        .where((p) => ['paid', 'completed', 'approved']
        .contains(p.status.toLowerCase()))
        .toList();
    final failed = data.adminPayouts
        .where((p) => ['failed', 'rejected', 'cancelled']
        .contains(p.status.toLowerCase()))
        .toList();
    final others = data.adminPayouts
        .where((p) {
      final s = p.status.toLowerCase();
      return !['pending', 'paid', 'completed', 'approved',
        'failed', 'rejected', 'cancelled'].contains(s);
    })
        .toList();

    return RefreshIndicator(
      onRefresh: data.adminLoadDashboard,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          ErrorBanner(data.error),
          _AdminHeroCard(
            title: 'Payout requests',
            subtitle: 'Review tutor withdrawal requests and open each payout for processing.',
            icon: Icons.payments_outlined,
            trailing: _CountBadge(count: data.adminPayouts.length, label: 'requests'),
          ),
          const SizedBox(height: 16),
          if (data.adminPayouts.isEmpty && !data.loading)
            const _EmptyStateCard(
              icon: Icons.payments_outlined,
              title: 'No payouts',
              subtitle: 'Tutor payout requests will appear here.',
            ),
          if (data.adminPayouts.isNotEmpty) ...[
            _PayoutSection(
              title: 'Pending',
              icon: Icons.pending_actions_outlined,
              payouts: pending,
              emptyText: 'No pending payouts.',
              statusColor: Colors.orange,
              initiallyExpanded: true,
            ),
            _PayoutSection(
              title: 'Paid',
              icon: Icons.check_circle_outline,
              payouts: paid,
              emptyText: 'No paid payouts.',
              statusColor: Colors.green,
            ),
            _PayoutSection(
              title: 'Failed',
              icon: Icons.cancel_outlined,
              payouts: failed,
              emptyText: 'No failed payouts.',
              statusColor: Colors.red,
            ),
            if (others.isNotEmpty)
              _PayoutSection(
                title: 'Other',
                icon: Icons.help_outline,
                payouts: others,
                emptyText: 'No payouts in this group.',
                statusColor: Colors.blueGrey,
              ),
          ],
        ],
      ),
    );
  }
}

class _PayoutSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<PayoutModel> payouts;
  final String emptyText;
  final Color statusColor;
  final bool initiallyExpanded;

  const _PayoutSection({
    required this.title,
    required this.icon,
    required this.payouts,
    required this.emptyText,
    required this.statusColor,
    this.initiallyExpanded = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      color: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_cardRadius),
        side: BorderSide(color: colors.outlineVariant),
      ),
      child: ExpansionTile(
        initiallyExpanded: initiallyExpanded,
        leading: _SoftIcon(icon: icon, color: statusColor),
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        title: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
            _StatusPill(
              label: payouts.length.toString(),
              color: statusColor,
            ),
          ],
        ),
        children: [
          if (payouts.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 14),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  emptyText,
                  style: TextStyle(color: colors.onSurfaceVariant),
                ),
              ),
            ),
          ...payouts.map((payout) => _PayoutItem(
            payout: payout,
            statusColor: statusColor,
          )),
        ],
      ),
    );
  }
}

class _PayoutItem extends StatelessWidget {
  final PayoutModel payout;
  final Color statusColor;

  const _PayoutItem({
    required this.payout,
    required this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: colors.surfaceVariant.withOpacity(0.28),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.outlineVariant.withOpacity(0.75)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        leading: _SoftIcon(
          icon: Icons.payments_outlined,
          color: statusColor,
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                'Payout #${payout.payoutId}',
                style: const TextStyle(fontWeight: FontWeight.w900),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            _StatusPill(label: payout.status, color: statusColor),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(
            'Tutor #${payout.tutorId}',
            style: TextStyle(
              height: 1.35,
              color: colors.onSurfaceVariant,
            ),
          ),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            MoneyText(payout.amount),
            const SizedBox(height: 4),
            Icon(
              Icons.chevron_right,
              size: 18,
              color: colors.onSurfaceVariant,
            ),
          ],
        ),
        onTap: () => context.push('/admin/payout/${payout.payoutId}'),
      ),
    );
  }
}

class _ReportsTab extends StatelessWidget {
  const _ReportsTab();

  @override
  Widget build(BuildContext context) {
    final data = context.watch<AppDataProvider>();
    final colors = Theme.of(context).colorScheme;

    return RefreshIndicator(
      onRefresh: () => data.adminLoadReports(),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          ErrorBanner(data.error),
          _AdminHeroCard(
            title: 'Tutor reports',
            subtitle: 'Review complaints, proof images, tutor details, and resolution status.',
            icon: Icons.report_outlined,
            trailing: _CountBadge(count: data.adminReports.length, label: 'reports'),
          ),
          const SizedBox(height: 16),
          if (data.adminReports.isEmpty && !data.loading)
            const _EmptyStateCard(
              icon: Icons.report_outlined,
              title: 'No reports',
              subtitle: 'Tutor reports will appear here.',
            ),
          ...data.adminReports.map((report) {
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
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                leading: _SoftIcon(
                  icon: status == 'pending'
                      ? Icons.pending_actions_outlined
                      : status == 'resolved'
                      ? Icons.check_circle_outline
                      : Icons.report_outlined,
                  color: statusColor,
                ),
                title: Row(
                  children: [
                    Expanded(
                      child: Text(
                        report.title,
                        style: const TextStyle(fontWeight: FontWeight.w900),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _StatusPill(label: report.status, color: statusColor),
                  ],
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    'Tutor: ${report.tutorName}\nReporter: ${report.reporterName}',
                    style: TextStyle(
                      height: 1.35,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
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
  final String subtitle;
  final double amount;
  final IconData icon;
  final Color? accent;

  const _MoneyStatCard({
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.icon,
    this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final color = accent ?? colors.primary;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      color: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_cardRadius),
        side: BorderSide(color: colors.outlineVariant),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        leading: _SoftIcon(icon: icon, color: color),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        subtitle: Text(subtitle),
        trailing: FittedBox(
          fit: BoxFit.scaleDown,
          child: MoneyText(amount),
        ),
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
        mainAxisExtent: 132,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemBuilder: (context, index) {
        final item = items[index];
        final colors = Theme.of(context).colorScheme;
        final accent = item.color ?? colors.primary;

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(_cardRadius),
            border: Border.all(color: colors.outlineVariant),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SoftIcon(icon: item.icon, color: accent, size: 38),
              const SizedBox(height: 8),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  item.value,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                  maxLines: 1,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                item.label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
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
  final Color? color;

  _StatItem(
      this.label,
      this.value,
      this.icon, [
        this.color,
      ]);
}

class _AdminHeroCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Widget? trailing;

  const _AdminHeroCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
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
        border: Border.all(color: colors.outlineVariant.withOpacity(0.75)),
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: colors.surface.withOpacity(0.78),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(icon, color: colors.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: colors.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    height: 1.35,
                    color: colors.onPrimaryContainer.withOpacity(0.78),
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 12),
            trailing!,
          ],
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const _SectionTitle({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Row(
      children: [
        _SoftIcon(icon: icon, size: 36),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
              const SizedBox(height: 2),
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
    );
  }
}

class _PanelCard extends StatelessWidget {
  final Widget child;

  const _PanelCard({required this.child});

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
        child: child,
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

class _CountBadge extends StatelessWidget {
  final int count;
  final String label;

  const _CountBadge({
    required this.count,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: colors.surface.withOpacity(0.82),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Text(
        '$count $label',
        style: TextStyle(
          color: colors.primary,
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _InitialAvatar extends StatelessWidget {
  final String text;
  final Color color;

  const _InitialAvatar({
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      backgroundColor: color.withOpacity(0.12),
      foregroundColor: color,
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.w900),
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

InputDecoration _adminInputDecoration(
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

Color _statusColor(String status) {
  final normalized = status.toLowerCase();
  if (normalized == 'pending' || normalized == 'reviewing') return Colors.orange;
  if (normalized == 'resolved' || normalized == 'approved' || normalized == 'completed') {
    return Colors.green;
  }
  if (normalized == 'rejected' || normalized == 'cancelled') return Colors.red;
  return Colors.blueGrey;
}

// ── Dashboard support widgets ──────────────────────────────────────

class _DashSectionLabel extends StatelessWidget {
  final String label;
  const _DashSectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: 0.9,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String label;
  final String value;
  final String? badge;
  final Color? badgeColor;
  final Color? badgeBg;

  const _MetricCard({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.label,
    required this.value,
    this.badge,
    this.badgeColor,
    this.badgeBg,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surfaceVariant.withOpacity(0.35),
        borderRadius: BorderRadius.circular(_cardRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 17),
          ),
          const Spacer(),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colors.onSurfaceVariant,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (badge != null) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: badgeBg,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                badge!,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: badgeColor,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DashCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;

  const _DashCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(_cardRadius),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _RevStat extends StatelessWidget {
  final String label;
  final double value;
  final Color? color;

  const _RevStat({
    required this.label,
    required this.value,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: colors.onSurfaceVariant,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 3),
          MoneyText(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 13,
              color: color ?? colors.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

class _BigStat extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;

  const _BigStat({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.07),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: color,
                  ),
                ),
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: color.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TutorStatusBars extends StatelessWidget {
  final int total;
  final int approved;
  final int pending;

  const _TutorStatusBars({
    required this.total,
    required this.approved,
    required this.pending,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final t = total == 0 ? 1 : total;

    return Column(
      children: [
        _MiniBar(label: 'Approved', count: approved, pct: approved / t, color: Colors.green),
        const SizedBox(height: 8),
        _MiniBar(label: 'Pending', count: pending, pct: pending / t, color: Colors.orange),
        const SizedBox(height: 8),
        _MiniBar(
          label: 'Other',
          count: total - approved - pending,
          pct: (total - approved - pending) / t,
          color: colors.onSurfaceVariant,
        ),
      ],
    );
  }
}

class _MiniBar extends StatelessWidget {
  final String label;
  final int count;
  final double pct;
  final Color color;

  const _MiniBar({
    required this.label,
    required this.count,
    required this.pct,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      children: [
        SizedBox(
          width: 60,
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: pct.clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: colors.surfaceVariant,
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          count.toString(),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _RevenueBarChart extends StatelessWidget {
  final double gross;
  final double platform;
  final double tutor;

  const _RevenueBarChart({
    required this.gross,
    required this.platform,
    required this.tutor,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    final maxVal = [gross, platform, tutor].reduce((a, b) => a > b ? a : b);

    final double divisor;
    final String suffix;

    if (maxVal >= 1000000) {
      divisor = 1000000;
      suffix = 'M';
    } else if (maxVal >= 1000) {
      divisor = 1000;
      suffix = 'K';
    } else {
      divisor = 1;
      suffix = '';
    }

    final maxYRaw = (maxVal / divisor) * 1.25;
    final maxY = maxYRaw.ceilToDouble();
    final interval = (maxY / 4).ceilToDouble();

    return BarChart(
      BarChartData(
        maxY: maxY,
        barGroups: [
          _bar(0, gross / divisor, const Color(0xFF7F77DD)),
          _bar(1, platform / divisor, const Color(0xFF5DCAA5)),
          _bar(2, tutor / divisor, const Color(0xFFAFA9EC)),
        ],
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (v, _) {
                const labels = ['Gross', 'Platform', 'Tutor'];
                final i = v.toInt();
                if (i < 0 || i >= labels.length) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    labels[i],
                    style: TextStyle(fontSize: 10, color: colors.onSurfaceVariant),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 48,
              interval: interval,
              getTitlesWidget: (v, _) => Text(
                '₫${v.toStringAsFixed(v == v.truncateToDouble() ? 0 : 1)}$suffix',
                style: TextStyle(fontSize: 9, color: colors.onSurfaceVariant),
              ),
            ),
          ),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) => FlLine(
            color: colors.outlineVariant,
            strokeWidth: 0.5,
          ),
          checkToShowHorizontalLine: (value) => value % interval == 0,
        ),
        borderData: FlBorderData(show: false),
      ),
    );
  }

  BarChartGroupData _bar(int x, double val, Color color) => BarChartGroupData(
    x: x,
    barRods: [
      BarChartRodData(
        toY: val,
        color: color,
        width: 28,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
      ),
    ],
  );
}

class _TutorDonutChart extends StatelessWidget {
  final int approved;
  final int pending;
  final int total;

  const _TutorDonutChart({
    required this.approved,
    required this.pending,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final rejected = (total - approved - pending).clamp(0, total);
    return PieChart(
      PieChartData(
        sectionsSpace: 2,
        centerSpaceRadius: 30,
        sections: [
          PieChartSectionData(
            value: approved.toDouble(),
            color: Colors.green,
            radius: 18,
            showTitle: false,
          ),
          PieChartSectionData(
            value: pending.toDouble(),
            color: Colors.orange,
            radius: 18,
            showTitle: false,
          ),
          PieChartSectionData(
            value: rejected.toDouble(),
            color: Colors.red,
            radius: 18,
            showTitle: false,
          ),
        ],
      ),
    );
  }
}

