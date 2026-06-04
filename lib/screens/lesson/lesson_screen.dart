import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/mvp_models.dart';
import '../../providers/app_data_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/error_banner.dart';

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
    final auth = context.watch<AuthProvider>();

    final lessons = [...data.lessons]
      ..sort((a, b) => a.scheduleTime.compareTo(b.scheduleTime));

    final nextLesson = _findNextLesson(
      lessons: lessons,
      isTutor: auth.isTutor,
    );

    final overdueSessions = auth.isTutor
        ? _findOverdueTutorSessions(lessons)
        : <_TutorSessionInfo>[];

    final learnerGrouped = _groupLearnerLessonsByTutorThenAvailability(lessons);
    final tutorGrouped = _groupTutorLessonsByAvailability(lessons);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lessons'),
        actions: [
          IconButton(
            onPressed: data.loading ? null : data.loadLessons,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: data.loadLessons,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 16),
          children: [
            ErrorBanner(data.error),

            if (auth.isTutor && overdueSessions.isNotEmpty)
              _TutorReminderBox(sessions: overdueSessions),

            if (nextLesson != null)
              _NextLessonBox(
                info: nextLesson,
                isTutor: auth.isTutor,
              ),

            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Text(
                auth.isTutor ? 'My teaching lessons' : 'My learning lessons',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            if (data.loading && lessons.isEmpty)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              ),

            if (!data.loading && lessons.isEmpty)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Text('No lessons yet. Pay a booking first.'),
              ),

            if (auth.isTutor)
              ...tutorGrouped.values.map((availabilityLessons) {
                return _TutorAvailabilityCard(
                  lessons: availabilityLessons,
                );
              })
            else
              ...learnerGrouped.values.map((availabilityGroups) {
                return _LearnerTutorCard(
                  availabilityGroups: availabilityGroups,
                );
              }),
          ],
        ),
      ),
    );
  }

  _NextLessonInfo? _findNextLesson({
    required List<LessonModel> lessons,
    required bool isTutor,
  }) {
    final now = DateTime.now();

    if (isTutor) {
      final sessions = _groupLessonsBySession(lessons).values
          .map((sessionLessons) => _TutorSessionInfo.fromLessons(sessionLessons))
          .where((session) {
        final status = session.status.toLowerCase();

        return status != 'completed' && session.endTime.isAfter(now);
      }).toList()
        ..sort((a, b) => a.startTime.compareTo(b.startTime));

      if (sessions.isEmpty) return null;

      final next = sessions.first;

      return _NextLessonInfo(
        lesson: next.mainLesson,
        studentCount: next.studentCount,
      );
    }

    final upcoming = lessons.where((lesson) {
      final status = lesson.status.toLowerCase();
      final endTime = lesson.scheduleTime
          .toLocal()
          .add(Duration(minutes: lesson.duration));

      return status != 'completed' && endTime.isAfter(now);
    }).toList()
      ..sort((a, b) => a.scheduleTime.compareTo(b.scheduleTime));

    if (upcoming.isEmpty) return null;

    return _NextLessonInfo(
      lesson: upcoming.first,
      studentCount: 1,
    );
  }

  List<_TutorSessionInfo> _findOverdueTutorSessions(
      List<LessonModel> lessons,
      ) {
    final now = DateTime.now();

    final sessions = _groupLessonsBySession(lessons).values
        .map((sessionLessons) => _TutorSessionInfo.fromLessons(sessionLessons))
        .where((session) {
      final status = session.status.toLowerCase();

      return status != 'completed' && !session.endTime.isAfter(now);
    }).toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));

    return sessions;
  }

  Map<int, Map<int, List<LessonModel>>>
  _groupLearnerLessonsByTutorThenAvailability(
      List<LessonModel> lessons,
      ) {
    final grouped = <int, Map<int, List<LessonModel>>>{};

    for (final lesson in lessons) {
      grouped.putIfAbsent(lesson.tutorId, () => <int, List<LessonModel>>{});
      grouped[lesson.tutorId]!.putIfAbsent(
        lesson.availabilityId,
            () => <LessonModel>[],
      );
      grouped[lesson.tutorId]![lesson.availabilityId]!.add(lesson);
    }

    return grouped;
  }

  Map<int, List<LessonModel>> _groupTutorLessonsByAvailability(
      List<LessonModel> lessons,
      ) {
    final grouped = <int, List<LessonModel>>{};

    for (final lesson in lessons) {
      grouped.putIfAbsent(lesson.availabilityId, () => <LessonModel>[]);
      grouped[lesson.availabilityId]!.add(lesson);
    }

    return grouped;
  }
}

class _NextLessonInfo {
  final LessonModel lesson;
  final int studentCount;

