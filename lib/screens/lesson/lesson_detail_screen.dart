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
      _showSnack('Invalid meeting link');
      return;
    }
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && mounted) _showSnack('Could not open meeting link');
  }

  Future<void> _saveMeetingLink() async {
    try {
      await context.read<AppDataProvider>().setLessonMeetingLink(
            lessonId: widget.lessonId,
            meetingLink: meetingLink.text.trim(),
          );
      if (!mounted) return;
      _showSnack('Meeting link saved');
    } catch (_) {}
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
      _showSnack('Marked as $status');
    } catch (_) {}
  }

  Future<void> _completeLesson() async {
    try {
      await context
          .read<AppDataProvider>()
          .completeLessonGroup(widget.lessonId);
      if (!mounted) return;
      _showSnack('Lesson completed');
    } catch (_) {}
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = context.watch<AppDataProvider>();
    final detail = data.lessonDetails[widget.lessonId];
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      backgroundColor: colors.surfaceContainerLowest,
      appBar: AppBar(
        backgroundColor: colors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        titleSpacing: 4,
        title: Text(
          'Lesson detail',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
            letterSpacing: -0.3,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: IconButton.outlined(
              onPressed: data.loading ? null : _reload,
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
      body: detail == null
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _reload,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 32),
                children: [
                  ErrorBanner(data.error),

                  _LessonHeaderCard(detail: detail),
                  const SizedBox(height: 10),

                  _MeetingLinkCard(
                    controller: meetingLink,
                    detail: detail,
                    loading: data.loading,
                    onOpenMeeting: _openMeeting,
                    onSave: _saveMeetingLink,
                  ),
                  const SizedBox(height: 18),

                  // Students section label
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        Text(
                          'Students',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 9, vertical: 3),
                          decoration: BoxDecoration(
                            color: colors.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: Text(
                            '${detail.students.length}',
                            style: theme.textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: colors.onSurface
                                  .withValues(alpha: 0.6),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  ...detail.students.map(
                    (student) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _StudentAttendanceCard(
                        detail: detail,
                        student: student,
                        loading: data.loading,
                        onMarkAttendance: _markAttendance,
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),
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
}

// ─────────────────────────────────────────────────────────────────
// Lesson Header Card
// ─────────────────────────────────────────────────────────────────

class _LessonHeaderCard extends StatelessWidget {
  final LessonDetailModel detail;
  const _LessonHeaderCard({required this.detail});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final start = detail.scheduleTime.toLocal();
    final end = start.add(Duration(minutes: detail.duration));
    final dateStr = DateFormat('dd/MM/yyyy').format(start);
    final timeStr =
        '${DateFormat('HH:mm').format(start)} — ${DateFormat('HH:mm').format(end)}';

    final (statusBg, statusFg, statusBorder) = _statusColors(detail.status);

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: colors.outlineVariant.withValues(alpha: 0.5), width: 0.5),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Status icon circle
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: statusBg,
              shape: BoxShape.circle,
              border: Border.all(color: statusBorder, width: 0.5),
            ),
            child: Icon(_statusIcon(detail.status), size: 22, color: statusFg),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dateStr,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: colors.onSurface.withValues(alpha: 0.5),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  timeStr,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${detail.duration} minutes',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
          // Status chip
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: statusBg,
              borderRadius: BorderRadius.circular(100),
              border: Border.all(color: statusBorder, width: 0.5),
            ),
            child: Text(
              detail.status,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: statusFg,
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _statusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Icons.check_circle_outline_rounded;
      case 'cancelled':
      case 'expired':
      case 'failed':
        return Icons.cancel_outlined;
      default:
        return Icons.schedule_outlined;
    }
  }

  (Color, Color, Color) _statusColors(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return (
          const Color(0xFFEAF3DE),
          const Color(0xFF3B6D11),
          const Color(0xFFC0DD97),
        );
      case 'cancelled':
      case 'expired':
      case 'failed':
        return (
          const Color(0xFFFCEBEB),
          const Color(0xFFA32D2D),
          const Color(0xFFF7C1C1),
        );
      default:
        return (
          const Color(0xFFFAEEDA),
          const Color(0xFF854F0B),
          const Color(0xFFFAC775),
        );
    }
  }
}

// ─────────────────────────────────────────────────────────────────
// Meeting Link Card
// ─────────────────────────────────────────────────────────────────

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
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

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
          // Header row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE6F1FB),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.video_call_outlined,
                      size: 18, color: Color(0xFF185FA5)),
                ),
                const SizedBox(width: 10),
                Text(
                  'Google Meet link',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),
          Divider(
              height: 0.5,
              thickness: 0.5,
              color: colors.outlineVariant.withValues(alpha: 0.4)),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(
              children: [
                // Text field
                TextField(
                  controller: controller,
                  style: theme.textTheme.bodyMedium,
                  decoration: InputDecoration(
                    labelText: 'Meeting link',
                    hintText: 'Paste Google Meet link here',
                    prefixIcon: const Icon(Icons.link_rounded, size: 20),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                          color: colors.outlineVariant, width: 0.5),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                          color: colors.outlineVariant, width: 0.5),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide:
                          BorderSide(color: colors.primary, width: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: loading ? null : onSave,
                        icon: loading
                            ? const SizedBox(
                                width: 15,
                                height: 15,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white),
                              )
                            : const Icon(Icons.save_outlined, size: 17),
                        label:
                            Text(loading ? 'Saving...' : 'Save link'),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(0, 42),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                          textStyle: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: hasMeetingLink
                          ? () => onOpenMeeting(detail.meetingLink)
                          : null,
                      icon: const Icon(Icons.open_in_new_rounded, size: 16),
                      label: const Text('Open'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 42),
                        side: BorderSide(
                            color: colors.outlineVariant, width: 0.5),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        textStyle: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
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
// Student Attendance Card
// ─────────────────────────────────────────────────────────────────

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
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final lessonCompleted =
        student.lessonStatus.toLowerCase() == 'completed';
    final canTakeAttendance =
        detail.canTakeAttendance && !lessonCompleted && !loading;

    String? trailingLabel;
    if (lessonCompleted) {
      trailingLabel = 'Locked';
    } else if (!detail.canTakeAttendance) {
      trailingLabel = 'Not started';
    }

    final (attBg, attFg, attBorder) =
        _attendanceColors(student.attendanceStatus);
    final initials = _initials(student.studentName);

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: colors.outlineVariant.withValues(alpha: 0.5), width: 0.5),
      ),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: colors.surfaceContainerHighest,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              initials,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: colors.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  student.studentName,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    // Attendance chip
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: attBg,
                        borderRadius: BorderRadius.circular(100),
                        border:
                            Border.all(color: attBorder, width: 0.5),
                      ),
                      child: Text(
                        student.attendanceStatus,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: attFg,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '· ${student.lessonStatus}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // Trailing: popup or label
          if (canTakeAttendance)
            PopupMenuButton<String>(
              onSelected: (value) => onMarkAttendance(
                studentLessonId: student.lessonId,
                status: value,
              ),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'Present', child: Text('Present')),
                PopupMenuItem(value: 'Absent', child: Text('Absent')),
                PopupMenuItem(value: 'Late', child: Text('Late')),
              ],
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  border: Border.all(
                      color: colors.outlineVariant, width: 0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Mark',
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.expand_more_rounded,
                        size: 16,
                        color: colors.onSurface.withValues(alpha: 0.5)),
                  ],
                ),
              ),
            )
          else if (trailingLabel != null)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: colors.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                trailingLabel,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colors.onSurface.withValues(alpha: 0.45),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  (Color, Color, Color) _attendanceColors(String status) {
    switch (status.toLowerCase()) {
      case 'present':
        return (
          const Color(0xFFEAF3DE),
          const Color(0xFF3B6D11),
          const Color(0xFFC0DD97),
        );
      case 'absent':
        return (
          const Color(0xFFFCEBEB),
          const Color(0xFFA32D2D),
          const Color(0xFFF7C1C1),
        );
      case 'late':
        return (
          const Color(0xFFFAEEDA),
          const Color(0xFF854F0B),
          const Color(0xFFFAC775),
        );
      default:
        return (
          const Color(0xFFF1EFE8),
          const Color(0xFF5F5E5A),
          const Color(0xFFD3D1C7),
        );
    }
  }
}

