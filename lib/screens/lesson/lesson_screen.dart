import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../l10n/app_strings.dart';
import '../../models/mvp_models.dart';
import '../../providers/app_data_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/error_banner.dart';
import '../../widgets/tutor_review_sheet.dart';
import '../../widgets/user_avatar.dart';

class LessonScreen extends StatefulWidget {
  const LessonScreen({super.key});

  @override
  State<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends State<LessonScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppDataProvider>().loadLessons();
    });
  }

  @override
  Widget build(BuildContext context) {
    final data = context.watch<AppDataProvider>();
    final t = context.l10n;
    final auth = context.watch<AuthProvider>();
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final lessons = [...data.lessons]
      ..sort((a, b) => a.scheduleTime.compareTo(b.scheduleTime));

    final nextLesson = _findNextLesson(lessons: lessons, isTutor: auth.isTutor);
    final overdueSessions = auth.isTutor
        ? _findOverdueTutorSessions(lessons)
        : <_TutorSessionInfo>[];

    final learnerGrouped = _groupLearnerLessonsByTutorThenAvailability(lessons);
    final tutorGrouped = _groupTutorLessonsByAvailability(lessons);

    return Scaffold(
      backgroundColor: colors.surfaceContainerLowest,
      appBar: AppBar(
        backgroundColor: colors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        titleSpacing: 20,
        title: Text(
          t.lessonsTitle,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
            letterSpacing: -0.3,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: IconButton.outlined(
              onPressed: data.loading ? null : data.loadLessons,
              tooltip: t.refresh,
              icon: const Icon(Icons.refresh_rounded, size: 20),
              style: IconButton.styleFrom(
                side: BorderSide(color: colors.outlineVariant, width: 0.5),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                minimumSize: const Size(36, 36),
                padding: EdgeInsets.zero,
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(0.5),
          child: Divider(
              height: 0.5,
              thickness: 0.5,
              color: colors.outlineVariant.withValues(alpha: 0.5)),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: data.loadLessons,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            ErrorBanner(data.error),
            if (auth.isTutor && overdueSessions.isNotEmpty) ...[
              _TutorReminderBox(sessions: overdueSessions),
              const SizedBox(height: 10),
            ],
            if (nextLesson != null) ...[
              _NextLessonBox(info: nextLesson, isTutor: auth.isTutor),
              const SizedBox(height: 10),
            ],
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                auth.isTutor ? t.myTeachingLessons : t.myLearningLessons,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colors.onSurface,
                  letterSpacing: -0.1,
                ),
              ),
            ),
            if (data.loading && lessons.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 48),
                child: Center(child: CircularProgressIndicator()),
              ),
            if (!data.loading && lessons.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 48),
                child: Column(
                  children: [
                    Icon(Icons.school_outlined,
                        size: 40,
                        color: colors.onSurface.withValues(alpha: 0.3)),
                    const SizedBox(height: 12),
                    Text(
                      t.noLessonsYet,
                      style: theme.textTheme.bodyLarge?.copyWith(
                          color: colors.onSurface.withValues(alpha: 0.5)),
                    ),
                  ],
                ),
              ),
            if (auth.isTutor)
              ...tutorGrouped.values.map((availabilityLessons) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _TutorAvailabilityCard(lessons: availabilityLessons),
                  ))
            else
              ...learnerGrouped.values.map((availabilityGroups) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _LearnerTutorCard(
                        availabilityGroups: availabilityGroups),
                  )),
          ],
        ),
      ),
    );
  }

  // ── Logic preserved from original ──────────────────────────

  _NextLessonInfo? _findNextLesson({
    required List<LessonModel> lessons,
    required bool isTutor,
  }) {
    final now = DateTime.now();

    if (isTutor) {
      final sessions = _groupLessonsBySession(lessons)
          .values
          .map((s) => _TutorSessionInfo.fromLessons(s))
          .where((s) =>
              s.status.toLowerCase() != 'completed' && s.endTime.isAfter(now))
          .toList()
        ..sort((a, b) => a.startTime.compareTo(b.startTime));
      if (sessions.isEmpty) return null;
      final next = sessions.first;
      return _NextLessonInfo(
          lesson: next.mainLesson, studentCount: next.studentCount);
    }

    final upcoming = lessons.where((lesson) {
      final end =
          lesson.scheduleTime.toLocal().add(Duration(minutes: lesson.duration));
      return lesson.status.toLowerCase() != 'completed' && end.isAfter(now);
    }).toList()
      ..sort((a, b) => a.scheduleTime.compareTo(b.scheduleTime));

    if (upcoming.isEmpty) return null;
    return _NextLessonInfo(lesson: upcoming.first, studentCount: 1);
  }

  List<_TutorSessionInfo> _findOverdueTutorSessions(List<LessonModel> lessons) {
    final now = DateTime.now();
    return _groupLessonsBySession(lessons)
        .values
        .map((s) => _TutorSessionInfo.fromLessons(s))
        .where((s) =>
            s.status.toLowerCase() != 'completed' && !s.endTime.isAfter(now))
        .toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
  }

  Map<int, Map<int, List<LessonModel>>>
      _groupLearnerLessonsByTutorThenAvailability(List<LessonModel> lessons) {
    final grouped = <int, Map<int, List<LessonModel>>>{};
    for (final l in lessons) {
      grouped.putIfAbsent(l.tutorId, () => {});
      grouped[l.tutorId]!.putIfAbsent(l.availabilityId, () => []);
      grouped[l.tutorId]![l.availabilityId]!.add(l);
    }
    return grouped;
  }

  Map<int, List<LessonModel>> _groupTutorLessonsByAvailability(
      List<LessonModel> lessons) {
    final grouped = <int, List<LessonModel>>{};
    for (final l in lessons) {
      grouped.putIfAbsent(l.availabilityId, () => []);
      grouped[l.availabilityId]!.add(l);
    }
    return grouped;
  }
}