  const _NextLessonInfo({
    required this.lesson,
    required this.studentCount,
  });
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

class _TutorReminderBox extends StatelessWidget {
  final List<_TutorSessionInfo> sessions;

  const _TutorReminderBox({
    required this.sessions,
  });

  @override
  Widget build(BuildContext context) {
    final shown = sessions.take(3).toList();
    final hiddenCount = sessions.length - shown.length;

    return Card(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.notification_important_outlined),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Attendance reminder',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'These lessons have ended but are not completed yet. Open the detail page, take attendance, then complete the lesson.',
            ),
            const SizedBox(height: 12),
            ...shown.map((session) {
              final lesson = session.mainLesson;

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outlineVariant,
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.pending_actions_outlined),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _subjectName(lesson),
                              style:
                              const TextStyle(fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 2),
                            Text(_lessonTimeText(lesson)),
                            Text(
                              '${session.studentCount} student${session.studentCount == 1 ? '' : 's'} • ${session.status}',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: () =>
                            context.push('/lessons/${lesson.lessonId}'),
                        child: const Text('Open'),
                      ),
                    ],
                  ),
                ),
              );
            }),
            if (hiddenCount > 0)
              Text(
                '+$hiddenCount more lesson session${hiddenCount == 1 ? '' : 's'} need attention.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
          ],
        ),
      ),
    );
  }
}

class _NextLessonBox extends StatelessWidget {
  final _NextLessonInfo info;
  final bool isTutor;

  const _NextLessonBox({
    required this.info,
    required this.isTutor,
  });

