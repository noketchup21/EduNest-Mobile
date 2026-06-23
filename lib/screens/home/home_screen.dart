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

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _reload();
    });
  }

  Future<void> _reload() async {
    final auth = context.read<AuthProvider>();
    final data = context.read<AppDataProvider>();
    if (auth.isTutor && !auth.isAdmin) {
      await data.loadMyAvailability();
    } else {
      await data.loadHome();
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = context.watch<AppDataProvider>();
    final auth = context.watch<AuthProvider>();
    final isTutor = auth.isTutor && !auth.isAdmin;
    final theme = Theme.of(context);
    final t = context.l10n;

    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerLow,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 2,
        backgroundColor: Colors.transparent,
        title: Text(
          isTutor ? t.myCourses : t.exploreTutors,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
            fontSize: 24,
          ),
        ),
        actions: [
          if (isTutor)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: IconButton(
                onPressed: () => context.push('/teaching-guide'),
                icon: Icon(
                  Icons.auto_awesome_outlined,
                  color: theme.colorScheme.primary,
                ),
                tooltip: t.text('Teaching preparation guide'),
              ),
            ),
          if (isTutor)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: IconButton(
                onPressed: () => context.push('/availability/create'),
                icon: Icon(Icons.add_circle_rounded,
                    size: 28, color: theme.colorScheme.primary),
              ),
            ),
          if (!isTutor)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: IconButton(
                onPressed: () => context.push('/favorites'),
                icon: const Icon(Icons.favorite_border_rounded),
                tooltip: t.favoriteTutors,
              ),
            ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: IconButton(
              onPressed: data.loading ? null : _reload,
              icon: const Icon(Icons.refresh_rounded),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _reload,
        child: isTutor
            ? _TutorCourseList(data: data)
            : _LearnerTutorList(data: data),
      ),
    );
  }
}

// --- VIEW 1: TUTOR COURSE LIST ---
class _TutorCourseList extends StatelessWidget {
  final AppDataProvider data;
  const _TutorCourseList({required this.data});

  @override
  Widget build(BuildContext context) {
    final courses = data.myAvailabilities;
    final t = context.l10n;
    final activeCourses = courses
        .where((course) => course.status.toLowerCase() == 'active')
        .length;
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      children: [
        ErrorBanner(data.error),
        _HomeHero(
          isTutor: true,
          name: data.profile?.name,
          action: () => context.push('/availability/create'),
        ),
        const SizedBox(height: 16),
        if (courses.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.45,
              children: [
                AppMetricCard(
                  icon: Icons.menu_book_rounded,
                  label: t.myCourses,
                  value: '${courses.length}',
                ),
                AppMetricCard(
                  icon: Icons.check_circle_outline_rounded,
                  label: t.active,
                  value: '$activeCourses',
                  tone: AppStatusTone.success,
                ),
              ],
            ),
          ),
        if (data.loading && courses.isEmpty)
          const Padding(
            padding: EdgeInsets.all(48),
            child: Center(child: CircularProgressIndicator()),
          ),
        if (!data.loading && courses.isEmpty)
          AppEmptyState(
            icon: Icons.menu_book_rounded,
            title: t.noCoursesAvailable,
            message: t.startSharingKnowledge,
          ),
        if (courses.isNotEmpty) ...[
          const SizedBox(height: 20),
          AppSectionHeader(
            icon: Icons.menu_book_rounded,
            title: t.myCourses,
            subtitle: t.text('Review your published teaching availability.'),
          ),
          const SizedBox(height: 12),
        ],
        ...courses.map(
            (availability) => _TutorCourseCard(availability: availability)),
      ],
    );
  }
}

class _TutorCourseCard extends StatelessWidget {
  final AvailabilityModel availability;
  const _TutorCourseCard({required this.availability});