// ─────────────────────────────────────────────────────────────────
// Data classes (unchanged)
// ─────────────────────────────────────────────────────────────────

class _NextLessonInfo {
  final LessonModel lesson;
  final int studentCount;
  const _NextLessonInfo({required this.lesson, required this.studentCount});
}

class _TutorSessionInfo {
  final LessonModel mainLesson;
  final int studentCount;
  final String status;
  final DateTime startTime;
  final DateTime endTime;

  const _TutorSessionInfo({
    required this.mainLesson,
    required this.studentCount,
    required this.status,
    required this.startTime,
    required this.endTime,
  });

  factory _TutorSessionInfo.fromLessons(List<LessonModel> lessons) {
    final sorted = [...lessons]
      ..sort((a, b) => a.scheduleTime.compareTo(b.scheduleTime));
    final first = sorted.first;
    final start = first.scheduleTime.toLocal();
    final end = start.add(Duration(minutes: first.duration));
    return _TutorSessionInfo(
      mainLesson: first,
      studentCount: sorted.length,
      status: _groupStatus(sorted),
      startTime: start,
      endTime: end,
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Reminder Box
// ─────────────────────────────────────────────────────────────────

class _TutorReminderBox extends StatelessWidget {
  final List<_TutorSessionInfo> sessions;
  const _TutorReminderBox({required this.sessions});

  static const _red50 = Color(0xFFFCEBEB);
  static const _red200 = Color(0xFFF7C1C1);
  static const _red800 = Color(0xFFA32D2D);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final t = context.l10n;
    final shown = sessions.take(3).toList();
    final hiddenCount = sessions.length - shown.length;

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _red200, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
            decoration: const BoxDecoration(
              color: _red50,
              borderRadius: BorderRadius.vertical(top: Radius.circular(15.5)),
              border: Border(bottom: BorderSide(color: _red200, width: 0.5)),
            ),
            child: Row(
              children: [
                const Icon(Icons.notifications_outlined,
                    size: 20, color: _red800),
                const SizedBox(width: 8),
                Text(t.attendanceReminder,
                    style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600, color: _red800)),
              ],
            ),
          ),

          // Description
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
            child: Text(
              t.attendanceReminderMessage,
              style: theme.textTheme.bodyLarge?.copyWith(
                  color: colors.onSurface.withValues(alpha: 0.6), height: 1.6),
            ),
          ),

