import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_strings.dart';
import '../../models/mvp_models.dart';
import '../../providers/app_data_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/error_banner.dart';
import '../../widgets/money_text.dart';
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
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      children: [
        ErrorBanner(data.error),
        if (data.loading && courses.isEmpty)
          const Padding(
            padding: EdgeInsets.all(48),
            child: Center(child: CircularProgressIndicator()),
          ),
        if (!data.loading && courses.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                Icon(Icons.menu_book_rounded,
                    size: 48, color: Colors.grey[400]),
                const SizedBox(height: 12),
                Text(
                  t.noCoursesAvailable,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 4),
                Text(
                  t.startSharingKnowledge,
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
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

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
            color: theme.colorScheme.outlineVariant.withOpacity(0.4)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
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
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isActive
                        ? Colors.green.withOpacity(0.1)
                        : Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isActive
                            ? Icons.check_circle_rounded
                            : Icons.pause_circle_rounded,
                        size: 14,
                        color: isActive ? Colors.green : Colors.orange,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isActive ? t.active : t.hidden,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isActive ? Colors.green : Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Info Grid
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                _buildInfoTag(theme, Icons.calendar_today_rounded,
                    availability.dayOfWeek),
                _buildInfoTag(theme, Icons.access_time_rounded,
                    '${availability.startTime} - ${availability.endTime}'),
                _buildInfoTag(theme, Icons.layers_rounded,
                    '${t.mode(availability.mode)} - ${t.level(availability.level)}'),
                if (_offlineAreas(availability).isNotEmpty)
                  _buildInfoTag(theme, Icons.location_on_outlined,
                      _offlineAreas(availability)),
                _buildInfoTag(theme, Icons.list_alt_rounded,
                    '${availability.slot} ${t.lessonsLower}'),
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
                        ? theme.colorScheme.errorContainer.withOpacity(0.6)
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

  Widget _buildInfoTag(ThemeData theme, IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.4),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500),
          ),
        ],
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
        if (data.loading && data.availabilities.isEmpty)
          const Padding(
            padding: EdgeInsets.all(48),
            child: Center(child: CircularProgressIndicator()),
          ),
        if (!data.loading && data.availabilities.isEmpty)
          Container(
            padding: const EdgeInsets.all(40),
            alignment: Alignment.center,
            child: Text(
              t.noTutorsAvailable,
              style: const TextStyle(color: Colors.grey),
            ),
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

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
            color: theme.colorScheme.outlineVariant.withOpacity(0.3)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: true,
          backgroundColor: Colors.transparent,
          collapsedBackgroundColor: Colors.transparent,
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                  color: theme.colorScheme.primary.withOpacity(0.2), width: 3),
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
          subtitle: Text(
            t.activeCoursesOpen(courses.length),
            style: TextStyle(
                fontSize: 13, color: theme.colorScheme.onSurfaceVariant),
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
                      ? theme.colorScheme.errorContainer.withOpacity(0.55)
                      : theme.colorScheme.surfaceContainerHighest
                          .withOpacity(0.6),
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
                  backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
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
                    child: OutlinedButton.icon(
                      onPressed: () => context.push('/tutors/${first.tutorId}'),
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
                    color: theme.colorScheme.secondary.withOpacity(0.1),
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
                  onPressed:
                      data.loading ? null : () => _book(context, availability),
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