  @override
  Widget build(BuildContext context) {
    final data = context.watch<AppDataProvider>();
    final theme = Theme.of(context);
    final status = availability.status.toLowerCase();
    final isActive = status == 'active';
    final t = context.l10n;
    final total = availability.totalCoursePrice > 0
        ? availability.totalCoursePrice
        : availability.pricePerSlot * availability.slot;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: AppSurfaceCard(
        kind: AppSurfaceCardKind.marketplace,
        padding: const EdgeInsets.all(20),
        onTap: () => context.push(
          '/availabilities/${availability.availabilityId}',
          extra: availability,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card: Subject Name + Status Badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    _subjectText(context, availability),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
                AppStatusBadge(
                  label: isActive ? t.active : t.hidden,
                  tone:
                      isActive ? AppStatusTone.success : AppStatusTone.warning,
                  icon: isActive
                      ? Icons.check_circle_rounded
                      : Icons.pause_circle_rounded,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Info Grid
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                AppMetaChip(
                  icon: Icons.calendar_today_rounded,
                  label: availability.dayOfWeek,
                ),
                AppMetaChip(
                  icon: Icons.access_time_rounded,
                  label: '${availability.startTime} - ${availability.endTime}',
                ),
                AppMetaChip(
                  icon: Icons.layers_rounded,
                  label: t.mode(availability.mode),
                ),
                if (_offlineAreas(availability).isNotEmpty)
                  AppMetaChip(
                    icon: Icons.location_on_outlined,
                    label: _offlineAreas(availability),
                  ),
                AppMetaChip(
                  icon: Icons.list_alt_rounded,
                  label: '${availability.slot} ${t.lessonsLower}',
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 14),

            // Footer Card: Price + Action Button
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start, // Đã sửa lỗi tại đây
                    children: [
                      Text(
                        t.totalTuition,
                        style: TextStyle(
                            fontSize: 11,
                            color: theme.colorScheme.onSurfaceVariant),
                      ),
                      MoneyText(
                        total,
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 20,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton.tonal(
                  onPressed: data.loading || availability.hasBookings
                      ? null
                      : () => _toggleStatus(context, availability),
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    backgroundColor: isActive
                        ? theme.colorScheme.errorContainer
                            .withValues(alpha: 0.6)
                        : theme.colorScheme.secondaryContainer,
                    foregroundColor: isActive
                        ? theme.colorScheme.error
                        : theme.colorScheme.onSecondaryContainer,
                  ),
                  child: Text(isActive ? t.hide : t.publish,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleStatus(
      BuildContext context, AvailabilityModel availability) async {
    final isActive = availability.status.toLowerCase() == 'active';
    final newStatus = isActive ? 'Inactive' : 'Active';
    final t = AppStrings.of(context, listen: false);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(isActive ? t.hideCourseTitle : t.publishCourseTitle),
        content: Text(
          isActive ? t.hideCourseMessage : t.publishCourseMessage,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(t.cancel)),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(
              backgroundColor:
                  isActive ? Theme.of(context).colorScheme.error : null,
            ),
            child: Text(isActive ? t.hide : t.publish),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      await context.read<AppDataProvider>().toggleAvailabilityStatus(
            availabilityId: availability.availabilityId,
            status: newStatus,
          );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t.courseStatusUpdated)),
        );
      }
    } catch (_) {}
  }
}

// --- VIEW 2: LEARNER TUTOR LIST ---
class _LearnerTutorList extends StatelessWidget {
  final AppDataProvider data;
  const _LearnerTutorList({required this.data});

  @override
  Widget build(BuildContext context) {
    final groups = _groupByTutor(data.availabilities);
    final t = context.l10n;
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      children: [
        ErrorBanner(data.error),
        _HomeHero(
          isTutor: false,
          name: data.profile?.name,
        ),
        const SizedBox(height: 20),
        AppSectionHeader(
          icon: Icons.school_rounded,
          title: t.text('Tutors you can book'),
          subtitle: t.text('Compare availability, teaching mode, and price.'),
        ),
        const SizedBox(height: 12),
        if (data.loading && data.availabilities.isEmpty)
          const Padding(
            padding: EdgeInsets.all(48),
            child: Center(child: CircularProgressIndicator()),
          ),
        if (!data.loading && data.availabilities.isEmpty)
          AppEmptyState(
            icon: Icons.school_outlined,
            title: t.noTutorsAvailable,
            message: t.text('Check back soon for new tutors and courses.'),
          ),
        ...groups.values.map((courses) => _TutorGroupCard(courses: courses)),
      ],
    );
  }

  Map<int, List<AvailabilityModel>> _groupByTutor(
      List<AvailabilityModel> availabilities) {
    final result = <int, List<AvailabilityModel>>{};
    for (final availability in availabilities) {
      result.putIfAbsent(availability.tutorId, () => []);
      result[availability.tutorId]!.add(availability);
    }
    return result;
  }
}

class _HomeHero extends StatelessWidget {
  final bool isTutor;
  final String? name;
  final VoidCallback? action;