          Divider(
              height: 0.5,
              thickness: 0.5,
              color: colors.outlineVariant.withValues(alpha: 0.4)),

          // Session rows
          ...shown.map((session) {
            final lesson = session.mainLesson;
            return Column(
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: _red50,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.pending_actions_outlined,
                            size: 20, color: _red800),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_subjectName(lesson),
                                style: theme.textTheme.bodyLarge
                                    ?.copyWith(fontWeight: FontWeight.w600),
                                overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 2),
                            Text(
                              '${_lessonTimeText(lesson)} · '
                              '${session.studentCount} student${session.studentCount == 1 ? '' : 's'} · ${session.status}',
                              style: theme.textTheme.bodyLarge?.copyWith(
                                  color:
                                      colors.onSurface.withValues(alpha: 0.55)),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: () =>
                            context.push('/lessons/${lesson.lessonId}'),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(60, 32),
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          textStyle: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w500),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                        child: Text(t.open),
                      ),
                    ],
                  ),
                ),
                if (shown.indexOf(session) < shown.length - 1 ||
                    hiddenCount > 0)
                  Divider(
                      height: 0.5,
                      thickness: 0.5,
                      color: colors.outlineVariant.withValues(alpha: 0.4)),
              ],
            );
          }),

          if (hiddenCount > 0)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
              child: Text(
                '+$hiddenCount more session${hiddenCount == 1 ? '' : 's'} need attention.',
                style: theme.textTheme.bodyLarge
                    ?.copyWith(color: colors.onSurface.withValues(alpha: 0.5)),
              ),
            )
          else
            const SizedBox(height: 4),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Next Lesson Box
// ─────────────────────────────────────────────────────────────────

class _NextLessonBox extends StatelessWidget {
  final _NextLessonInfo info;
  final bool isTutor;
  const _NextLessonBox({required this.info, required this.isTutor});

  static const _green50 = Color(0xFFEAF3DE);
  static const _green200 = Color(0xFFC0DD97);
  static const _green800 = Color(0xFF3B6D11);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final lesson = info.lesson;
    final t = context.l10n;

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: colors.outlineVariant.withValues(alpha: 0.5), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: const BoxDecoration(
              color: _green50,
              borderRadius: BorderRadius.vertical(top: Radius.circular(15.5)),
              border: Border(bottom: BorderSide(color: _green200, width: 0.5)),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today_outlined,
                    size: 19, color: _green800),
                const SizedBox(width: 8),
                Text(t.nextLesson,
                    style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: _green800,
                        letterSpacing: 0.5)),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _subjectName(lesson),
                  style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600, letterSpacing: -0.2),
                ),
                const SizedBox(height: 10),

                // Meta rows
                _MetaRow(
                    icon: Icons.access_time_outlined,
                    label: _lessonTimeText(lesson)),
                const SizedBox(height: 4),
                _MetaRow(
                  icon: isTutor
                      ? Icons.people_outline_rounded
                      : Icons.person_outline_rounded,
                  label: isTutor
                      ? t.students(info.studentCount)
                      : t.tutorName(lesson.tutorName),
                ),

                const SizedBox(height: 14),

                if (isTutor)
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () =>
                          context.push('/lessons/${lesson.lessonId}'),
                      icon: const Icon(Icons.people_outline, size: 16),
                      label: Text(t.openLessonDetail),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(0, 40),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        textStyle: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w500),
                      ),
                    ),
                  )
                else
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: lesson.meetingLink != null &&
                              lesson.meetingLink!.trim().isNotEmpty
                          ? () => _openMeetingLink(
                              context, lesson.meetingLink!.trim())
                          : null,
                      icon: const Icon(Icons.video_call_outlined, size: 16),
                      label: Text(
                        lesson.meetingLink != null &&
                                lesson.meetingLink!.trim().isNotEmpty
                            ? t.openMeeting
                            : t.meetingLinkNotAdded,
                      ),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 40),
                        side: BorderSide(
                            color: colors.outlineVariant, width: 0.5),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        textStyle: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w500),
                      ),
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

// ─────────────────────────────────────────────────────────────────
// Learner: Tutor Card → Availability Groups → Lesson Tiles
// ─────────────────────────────────────────────────────────────────

