import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/mvp_models.dart';
import '../../providers/app_data_provider.dart';
import '../../widgets/error_banner.dart';

class LessonDetailScreen extends StatefulWidget {
  final int lessonId;

  const LessonDetailScreen({
    super.key,
    required this.lessonId,
  });

  @override
  State<LessonDetailScreen> createState() => _LessonDetailScreenState();
}

class _LessonDetailScreenState extends State<LessonDetailScreen> {
  final meetingLink = TextEditingController();

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _reload();

      if (!mounted) return;

      final detail =
      context.read<AppDataProvider>().lessonDetails[widget.lessonId];

      if (detail != null && detail.meetingLink.trim().isNotEmpty) {
        meetingLink.text = detail.meetingLink;
      }
    });
  }

  @override
  void dispose() {
    meetingLink.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    await context.read<AppDataProvider>().loadLessonDetail(widget.lessonId);
  }

  Future<void> _openMeeting(String link) async {
    final uri = Uri.tryParse(link.trim());

    if (uri == null) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid meeting link')),
      );
      return;
    }

    final opened = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );

    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open meeting link')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = context.watch<AppDataProvider>();
    final detail = data.lessonDetails[widget.lessonId];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lesson detail'),
        actions: [
          IconButton(
            onPressed: data.loading ? null : _reload,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: detail == null
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: _reload,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            ErrorBanner(data.error),
            _LessonHeaderCard(detail: detail),
            const SizedBox(height: 12),
            _MeetingLinkCard(
              controller: meetingLink,
              detail: detail,
              loading: data.loading,
              onOpenMeeting: _openMeeting,
              onSave: _saveMeetingLink,
            ),
            const SizedBox(height: 16),
            Text(
              'Students',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ...detail.students.map(
                  (student) => _StudentAttendanceCard(
                detail: detail,
                student: student,
                loading: data.loading,
                onMarkAttendance: _markAttendance,
              ),
            ),
            const SizedBox(height: 16),
            _CompleteLessonButton(
              detail: detail,
              loading: data.loading,
              onComplete: _completeLesson,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveMeetingLink() async {
    final value = meetingLink.text.trim();

    try {
      await context.read<AppDataProvider>().setLessonMeetingLink(
        lessonId: widget.lessonId,
        meetingLink: value,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Meeting link saved')),
      );
    } catch (_) {
      // ErrorBanner will show provider error.
    }
  }

  Future<void> _markAttendance({
    required int studentLessonId,
    required String status,
  }) async {
    try {
      await context.read<AppDataProvider>().markStudentAttendance(
        mainLessonId: widget.lessonId,
        studentLessonId: studentLessonId,
        status: status,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Marked as $status')),
      );
    } catch (_) {
      // ErrorBanner will show provider error.
    }
  }

  Future<void> _completeLesson() async {
    try {
      await context.read<AppDataProvider>().completeLessonGroup(widget.lessonId);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lesson completed')),
      );
    } catch (_) {
      // ErrorBanner will show provider error.
    }
  }
}

class _LessonHeaderCard extends StatelessWidget {
  final LessonDetailModel detail;

  const _LessonHeaderCard({
    required this.detail,
  });

  @override
  Widget build(BuildContext context) {
    final start = detail.scheduleTime.toLocal();
    final end = start.add(Duration(minutes: detail.duration));

    final formatter = DateFormat('dd/MM/yyyy HH:mm');
    final timeFormatter = DateFormat('HH:mm');

    return Card(
      child: ListTile(
        leading: _StatusIcon(status: detail.status),
        title: Text(
          '${formatter.format(start)} - ${timeFormatter.format(end)}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          'Duration: ${detail.duration} minutes\n'
              'Status: ${detail.status}',
        ),
      ),
    );
  }
}

class _MeetingLinkCard extends StatelessWidget {
  final TextEditingController controller;
  final LessonDetailModel detail;
  final bool loading;
  final Future<void> Function(String link) onOpenMeeting;
  final Future<void> Function() onSave;

  const _MeetingLinkCard({
    required this.controller,
    required this.detail,
    required this.loading,
    required this.onOpenMeeting,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    final hasMeetingLink = detail.meetingLink.trim().isNotEmpty;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Google Meet link',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Meeting link',
                hintText: 'Paste Google Meet link here',
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: loading ? null : onSave,
                    icon: const Icon(Icons.save),
                    label: Text(loading ? 'Saving...' : 'Save link'),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: hasMeetingLink
                      ? () => onOpenMeeting(detail.meetingLink)
                      : null,
                  icon: const Icon(Icons.open_in_new),
                  label: const Text('Open'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StudentAttendanceCard extends StatelessWidget {
  final LessonDetailModel detail;
  final LessonStudentModel student;
  final bool loading;
  final Future<void> Function({
  required int studentLessonId,
  required String status,
  }) onMarkAttendance;

  const _StudentAttendanceCard({
    required this.detail,
    required this.student,
    required this.loading,
    required this.onMarkAttendance,
  });

  @override
  Widget build(BuildContext context) {
    final lessonCompleted = student.lessonStatus.toLowerCase() == 'completed';

    final canTakeAttendance =
        detail.canTakeAttendance && !lessonCompleted && !loading;

    String trailingText;

    if (lessonCompleted) {
      trailingText = 'Locked';
    } else if (!detail.canTakeAttendance) {
      trailingText = 'Not started';
    } else {
      trailingText = '';
    }

    return Card(
      child: ListTile(
        title: Text(student.studentName),
        subtitle: Text(
          'Attendance: ${student.attendanceStatus}\n'
              'Lesson: ${student.lessonStatus}',
        ),
        trailing: canTakeAttendance
            ? PopupMenuButton<String>(
          onSelected: (value) {
            onMarkAttendance(
              studentLessonId: student.lessonId,
              status: value,
            );
          },
          itemBuilder: (_) => const [
            PopupMenuItem(
              value: 'Present',
              child: Text('Present'),
            ),
            PopupMenuItem(
              value: 'Absent',
              child: Text('Absent'),
            ),
            PopupMenuItem(
              value: 'Late',
              child: Text('Late'),
            ),
          ],
        )
            : Text(trailingText),
      ),
    );
  }
}

class _CompleteLessonButton extends StatelessWidget {
  final LessonDetailModel detail;
  final bool loading;
  final Future<void> Function() onComplete;

  const _CompleteLessonButton({
    required this.detail,
    required this.loading,
    required this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    final status = detail.status.toLowerCase();

    final alreadyCompleted = status == 'completed';

    final allStudentsCompleted = detail.students.isNotEmpty &&
        detail.students.every(
              (x) => x.lessonStatus.toLowerCase() == 'completed',
        );

    final canComplete =
        detail.canComplete && !alreadyCompleted && !allStudentsCompleted;

    if (alreadyCompleted || allStudentsCompleted) {
      return const Card(
        child: ListTile(
          leading: Icon(Icons.lock_outline),
          title: Text('Lesson completed'),
          subtitle: Text(
            'Attendance and completion actions are now locked.',
          ),
        ),
      );
    }

    if (!detail.canComplete) {
      return const Card(
        child: ListTile(
          leading: Icon(Icons.schedule_outlined),
          title: Text('Complete lesson unavailable'),
          subtitle: Text(
            'You can complete this lesson after the lesson end time.',
          ),
        ),
      );
    }

    return FilledButton.icon(
      onPressed: !canComplete || loading ? null : onComplete,
      icon: loading
          ? const SizedBox(
        width: 18,
        height: 18,
        child: CircularProgressIndicator(strokeWidth: 2),
      )
          : const Icon(Icons.check_circle_outline),
      label: Text(loading ? 'Completing...' : 'Complete lesson'),
    );
  }
}

class _StatusIcon extends StatelessWidget {
  final String status;

  const _StatusIcon({
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final normalized = status.toLowerCase();

    if (normalized == 'completed') {
      return const Icon(Icons.check_circle_outline);
    }

    if (normalized == 'cancelled' ||
        normalized == 'expired' ||
        normalized == 'failed') {
      return const Icon(Icons.cancel_outlined);
    }

    return const Icon(Icons.schedule_outlined);
  }
}