  @override
  Widget build(BuildContext context) {
    final lesson = info.lesson;
    final subjectName = _subjectName(lesson);

    return Card(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              child: Icon(
                isTutor
                    ? Icons.event_available_outlined
                    : Icons.school_outlined,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Next lesson',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subjectName,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(_lessonTimeText(lesson)),
                  const SizedBox(height: 4),
                  Text(
                    isTutor
                        ? '${info.studentCount} student${info.studentCount == 1 ? '' : 's'}'
                        : 'Tutor: ${lesson.tutorName}',
                  ),
                  const SizedBox(height: 10),
                  if (isTutor)
                    FilledButton.icon(
                      onPressed: () =>
                          context.push('/lessons/${lesson.lessonId}'),
                      icon: const Icon(Icons.people_outline),
                      label: const Text('Open lesson detail'),
                    )
                  else
                    OutlinedButton.icon(
                      onPressed: lesson.meetingLink != null &&
                          lesson.meetingLink!.trim().isNotEmpty
                          ? () => _openMeetingLink(
                        context,
                        lesson.meetingLink!.trim(),
                      )
                          : null,
                      icon: const Icon(Icons.video_call_outlined),
                      label: Text(
                        lesson.meetingLink != null &&
                            lesson.meetingLink!.trim().isNotEmpty
                            ? 'Open meeting'
                            : 'Meeting link not added yet',
                      ),
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

class _LearnerTutorCard extends StatelessWidget {
  final Map<int, List<LessonModel>> availabilityGroups;

  const _LearnerTutorCard({
    required this.availabilityGroups,
  });

  @override
  Widget build(BuildContext context) {
    final allLessons = availabilityGroups.values.expand((x) => x).toList();

    if (allLessons.isEmpty) return const SizedBox.shrink();

    final first = allLessons.first;

    return Card(
      child: ExpansionTile(
        leading: const CircleAvatar(
          child: Icon(Icons.person_outline),
        ),
        title: Text(
          first.tutorName,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        subtitle: Text(
          '${allLessons.length} lesson${allLessons.length == 1 ? '' : 's'} '
              'in ${availabilityGroups.length} course${availabilityGroups.length == 1 ? '' : 's'}',
        ),
        children: availabilityGroups.values.map((lessons) {
          return _LearnerAvailabilityGroup(lessons: lessons);
        }).toList(),
      ),
    );
  }
}

class _LearnerAvailabilityGroup extends StatelessWidget {
  final List<LessonModel> lessons;

  const _LearnerAvailabilityGroup({
    required this.lessons,
  });

  @override
  Widget build(BuildContext context) {
    if (lessons.isEmpty) return const SizedBox.shrink();

    final sorted = [...lessons]
      ..sort((a, b) => a.scheduleTime.compareTo(b.scheduleTime));

    final first = sorted.first;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: ExpansionTile(
          title: Text(
            _subjectName(first),
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          subtitle: Text(
            'Availability #${first.availabilityId} • '
                '${sorted.length} lesson${sorted.length == 1 ? '' : 's'}',
          ),
          children: sorted.map((lesson) {
            return _LessonTile(lesson: lesson);
          }).toList(),
        ),
      ),
    );
  }
}

class _TutorAvailabilityCard extends StatelessWidget {
  final List<LessonModel> lessons;

  const _TutorAvailabilityCard({
    required this.lessons,
  });

  @override
  Widget build(BuildContext context) {
    if (lessons.isEmpty) return const SizedBox.shrink();

    final first = lessons.first;
    final sessions = _groupLessonsBySession(lessons).values.toList()
      ..sort((a, b) => a.first.scheduleTime.compareTo(b.first.scheduleTime));

    final totalStudents = lessons.length;

    return Card(
      child: ExpansionTile(
        leading: const CircleAvatar(
          child: Icon(Icons.event_note_outlined),
        ),
        title: Text(
          _subjectName(first),
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        subtitle: Text(
          'Availability #${first.availabilityId}\n'
              '${sessions.length} session${sessions.length == 1 ? '' : 's'} • '
              '$totalStudents student lesson rows',
        ),
        children: sessions.map((sessionLessons) {
          return _TutorSessionTile(lessons: sessionLessons);
        }).toList(),
      ),
    );
  }
}

class _TutorSessionTile extends StatelessWidget {
  final List<LessonModel> lessons;

  const _TutorSessionTile({
    required this.lessons,
  });

  @override
  Widget build(BuildContext context) {
    if (lessons.isEmpty) return const SizedBox.shrink();

    final session = _TutorSessionInfo.fromLessons(lessons);
    final first = session.mainLesson;
    final status = session.status;

    final now = DateTime.now();

    String helper;

    if (status.toLowerCase() == 'completed') {
      helper = 'Completed';
    } else if (!session.endTime.isAfter(now)) {
      helper = 'Ended. Take attendance and complete this lesson.';
    } else if (!session.startTime.isAfter(now)) {
      helper = 'Lesson started. Completion unlocks after end time.';
    } else {
      helper = 'Starts later';
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.all(12),
          title: Text(
            _lessonTimeText(first),
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          subtitle: Text(
            '${session.studentCount} student${session.studentCount == 1 ? '' : 's'}\n'
                'Status: $status\n'
                '$helper',
          ),
          trailing: FilledButton.icon(
            onPressed: () => context.push('/lessons/${first.lessonId}'),
            icon: const Icon(Icons.people_outline),
            label: const Text('Detail'),
          ),
        ),
      ),
    );
  }
}

class _LessonTile extends StatelessWidget {
  final LessonModel lesson;

  const _LessonTile({
    required this.lesson,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      leading: lesson.meetingLink != null &&
          lesson.meetingLink!.trim().isNotEmpty
          ? IconButton(
        icon: const Icon(Icons.video_call_outlined),
        onPressed: () => _openMeetingLink(
          context,
          lesson.meetingLink!.trim(),
        ),
      )
          : const Icon(Icons.schedule_outlined),
      title: Text(
        _lessonTimeText(lesson),
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      subtitle: Text(
        'Booking #${lesson.bookingId} • ${lesson.duration} minutes',
      ),
      trailing: _StatusChip(status: lesson.status),
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
      label: Text(status),
      backgroundColor: color.withValues(alpha: 0.15),
      side: BorderSide(
        color: color.withValues(alpha: 0.4),
      ),
    );
  }

  Color _statusColor(String value) {
    switch (value.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'cancelled':
      case 'expired':
      case 'failed':
        return Colors.red;
      case 'scheduled':
      default:
        return Colors.orange;
    }
  }
}

Map<String, List<LessonModel>> _groupLessonsBySession(
    List<LessonModel> lessons,
    ) {
  final grouped = <String, List<LessonModel>>{};

  for (final lesson in lessons) {
    final key = _sessionKey(lesson);
    grouped.putIfAbsent(key, () => <LessonModel>[]);
    grouped[key]!.add(lesson);
  }

  return grouped;
}

String _subjectName(LessonModel lesson) {
  final name = lesson.subjectName;

  if (name != null && name.trim().isNotEmpty) {
    return name;
  }

  return 'Subject #${lesson.subjectId ?? '-'}';
}

String _lessonTimeText(LessonModel lesson) {
  final start = lesson.scheduleTime.toLocal();
  final end = start.add(Duration(minutes: lesson.duration));

  return '${DateFormat('dd/MM/yyyy HH:mm').format(start)} - '
      '${DateFormat('HH:mm').format(end)}';
}

String _sessionKey(LessonModel lesson) {
  return '${lesson.availabilityId}-${lesson.scheduleTime.toUtc().toIso8601String()}';
}

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

  if (uri == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Invalid meeting link')),
    );
    return;
  }

  final opened = await launchUrl(
    uri,
    mode: LaunchMode.externalApplication,
  );

  if (!opened && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Could not open meeting link')),
    );
  }
}