class _LearnerTutorCard extends StatelessWidget {
  final Map<int, List<LessonModel>> availabilityGroups;
  const _LearnerTutorCard({required this.availabilityGroups});

  @override
  Widget build(BuildContext context) {
    final allLessons = availabilityGroups.values.expand((x) => x).toList();
    if (allLessons.isEmpty) return const SizedBox.shrink();

    final first = allLessons.first;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final t = context.l10n;

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: colors.outlineVariant.withValues(alpha: 0.5), width: 0.5),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
          leading: UserAvatar(
            imageUrl: first.tutorAvatarUrl,
            name: first.tutorName,
            radius: 22,
          ),
          title: Text(
            first.tutorName,
            style: theme.textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          subtitle: Text(
            '${t.lessonsN(allLessons.length)} - ${t.coursesN(availabilityGroups.length)}',
            style: theme.textTheme.bodyLarge
                ?.copyWith(color: colors.onSurface.withValues(alpha: 0.55)),
          ),
          children: availabilityGroups.values
              .map((lessons) => _LearnerAvailabilityGroup(lessons: lessons))
              .toList(),
        ),
      ),
    );
  }
}

class _LearnerAvailabilityGroup extends StatelessWidget {
  final List<LessonModel> lessons;
  const _LearnerAvailabilityGroup({required this.lessons});