  const _HomeHero({
    required this.isTutor,
    this.name,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final t = context.l10n;
    final displayName = name?.trim() ?? '';

    return AppHeroCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: colors.onPrimary.withValues(alpha: 0.16),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isTutor
                      ? Icons.auto_awesome_rounded
                      : Icons.menu_book_rounded,
                  color: colors.onPrimary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  displayName.isEmpty
                      ? t.welcomeBack
                      : '${t.welcomeBack}, $displayName',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: colors.onPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            isTutor
                ? t.text('Make today a great teaching day')
                : t.text('Find a tutor who fits your goals'),
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: colors.onPrimary,
                  fontWeight: FontWeight.w900,
                  height: 1.05,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            isTutor
                ? t.text(
                    'Create availability, prepare your lessons, and stay on top of your courses.')
                : t.text(
                    'Explore trusted tutors, compare schedules, and book with confidence.'),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colors.onPrimary.withValues(alpha: 0.86),
                  height: 1.35,
                ),
          ),
          if (action != null) ...[
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: action,
              style: FilledButton.styleFrom(
                backgroundColor: colors.surface,
                foregroundColor: colors.primary,
                elevation: 0,
              ),
              icon: const Icon(Icons.add_circle_rounded),
              label: Text(t.text('Create availability')),
            ),
          ],
        ],
      ),
    );
  }
}

class _TutorGroupCard extends StatelessWidget {
  final List<AvailabilityModel> courses;
  const _TutorGroupCard({required this.courses});