// ─────────────────────────────────────────────────────────────────
// Complete Lesson Button
// ─────────────────────────────────────────────────────────────────

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
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final status = detail.status.toLowerCase();
    final alreadyCompleted = status == 'completed';
    final allStudentsCompleted = detail.students.isNotEmpty &&
        detail.students
            .every((x) => x.lessonStatus.toLowerCase() == 'completed');
    final canComplete =
        detail.canComplete && !alreadyCompleted && !allStudentsCompleted;

    // Locked state
    if (alreadyCompleted || allStudentsCompleted) {
      return Container(
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: colors.outlineVariant.withValues(alpha: 0.5),
              width: 0.5),
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: const Color(0xFFEAF3DE),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.lock_outline_rounded,
                  size: 20, color: Color(0xFF3B6D11)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Lesson completed',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Attendance and completion actions are now locked.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.onSurface.withValues(alpha: 0.55),
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Not yet available
    if (!detail.canComplete) {
      return Container(
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: colors.outlineVariant.withValues(alpha: 0.5),
              width: 0.5),
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: const Color(0xFFFAEEDA),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.schedule_outlined,
                  size: 20, color: Color(0xFF854F0B)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Complete lesson unavailable',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'You can complete this lesson after the lesson end time.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.onSurface.withValues(alpha: 0.55),
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Available
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: !canComplete || loading ? null : onComplete,
        icon: loading
            ? const SizedBox(
                width: 17,
                height: 17,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              )
            : const Icon(Icons.check_circle_outline_rounded, size: 18),
        label: Text(loading ? 'Completing...' : 'Complete lesson'),
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 48),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(
              fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}