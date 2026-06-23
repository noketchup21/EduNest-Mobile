import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_strings.dart';
import '../../models/mvp_models.dart';
import '../../providers/app_data_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/error_banner.dart';
import '../../widgets/money_text.dart';
import '../../widgets/app_ui.dart';
import '../../widgets/user_avatar.dart';

class AvailabilityDetailScreen extends StatefulWidget {
  final AvailabilityModel availability;

  const AvailabilityDetailScreen({
    super.key,
    required this.availability,
  });

  @override
  State<AvailabilityDetailScreen> createState() =>
      _AvailabilityDetailScreenState();
}

class _AvailabilityDetailScreenState extends State<AvailabilityDetailScreen> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final data = context.read<AppDataProvider>();
      if (data.subjects.isEmpty) {
        data.loadSubjects();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final data = context.watch<AppDataProvider>();
    final auth = context.watch<AuthProvider>();
    final availability = widget.availability;
    final subject = _subjectFor(data, availability);
    final subjectName = availability.subjectName?.trim().isNotEmpty == true
        ? availability.subjectName!.trim()
        : subject?.name ?? data.availabilitySubjectName(availability);
    final subjectDescription = subject?.description.trim() ?? '';
    final total = availability.totalCoursePrice > 0
        ? availability.totalCoursePrice
        : availability.pricePerSlot * availability.slot;
    final canBook =
        auth.isLearner && !auth.isAdmin && !availability.hasBookings;
    final t = context.l10n;
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(t.text('Availability details'))),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            ErrorBanner(data.error),
            _TutorHeader(availability: availability),
            const SizedBox(height: 14),
            _SectionCard(
              title: t.text('Subject'),
              icon: Icons.menu_book_outlined,
              children: [
                Text(
                  subjectName,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  subjectDescription.isEmpty
                      ? t.text(
                          'No description has been added for this subject.')
                      : subjectDescription,
                ),
              ],
            ),
            const SizedBox(height: 14),
            _SectionCard(
              title: t.text('Schedule'),
              icon: Icons.calendar_month_outlined,
              children: [
                _DetailRow(
                  icon: Icons.event_outlined,
                  label: t.text('Days of week'),
                  value: availability.dayOfWeek,
                ),
                _DetailRow(
                  icon: Icons.schedule_outlined,
                  label: t.text('Class time'),
                  value: '${availability.startTime} - ${availability.endTime}',
                ),
                _DetailRow(
                  icon: Icons.play_circle_outline,
                  label: t.text('Start course date'),
                  value: _formatDate(context, availability.startCourseTime),
                ),
                _DetailRow(
                  icon: Icons.stop_circle_outlined,
                  label: t.text('End course date'),
                  value: _formatDate(context, availability.endCourseTime),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _SectionCard(
              title: t.text('Availability setup'),
              icon: Icons.tune_outlined,
              children: [
                _DetailRow(
                  icon: Icons.language_outlined,
                  label: t.text('Mode'),
                  value: t.mode(availability.mode),
                ),
                _DetailRow(
                  icon: Icons.list_alt_outlined,
                  label: t.text('Lessons'),
                  value: t.lessonsN(availability.slot),
                ),
                if (availability.mode.toLowerCase() == 'offline' &&
                    (availability.offlineAreas?.trim().isNotEmpty ?? false))
                  _DetailRow(
                    icon: Icons.location_on_outlined,
                    label: t.text('Offline tutoring areas'),
                    value: availability.offlineAreas!.trim(),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            _SectionCard(
              title: t.text('Tuition'),
              icon: Icons.payments_outlined,
              children: [
                _DetailRow(
                  icon: Icons.price_change_outlined,
                  label: t.text('Price per lesson'),
                  valueWidget: MoneyText(availability.pricePerSlot),
                ),
                _DetailRow(
                  icon: Icons.account_balance_wallet_outlined,
                  label: t.text('Full tuition package'),
                  valueWidget: MoneyText(
                    total,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: colors.primary,
                    ),
                  ),
                ),
              ],
            ),
            if (canBook) ...[
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: data.loading
                    ? null
                    : () => _book(context, availability.availabilityId),
                icon: const Icon(Icons.event_available_outlined),
                label: Text(t.enrollNow),
              ),
            ],
          ],
        ),
      ),
    );
  }

  SubjectModel? _subjectFor(
    AppDataProvider data,
    AvailabilityModel availability,
  ) {
    for (final subject in data.subjects) {
      if (subject.subjectId == availability.subjectId) return subject;
    }

    return null;
  }

  String _formatDate(BuildContext context, DateTime date) {
    return MaterialLocalizations.of(context).formatMediumDate(date.toLocal());
  }

  Future<void> _book(BuildContext context, int availabilityId) async {
    try {
      await context.read<AppDataProvider>().book(availabilityId);
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.enrolledSuccessfully)),
      );
      context.go('/bookings');
    } catch (_) {}
  }
}

class _TutorHeader extends StatelessWidget {
  final AvailabilityModel availability;

  const _TutorHeader({required this.availability});

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final name = availability.tutorName.trim().isEmpty
        ? 'Tutor #${availability.tutorId}'
        : availability.tutorName.trim();

    return Card(
      child: ListTile(
        leading: UserAvatar(
          imageUrl: availability.tutorAvatarUrl,
          name: name,
          radius: 26,
        ),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle: Text(t.text('Tutor availability')),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return AppSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSectionHeader(title: title, icon: icon),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? value;
  final Widget? valueWidget;

  const _DetailRow({
    required this.icon,
    required this.label,
    this.value,
    this.valueWidget,
  }) : assert(value != null || valueWidget != null);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 19),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: Theme.of(context).textTheme.labelMedium),
                const SizedBox(height: 2),
                valueWidget ?? Text(value!),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