  @override
  Widget build(BuildContext context) {
    final data = context.watch<AppDataProvider>();
    final theme = Theme.of(context);
    final first = courses.first;
    final tutorName =
        first.tutorName.isEmpty ? 'Tutor #${first.tutorId}' : first.tutorName;
    final isFavorite = data.isFavoriteTutor(first.tutorId);
    final t = context.l10n;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: AppSurfaceCard(
        kind: AppSurfaceCardKind.marketplace,
        padding: EdgeInsets.zero,
        child: Theme(
          data: theme.copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            initiallyExpanded: false,
            backgroundColor: Colors.transparent,
            collapsedBackgroundColor: Colors.transparent,
            tilePadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                    color: theme.colorScheme.primary.withValues(alpha: 0.2),
                    width: 3),
              ),
              child: UserAvatar(
                imageUrl: first.tutorAvatarUrl,
                name: tutorName,
                radius: 24,
              ),
            ),
            title: Text(
              tutorName,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            subtitle: Wrap(
              spacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  t.activeCoursesOpen(courses.length),
                  style: TextStyle(
                    fontSize: 13,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                AppStatusBadge(
                  label: t.active,
                  tone: AppStatusTone.success,
                  icon: Icons.verified_rounded,
                ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: isFavorite ? t.unsaveTutor : t.saveTutor,
                  onPressed: data.loading
                      ? null
                      : () => _toggleFavorite(context, first, tutorName),
                  icon: Icon(
                    isFavorite
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    color: isFavorite
                        ? theme.colorScheme.error
                        : theme.colorScheme.onSurfaceVariant,
                    size: 22,
                  ),
                  style: IconButton.styleFrom(
                    backgroundColor: isFavorite
                        ? theme.colorScheme.errorContainer
                            .withValues(alpha: 0.55)
                        : theme.colorScheme.surfaceContainerHighest
                            .withValues(alpha: 0.6),
                    padding: const EdgeInsets.all(8),
                  ),
                ),
                const SizedBox(width: 4),
                IconButton(
                  tooltip: 'Chat',
                  onPressed: first.tutorUserId <= 0
                      ? null
                      : () => _startChat(context, first.tutorUserId),
                  icon: Icon(Icons.chat_bubble_rounded,
                      color: theme.colorScheme.primary, size: 22),
                  style: IconButton.styleFrom(
                    backgroundColor:
                        theme.colorScheme.primary.withValues(alpha: 0.1),
                    padding: const EdgeInsets.all(8),
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.expand_more_rounded),
              ],
            ),
            children: [
              const Divider(height: 1, indent: 16, endIndent: 16),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: FilledButton.tonalIcon(
                        onPressed: () =>
                            context.push('/tutors/${first.tutorId}'),
                        icon: const Icon(Icons.badge_rounded),
                        label: Text(t.viewTutorProfile),
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              ...courses.map((availability) =>
                  _LearnerCourseTile(availability: availability)),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _startChat(BuildContext context, int tutorUserId) async {
    try {
      final conversation =
          await context.read<AppDataProvider>().startConversation(tutorUserId);
      if (context.mounted) context.push('/chat/${conversation.conversationId}');
    } catch (_) {}
  }

  Future<void> _toggleFavorite(
    BuildContext context,
    AvailabilityModel availability,
    String tutorName,
  ) async {
    try {
      await context.read<AppDataProvider>().toggleFavoriteTutor(
            tutorId: availability.tutorId,
            name: tutorName,
            userId: availability.tutorUserId,
            avatarUrl: availability.tutorAvatarUrl,
          );

      if (!context.mounted) return;

      final saved =
          context.read<AppDataProvider>().isFavoriteTutor(availability.tutorId);
      final t = AppStrings.of(context, listen: false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(saved ? t.tutorSaved : t.tutorRemoved),
        ),
      );
    } catch (_) {}
  }
}

class _LearnerCourseTile extends StatelessWidget {
  final AvailabilityModel availability;
  const _LearnerCourseTile({required this.availability});

  @override
  Widget build(BuildContext context) {
    final data = context.watch<AppDataProvider>();
    final theme = Theme.of(context);
    final t = context.l10n;
    final total = availability.totalCoursePrice > 0
        ? availability.totalCoursePrice
        : availability.pricePerSlot * availability.slot;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => context.push(
          '/availabilities/${availability.availabilityId}',
          extra: availability,
        ),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      _subjectText(context, availability),
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.secondary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      t.mode(availability.mode),
                      style: TextStyle(
                          fontSize: 11,
                          color: theme.colorScheme.secondary,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _buildSmallInfo(
                      theme, Icons.event_rounded, availability.dayOfWeek),
                  const SizedBox(width: 16),
                  _buildSmallInfo(theme, Icons.schedule_rounded,
                      '${availability.startTime} - ${availability.endTime}'),
                ],
              ),
              if (_offlineAreas(availability).isNotEmpty) ...[
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      size: 14,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        _offlineAreas(availability),
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(t.fullTuitionPackage,
                            style: TextStyle(
                                fontSize: 11,
                                color: theme.colorScheme.onSurfaceVariant)),
                        MoneyText(
                          total,
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  FilledButton(
                    onPressed: data.loading
                        ? null
                        : () => _book(context, availability),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(t.enrollNow,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSmallInfo(ThemeData theme, IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 6),
        Text(text,
            style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500)),
      ],
    );
  }

  Future<void> _book(BuildContext context, availability) async {
    try {
      await context.read<AppDataProvider>().book(availability.availabilityId);
      if (context.mounted) {
        final t = AppStrings.of(context, listen: false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t.enrolledSuccessfully)),
        );
        context.go('/bookings');
      }
    } catch (_) {}
  }
}

String _subjectText(BuildContext context, AvailabilityModel availability) {
  final data = context.read<AppDataProvider>();
  if ((availability.subjectName ?? '').isNotEmpty) {
    return availability.subjectName!;
  }
  return data.availabilitySubjectName(availability);
}

String _offlineAreas(AvailabilityModel availability) {
  final areas = availability.offlineAreas?.trim() ?? '';

  if (availability.mode != 'Offline' || areas.isEmpty) {
    return '';
  }

  return areas;
}