  @override
  Widget build(BuildContext context) {
    if (lessons.isEmpty) return const SizedBox.shrink();

    final sorted = [...lessons]
      ..sort((a, b) => a.scheduleTime.compareTo(b.scheduleTime));
    final first = sorted.first;
    final data = context.watch<AppDataProvider>();
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final t = context.l10n;
    final allCompleted =
        sorted.every((lesson) => lesson.status.toLowerCase() == 'completed');
    final reviewed = data.hasReviewedBooking(first.bookingId);

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
      child: Container(
        decoration: BoxDecoration(
          color: colors.surfaceContainerLowest,
          border: Border.all(
              color: colors.outlineVariant.withValues(alpha: 0.5), width: 0.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            tilePadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
            title: Text(
              _subjectName(first),
              style: theme.textTheme.bodyLarge
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              '${t.availabilityNumber(first.availabilityId)} - ${t.lessonsN(sorted.length)}',
              style: theme.textTheme.bodyLarge
                  ?.copyWith(color: colors.onSurface.withValues(alpha: 0.5)),
            ),
            children: [
              ...sorted.map((lesson) => _LessonTile(lesson: lesson)),
              if (allCompleted)
                _CourseReviewAction(
                  lesson: first,
                  reviewed: reviewed,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Tutor: Availability Card → Session Tiles
// ─────────────────────────────────────────────────────────────────

class _CourseReviewAction extends StatelessWidget {
  final LessonModel lesson;
  final bool reviewed;

  const _CourseReviewAction({
    required this.lesson,
    required this.reviewed,
  });

  @override
  Widget build(BuildContext context) {
    final data = context.watch<AppDataProvider>();
    final t = context.l10n;

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: reviewed || data.loading ? null : () => _review(context),
          icon: Icon(
            reviewed ? Icons.check_circle_rounded : Icons.rate_review_rounded,
          ),
          label: Text(reviewed ? t.reviewed : t.reviewTutor),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(0, 42),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _review(BuildContext context) async {
    final created = await showTutorReviewSheet(
      context: context,
      bookingId: lesson.bookingId,
      tutorId: lesson.tutorId,
      tutorName: lesson.tutorName,
    );

    if (created == true && context.mounted) {
      final t = AppStrings.of(context, listen: false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.reviewSubmitted)),
      );
    }
  }
}

class _TutorAvailabilityCard extends StatelessWidget {
  final List<LessonModel> lessons;
  const _TutorAvailabilityCard({required this.lessons});

  @override
  Widget build(BuildContext context) {
    if (lessons.isEmpty) return const SizedBox.shrink();

    final first = lessons.first;
    final sessions = _groupLessonsBySession(lessons).values.toList()
      ..sort((a, b) => a.first.scheduleTime.compareTo(b.first.scheduleTime));
    final totalStudents = lessons.length;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final t = context.l10n;

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: colors.outlineVariant.withValues(alpha: 0.5), width: 0.5),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
          leading: CircleAvatar(
            radius: 19,
            backgroundColor: colors.surfaceContainerHighest,
            child: Icon(Icons.event_note_outlined,
                size: 20, color: colors.onSurfaceVariant),
          ),
          title: Text(
            _subjectName(first),
            style: theme.textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          subtitle: Text(
            '${t.availabilityNumber(first.availabilityId)} - '
            '${t.sessionsN(sessions.length)} - ${t.studentRows(totalStudents)}',
            style: theme.textTheme.bodyLarge
                ?.copyWith(color: colors.onSurface.withValues(alpha: 0.55)),
          ),
          children: sessions.map((s) => _TutorSessionTile(lessons: s)).toList(),
        ),
      ),
    );
  }
}

class _TutorSessionTile extends StatelessWidget {
  final List<LessonModel> lessons;
  const _TutorSessionTile({required this.lessons});

  static const _amber50 = Color(0xFFFAEEDA);
  static const _amber200 = Color(0xFFFAC775);
  static const _amber800 = Color(0xFF633806);
  static const _green50 = Color(0xFFEAF3DE);
  static const _green200 = Color(0xFFC0DD97);
  static const _green800 = Color(0xFF3B6D11);

  @override
  Widget build(BuildContext context) {
    if (lessons.isEmpty) return const SizedBox.shrink();

    final session = _TutorSessionInfo.fromLessons(lessons);
    final first = session.mainLesson;
    final status = session.status;
    final now = DateTime.now();
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final t = context.l10n;

    String helperText;
    bool isOverdue = false;
    bool isDone = false;

    if (status.toLowerCase() == 'completed') {
      helperText = t.completed;
      isDone = true;
    } else if (!session.endTime.isAfter(now)) {
      helperText = t.endedTakeAttendance;
      isOverdue = true;
    } else if (!session.startTime.isAfter(now)) {
      helperText = t.lessonStartedCompletionLater;
    } else {
      helperText = t.startsLater;
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
      child: Container(
        decoration: BoxDecoration(
          color: colors.surfaceContainerLowest,
          border: Border.all(
              color: colors.outlineVariant.withValues(alpha: 0.5), width: 0.5),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Time + status chip row
            Row(
              children: [
                Expanded(
                  child: Text(_lessonTimeText(first),
                      style: theme.textTheme.bodyLarge
                          ?.copyWith(fontWeight: FontWeight.w600)),
                ),
                _StatusChip(status: status),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              t.students(session.studentCount),
              style: theme.textTheme.bodyLarge
                  ?.copyWith(color: colors.onSurface.withValues(alpha: 0.55)),
            ),
            const SizedBox(height: 10),

            // Helper text
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: isDone
                    ? _green50
                    : isOverdue
                        ? _amber50
                        : colors.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: isDone
                        ? _green200
                        : isOverdue
                            ? _amber200
                            : colors.outlineVariant.withValues(alpha: 0.4),
                    width: 0.5),
              ),
              child: Row(
                children: [
                  Icon(
                    isDone
                        ? Icons.check_circle_outline_rounded
                        : isOverdue
                            ? Icons.warning_amber_rounded
                            : Icons.schedule_outlined,
                    size: 20,
                    color: isDone
                        ? _green800
                        : isOverdue
                            ? _amber800
                            : colors.onSurface.withValues(alpha: 0.5),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      helperText,
                      style: TextStyle(
                        fontSize: 14,
                        color: isDone
                            ? _green800
                            : isOverdue
                                ? _amber800
                                : colors.onSurface.withValues(alpha: 0.55),
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => context.push('/lessons/${first.lessonId}'),
                icon: const Icon(Icons.people_outline, size: 16),
                label: Text(t.openDetail),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, 38),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  textStyle: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w500),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Lesson Tile (learner row)
// ─────────────────────────────────────────────────────────────────

class _LessonTile extends StatelessWidget {
  final LessonModel lesson;
  const _LessonTile({required this.lesson});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final hasLink =
        lesson.meetingLink != null && lesson.meetingLink!.trim().isNotEmpty;

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 6, 14, 6),
      child: Row(
        children: [
          // Icon / link button
          hasLink
              ? InkWell(
                  onTap: () =>
                      _openMeetingLink(context, lesson.meetingLink!.trim()),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      border:
                          Border.all(color: colors.outlineVariant, width: 0.5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.video_call_outlined,
                        size: 19,
                        color: colors.onSurface.withValues(alpha: 0.6)),
                  ),
                )
              : Container(
                  width: 32,
                  height: 32,
                  alignment: Alignment.center,
                  child: Icon(Icons.schedule_outlined,
                      size: 19,
                      color: colors.onSurface.withValues(alpha: 0.35)),
                ),

          const SizedBox(width: 10),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _lessonTimeText(lesson),
                  style: theme.textTheme.bodyLarge
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  'Booking #${lesson.bookingId} · ${lesson.duration} min',
                  style: theme.textTheme.bodyLarge?.copyWith(
                      color: colors.onSurface.withValues(alpha: 0.5)),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),
          _StatusChip(status: lesson.status),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Shared helpers
// ─────────────────────────────────────────────────────────────────

class _MetaRow extends StatelessWidget {
  final IconData icon;
  final String label;
  const _MetaRow({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 20, color: colors.onSurface.withValues(alpha: 0.4)),
        const SizedBox(width: 7),
        Flexible(
          child: Text(label,
              style: TextStyle(
                  fontSize: 15,
                  color: colors.onSurface.withValues(alpha: 0.6))),
        ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final (bg, fg, border) = _colors(status);
    final t = context.l10n;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: border, width: 0.5),
      ),
      child: Text(t.status(status),
          style:
              TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: fg)),
    );
  }

  (Color, Color, Color) _colors(String value) {
    switch (value.toLowerCase()) {
      case 'completed':
        return (
          const Color(0xFFEAF3DE),
          const Color(0xFF3B6D11),
          const Color(0xFFC0DD97)
        );
      case 'cancelled':
      case 'expired':
      case 'failed':
        return (
          const Color(0xFFFCEBEB),
          const Color(0xFFA32D2D),
          const Color(0xFFF7C1C1)
        );
      case 'scheduled':
      default:
        return (
          const Color(0xFFFAEEDA),
          const Color(0xFF854F0B),
          const Color(0xFFFAC775)
        );
    }
  }
}

// ─────────────────────────────────────────────────────────────────
// Module-level helpers (unchanged logic from original)
// ─────────────────────────────────────────────────────────────────

Map<String, List<LessonModel>> _groupLessonsBySession(
    List<LessonModel> lessons) {
  final grouped = <String, List<LessonModel>>{};
  for (final lesson in lessons) {
    final key = _sessionKey(lesson);
    grouped.putIfAbsent(key, () => []);
    grouped[key]!.add(lesson);
  }
  return grouped;
}

String _subjectName(LessonModel lesson) {
  final name = lesson.subjectName;
  if (name != null && name.trim().isNotEmpty) return name;
  return 'Subject #${lesson.subjectId ?? '-'}';
}

String _lessonTimeText(LessonModel lesson) {
  final start = lesson.scheduleTime.toLocal();
  final end = start.add(Duration(minutes: lesson.duration));
  return '${DateFormat('dd/MM/yyyy HH:mm').format(start)} - '
      '${DateFormat('HH:mm').format(end)}';
}

String _sessionKey(LessonModel lesson) =>
    '${lesson.availabilityId}-${lesson.scheduleTime.toUtc().toIso8601String()}';

String _groupStatus(List<LessonModel> lessons) {
  if (lessons.every((x) => x.status.toLowerCase() == 'completed')) {
    return 'Completed';
  }
  if (lessons.any((x) => x.status.toLowerCase() == 'scheduled')) {
    return 'Scheduled';
  }
  return lessons.first.status;
}

Future<void> _openMeetingLink(BuildContext context, String link) async {
  final uri = Uri.tryParse(link);
  final t = AppStrings.of(context, listen: false);
  if (uri == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(t.invalidMeetingLink),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
    return;
  }
  final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (!opened && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(t.couldNotOpenMeeting),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}
