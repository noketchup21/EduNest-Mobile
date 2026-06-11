import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/mvp_models.dart';
import '../../providers/app_data_provider.dart';
import '../../providers/auth_provider.dart';
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
    final data = context.read<AppDataProvider>();
    final auth = context.read<AuthProvider>();
    await data.loadLessonDetail(widget.lessonId);
    if (!auth.isTutor) {
      await data.loadLessonHomeworks(widget.lessonId);
    }
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

  Future<void> _createHomework() async {
    final body = await _showHomeworkEditorSheet(context);
    if (body == null || !mounted) return;

    try {
      await context.read<AppDataProvider>().createHomework(
            lessonId: widget.lessonId,
            body: body,
          );
      if (!mounted) return;
      _showSnack('Homework created');
    } catch (_) {}
  }

  Future<void> _editHomework(HomeworkModel homework) async {
    if (homework.submissions.isNotEmpty) {
      _showSnack('Homework cannot be edited after a submission is received');
      return;
    }

    final body = await _showHomeworkEditorSheet(context, homework: homework);
    if (body == null || !mounted) return;

    try {
      await context.read<AppDataProvider>().updateHomework(
            lessonId: widget.lessonId,
            homeworkId: homework.homeworkId,
            body: body,
          );
      if (!mounted) return;
      _showSnack('Homework updated');
    } catch (_) {}
  }

  Future<void> _deleteHomework(HomeworkModel homework) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete homework?'),
        content: Text('Delete "${homework.title}" and its submissions?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await context.read<AppDataProvider>().deleteHomework(
            lessonId: widget.lessonId,
            homeworkId: homework.homeworkId,
          );
      if (!mounted) return;
      _showSnack('Homework deleted');
    } catch (_) {}
  }

  void _viewHomework(HomeworkModel homework) {
    context.push('/homework/${widget.lessonId}/${homework.homeworkId}');
  }

  Future<void> _submitHomework(HomeworkModel homework) async {
    final payload = await _showHomeworkSubmitSheet(context, homework);
    if (payload == null || !mounted) return;

    try {
      await context.read<AppDataProvider>().submitHomework(
            lessonId: widget.lessonId,
            homeworkId: homework.homeworkId,
            multipleChoiceAnswers: payload.multipleChoiceAnswers,
            essayAnswers: payload.essayAnswers,
          );
      if (!mounted) return;
      _showSnack('Homework submitted');
    } catch (_) {}
  }

  Future<void> _gradeSubmission({
    required HomeworkModel homework,
    required HomeworkSubmissionModel submission,
  }) async {
    final payload = await _showEssayGradeSheet(
      context,
      homework: homework,
      submission: submission,
    );
    if (payload == null || !mounted) return;

    try {
      await context.read<AppDataProvider>().gradeEssaySubmission(
            lessonId: widget.lessonId,
            homeworkId: homework.homeworkId,
            submissionId: submission.submissionId,
            essayGrades: payload.essayGrades,
            feedback: payload.feedback,
          );
      if (!mounted) return;
      _showSnack('Submission graded');
    } catch (_) {}
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = context.watch<AppDataProvider>();
    final auth = context.watch<AuthProvider>();
    final detail = data.lessonDetails[widget.lessonId];
    final homeworks = data.lessonHomeworks[widget.lessonId] ?? [];
    final isTutor = auth.isTutor;
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
                    isTutor: isTutor,
                    loading: data.loading,
                    onOpenMeeting: _openMeeting,
                    onSave: _saveMeetingLink,
                  ),
                  const SizedBox(height: 18),
                  if (isTutor)
                    _TutorHomeworkShortcutCard(lessonId: widget.lessonId)
                  else
                    _HomeworkSection(
                      homeworks: homeworks,
                      isTutor: isTutor,
                      loading: data.loading,
                      onCreate: _createHomework,
                      onView: _viewHomework,
                      onEdit: _editHomework,
                      onDelete: _deleteHomework,
                      onSubmit: _submitHomework,
                      onGrade: _gradeSubmission,
                    ),
                  const SizedBox(height: 18),
                  if (isTutor) ...[
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
                                color: colors.onSurface.withValues(alpha: 0.6),
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
                ],
              ),
            ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Lesson Header Card
// ─────────────────────────────────────────────────────────────────

class _TutorHomeworkShortcutCard extends StatelessWidget {
  final int lessonId;

  const _TutorHomeworkShortcutCard({required this.lessonId});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: colors.outlineVariant.withValues(alpha: 0.5),
          width: 0.5,
        ),
      ),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFFE6F1FB),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.assignment_outlined,
              color: Color(0xFF185FA5),
              size: 21,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Homework is managed separately',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Create assignments and grade submissions in the Homework tab.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onSurface.withValues(alpha: 0.55),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          OutlinedButton.icon(
            onPressed: () => context.go('/homework?lessonId=$lessonId'),
            icon: const Icon(Icons.open_in_new_rounded, size: 16),
            label: const Text('Open'),
          ),
        ],
      ),
    );
  }
}

class _HomeworkSection extends StatelessWidget {
  final List<HomeworkModel> homeworks;
  final bool isTutor;
  final bool loading;
  final Future<void> Function() onCreate;
  final void Function(HomeworkModel homework) onView;
  final Future<void> Function(HomeworkModel homework) onEdit;
  final Future<void> Function(HomeworkModel homework) onDelete;
  final Future<void> Function(HomeworkModel homework) onSubmit;
  final Future<void> Function({
    required HomeworkModel homework,
    required HomeworkSubmissionModel submission,
  }) onGrade;

  const _HomeworkSection({
    required this.homeworks,
    required this.isTutor,
    required this.loading,
    required this.onCreate,
    required this.onView,
    required this.onEdit,
    required this.onDelete,
    required this.onSubmit,
    required this.onGrade,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Homework',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.2,
                ),
              ),
            ),
            if (isTutor)
              IconButton.outlined(
                onPressed: loading ? null : onCreate,
                tooltip: 'Add homework',
                icon: const Icon(Icons.add_rounded, size: 20),
                style: IconButton.styleFrom(
                  side: BorderSide(color: colors.outlineVariant, width: 0.5),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  minimumSize: const Size(36, 36),
                  padding: EdgeInsets.zero,
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        if (homeworks.isEmpty)
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: colors.outlineVariant.withValues(alpha: 0.5),
                  width: 0.5),
            ),
            padding: const EdgeInsets.all(16),
            child: Text(
              isTutor
                  ? 'No homework yet. Add an assignment for this session.'
                  : 'No homework assigned for this session yet.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.onSurface.withValues(alpha: 0.6),
              ),
            ),
          )
        else
          ...homeworks.map(
            (homework) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _HomeworkCard(
                homework: homework,
                isTutor: isTutor,
                loading: loading,
                onView: () => onView(homework),
                onEdit: () => onEdit(homework),
                onDelete: () => onDelete(homework),
                onSubmit: () => onSubmit(homework),
                onGrade: (submission) => onGrade(
                  homework: homework,
                  submission: submission,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _HomeworkCard extends StatelessWidget {
  final HomeworkModel homework;
  final bool isTutor;
  final bool loading;
  final VoidCallback onView;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onSubmit;
  final void Function(HomeworkSubmissionModel submission) onGrade;

  const _HomeworkCard({
    required this.homework,
    required this.isTutor,
    required this.loading,
    required this.onView,
    required this.onEdit,
    required this.onDelete,
    required this.onSubmit,
    required this.onGrade,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final submitted = homework.mySubmission;
    final hasSubmissions = homework.submissions.isNotEmpty;
    final typeLabel = homework.isMultipleChoice ? 'Multiple choice' : 'Essay';
    final due =
        DateFormat('dd/MM/yyyy HH:mm').format(homework.dueDate.toLocal());

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: colors.outlineVariant.withValues(alpha: 0.5), width: 0.5),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFE6F1FB),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  homework.isMultipleChoice
                      ? Icons.checklist_rounded
                      : Icons.edit_note_rounded,
                  size: 20,
                  color: const Color(0xFF185FA5),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      homework.title,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '$typeLabel - ${homework.totalPoints.g} pts - due $due',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurface.withValues(alpha: 0.55),
                      ),
                    ),
                  ],
                ),
              ),
              if (isTutor)
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'view') onView();
                    if (value == 'edit') onEdit();
                    if (value == 'delete') onDelete();
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                      value: 'view',
                      child: Text('View detail'),
                    ),
                    PopupMenuItem(
                      value: 'edit',
                      enabled: !hasSubmissions,
                      child: Text(
                        hasSubmissions
                            ? 'Edit locked after submission'
                            : 'Edit',
                      ),
                    ),
                    const PopupMenuItem(value: 'delete', child: Text('Delete')),
                  ],
                ),
            ],
          ),
          if (homework.description != null &&
              homework.description!.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              homework.description!,
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
            ),
          ],
          const SizedBox(height: 10),
          if (isTutor)
            _TutorHomeworkSubmissions(
              homework: homework,
              loading: loading,
              onGrade: onGrade,
            )
          else
            _LearnerHomeworkAction(
              homework: homework,
              submission: submitted,
              loading: loading,
              onSubmit: onSubmit,
            ),
        ],
      ),
    );
  }
}

class _LearnerHomeworkAction extends StatelessWidget {
  final HomeworkModel homework;
  final HomeworkSubmissionModel? submission;
  final bool loading;
  final VoidCallback onSubmit;

  const _LearnerHomeworkAction({
    required this.homework,
    required this.submission,
    required this.loading,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    if (submission == null) {
      return SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: loading ? null : onSubmit,
          icon: const Icon(Icons.upload_file_rounded, size: 17),
          label: const Text('Submit homework'),
          style: FilledButton.styleFrom(
            minimumSize: const Size(0, 40),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      );
    }

    final status = submission!.isGraded ? 'Graded' : 'Submitted';
    final score = '${submission!.totalScore.g}/${submission!.maxScore.g}';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$status - $score pts',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          if (submission!.feedback != null &&
              submission!.feedback!.trim().isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(submission!.feedback!, style: theme.textTheme.bodySmall),
          ],
        ],
      ),
    );
  }
}

class _TutorHomeworkSubmissions extends StatelessWidget {
  final HomeworkModel homework;
  final bool loading;
  final void Function(HomeworkSubmissionModel submission) onGrade;

  const _TutorHomeworkSubmissions({
    required this.homework,
    required this.loading,
    required this.onGrade,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    if (homework.submissions.isEmpty) {
      return Text(
        'No submissions yet',
        style: theme.textTheme.bodySmall?.copyWith(
          color: colors.onSurface.withValues(alpha: 0.55),
        ),
      );
    }

    return Column(
      children: homework.submissions.map((submission) {
        final needsGrade = homework.isEssay && !submission.isGraded;
        return Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: colors.outlineVariant.withValues(alpha: 0.45),
                  width: 0.5),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${submission.studentName} - '
                    '${submission.totalScore.g}/${submission.maxScore.g} pts',
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
                if (needsGrade)
                  TextButton(
                    onPressed: loading ? null : () => onGrade(submission),
                    child: const Text('Grade'),
                  )
                else
                  Text(
                    submission.isGraded ? 'Graded' : 'Auto scored',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: colors.onSurface.withValues(alpha: 0.55),
                    ),
                  ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _QuestionDraft {
  final TextEditingController text;
  final TextEditingController points;
  final List<_OptionDraft> options;
  int correctIndex;

  _QuestionDraft({
    String question = '',
    String pointValue = '1',
    List<_OptionDraft>? options,
    this.correctIndex = 0,
  })  : text = TextEditingController(text: question),
        points = TextEditingController(text: pointValue),
        options = options ??
            [
              _OptionDraft(text: ''),
              _OptionDraft(text: ''),
            ];
}

class _OptionDraft {
  final TextEditingController text;

  _OptionDraft({String text = ''}) : text = TextEditingController(text: text);
}

class _EssayDraft {
  final TextEditingController prompt;
  final TextEditingController points;

  _EssayDraft({
    String question = '',
    String pointValue = '10',
  })  : prompt = TextEditingController(text: question),
        points = TextEditingController(text: pointValue);
}

class _HomeworkSubmitPayload {
  final List<Map<String, dynamic>> multipleChoiceAnswers;
  final List<Map<String, dynamic>> essayAnswers;

  const _HomeworkSubmitPayload({
    required this.multipleChoiceAnswers,
    required this.essayAnswers,
  });
}

class _EssayGradePayload {
  final List<Map<String, dynamic>> essayGrades;
  final String? feedback;

  const _EssayGradePayload({
    required this.essayGrades,
    required this.feedback,
  });
}

extension _ScoreFormat on double {
  String get g =>
      this == roundToDouble() ? toInt().toString() : toStringAsFixed(1);
}

Future<Map<String, dynamic>?> _showHomeworkEditorSheet(
  BuildContext context, {
  HomeworkModel? homework,
}) async {
  final title = TextEditingController(text: homework?.title ?? '');
  final description = TextEditingController(text: homework?.description ?? '');
  var type = homework?.type == 'Essay' ? 'Essay' : 'MultipleChoice';
  var dueDate = homework?.dueDate.toLocal() ??
      DateTime.now().add(const Duration(days: 7));
  final essayDrafts = homework?.essays.isNotEmpty == true
      ? homework!.essays.map((essay) {
          return _EssayDraft(
            question: essay.questionText,
            pointValue: essay.points.g,
          );
        }).toList()
      : [_EssayDraft()];
  final questionDrafts = homework?.questions.isNotEmpty == true
      ? homework!.questions.map((question) {
          final options = question.options
              .map((option) => _OptionDraft(text: option.content))
              .toList();
          final correctIndex =
              question.options.indexWhere((option) => option.isCorrect == true);
          return _QuestionDraft(
            question: question.questionText,
            pointValue: question.point.g,
            options: options,
            correctIndex: correctIndex < 0 ? 0 : correctIndex,
          );
        }).toList()
      : [_QuestionDraft()];

  return showModalBottomSheet<Map<String, dynamic>>(
    context: context,
    isScrollControlled: true,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setSheetState) {
          Future<void> pickDueDate() async {
            final picked = await showDatePicker(
              context: context,
              initialDate: dueDate,
              firstDate: DateTime.now().subtract(const Duration(days: 1)),
              lastDate: DateTime.now().add(const Duration(days: 365)),
            );
            if (picked == null) return;
            setSheetState(() {
              dueDate = DateTime(
                picked.year,
                picked.month,
                picked.day,
                dueDate.hour,
                dueDate.minute,
              );
            });
          }

          void save() {
            final titleText = title.text.trim();
            if (titleText.isEmpty) return;

            final body = <String, dynamic>{
              'title': titleText,
              'description': description.text.trim(),
              'type': type,
              'dueDate': dueDate.toUtc().toIso8601String(),
              'questions': <Map<String, dynamic>>[],
              'essays': <Map<String, dynamic>>[],
            };

            if (type == 'MultipleChoice') {
              body['questions'] = questionDrafts.map((question) {
                return {
                  'questionText': question.text.text.trim(),
                  'point': double.tryParse(question.points.text.trim()) ?? 1,
                  'options': question.options.asMap().entries.map((entry) {
                    return {
                      'content': entry.value.text.text.trim(),
                      'isCorrect': entry.key == question.correctIndex,
                    };
                  }).toList(),
                };
              }).toList();
            } else {
              body['essays'] = essayDrafts.map((essay) {
                return {
                  'questionText': essay.prompt.text.trim(),
                  'points': double.tryParse(essay.points.text.trim()) ?? 10,
                };
              }).toList();
            }

            Navigator.pop(context, body);
          }

          return SafeArea(
            child: Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      homework == null ? 'Add homework' : 'Edit homework',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: title,
                      decoration: const InputDecoration(labelText: 'Title'),
                    ),
                    TextField(
                      controller: description,
                      decoration:
                          const InputDecoration(labelText: 'Description'),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      initialValue: type,
                      decoration: const InputDecoration(labelText: 'Type'),
                      items: const [
                        DropdownMenuItem(
                          value: 'MultipleChoice',
                          child: Text('Multiple choice'),
                        ),
                        DropdownMenuItem(value: 'Essay', child: Text('Essay')),
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        setSheetState(() => type = value);
                      },
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: pickDueDate,
                      icon: const Icon(Icons.event_outlined),
                      label: Text(
                        'Due ${DateFormat('dd/MM/yyyy').format(dueDate)}',
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (type == 'MultipleChoice')
                      ...questionDrafts.asMap().entries.map((entry) {
                        final index = entry.key;
                        final question = entry.value;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                      child: Text('Question ${index + 1}')),
                                  IconButton(
                                    onPressed: questionDrafts.length == 1
                                        ? null
                                        : () => setSheetState(
                                              () => questionDrafts
                                                  .removeAt(index),
                                            ),
                                    icon: const Icon(Icons.delete_outline),
                                  ),
                                ],
                              ),
                              TextField(
                                controller: question.text,
                                decoration: const InputDecoration(
                                  labelText: 'Question text',
                                ),
                              ),
                              TextField(
                                controller: question.points,
                                keyboardType: TextInputType.number,
                                decoration:
                                    const InputDecoration(labelText: 'Points'),
                              ),
                              const SizedBox(height: 6),
                              ...question.options.asMap().entries.map((option) {
                                return Row(
                                  children: [
                                    Checkbox(
                                      value:
                                          question.correctIndex == option.key,
                                      onChanged: (_) => setSheetState(
                                        () =>
                                            question.correctIndex = option.key,
                                      ),
                                    ),
                                    Expanded(
                                      child: TextField(
                                        controller: option.value.text,
                                        decoration: InputDecoration(
                                          labelText: 'Option ${option.key + 1}',
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: question.options.length <= 2
                                          ? null
                                          : () => setSheetState(() {
                                                question.options
                                                    .removeAt(option.key);
                                                if (question.correctIndex ==
                                                    option.key) {
                                                  question.correctIndex = 0;
                                                } else if (question
                                                        .correctIndex >
                                                    option.key) {
                                                  question.correctIndex -= 1;
                                                }
                                              }),
                                      icon: const Icon(Icons.close_rounded),
                                      tooltip: 'Remove option',
                                    ),
                                  ],
                                );
                              }),
                              TextButton.icon(
                                onPressed: () => setSheetState(
                                  () => question.options.add(_OptionDraft()),
                                ),
                                icon: const Icon(Icons.add_rounded),
                                label: const Text('Add option'),
                              ),
                            ],
                          ),
                        );
                      })
                    else
                      ...essayDrafts.asMap().entries.map((entry) {
                        final index = entry.key;
                        final essay = entry.value;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(child: Text('Essay ${index + 1}')),
                                  IconButton(
                                    onPressed: essayDrafts.length == 1
                                        ? null
                                        : () => setSheetState(
                                              () => essayDrafts.removeAt(index),
                                            ),
                                    icon: const Icon(Icons.delete_outline),
                                    tooltip: 'Remove essay',
                                  ),
                                ],
                              ),
                              TextField(
                                controller: essay.prompt,
                                minLines: 2,
                                maxLines: 4,
                                decoration: const InputDecoration(
                                  labelText: 'Essay prompt',
                                ),
                              ),
                              TextField(
                                controller: essay.points,
                                keyboardType: TextInputType.number,
                                decoration:
                                    const InputDecoration(labelText: 'Points'),
                              ),
                            ],
                          ),
                        );
                      }),
                    if (type == 'MultipleChoice')
                      TextButton.icon(
                        onPressed: () => setSheetState(
                          () => questionDrafts.add(_QuestionDraft()),
                        ),
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('Add question'),
                      )
                    else
                      TextButton.icon(
                        onPressed: () => setSheetState(
                          () => essayDrafts.add(_EssayDraft()),
                        ),
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('Add essay'),
                      ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: save,
                        child: Text(homework == null ? 'Create' : 'Save'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    },
  );
}

Future<_HomeworkSubmitPayload?> _showHomeworkSubmitSheet(
  BuildContext context,
  HomeworkModel homework,
) async {
  final selected = <int, int>{};
  final essayControllers = {
    for (final essay in homework.essays) essay.essayId: TextEditingController(),
  };

  return showModalBottomSheet<_HomeworkSubmitPayload>(
    context: context,
    isScrollControlled: true,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setSheetState) {
          void submit() {
            if (homework.isMultipleChoice &&
                selected.length != homework.questions.length) {
              return;
            }

            Navigator.pop(
              context,
              _HomeworkSubmitPayload(
                multipleChoiceAnswers: homework.isMultipleChoice
                    ? selected.entries.map((entry) {
                        return {
                          'multipleChoiceQuestionId': entry.key,
                          'questionOptionId': entry.value,
                        };
                      }).toList()
                    : [],
                essayAnswers: homework.isEssay
                    ? essayControllers.entries.map((entry) {
                        return {
                          'essayId': entry.key,
                          'answerText': entry.value.text.trim(),
                        };
                      }).toList()
                    : [],
              ),
            );
          }

          return SafeArea(
            child: Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      homework.title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 12),
                    if (homework.isMultipleChoice)
                      ...homework.questions.map((question) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                question.questionText,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyLarge
                                    ?.copyWith(fontWeight: FontWeight.w600),
                              ),
                              ...question.options.map((option) {
                                final isSelected = selected[
                                        question.multipleChoiceQuestionId] ==
                                    option.questionOptionId;
                                return ListTile(
                                  onTap: () {
                                    setSheetState(() {
                                      selected[question
                                              .multipleChoiceQuestionId] =
                                          option.questionOptionId;
                                    });
                                  },
                                  leading: Icon(
                                    isSelected
                                        ? Icons.radio_button_checked_rounded
                                        : Icons.radio_button_unchecked_rounded,
                                  ),
                                  title: Text(option.content),
                                  contentPadding: EdgeInsets.zero,
                                );
                              }),
                            ],
                          ),
                        );
                      })
                    else
                      ...homework.essays.map((essay) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: TextField(
                            controller: essayControllers[essay.essayId],
                            minLines: 4,
                            maxLines: 8,
                            decoration: InputDecoration(
                              labelText: essay.questionText,
                              alignLabelWithHint: true,
                            ),
                          ),
                        );
                      }),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: submit,
                        child: const Text('Submit'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    },
  );
}

Future<_EssayGradePayload?> _showEssayGradeSheet(
  BuildContext context, {
  required HomeworkModel homework,
  required HomeworkSubmissionModel submission,
}) async {
  final scoreControllers = {
    for (final answer in submission.essayAnswers)
      answer.essayAnswerId:
          TextEditingController(text: answer.score == 0 ? '' : answer.score.g),
  };
  final feedbackControllers = {
    for (final answer in submission.essayAnswers)
      answer.essayAnswerId: TextEditingController(text: answer.feedback ?? ''),
  };
  final overallFeedback =
      TextEditingController(text: submission.feedback ?? '');

  return showModalBottomSheet<_EssayGradePayload>(
    context: context,
    isScrollControlled: true,
    builder: (context) {
      return SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Grade ${submission.studentName}',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 12),
                ...submission.essayAnswers.map((answer) {
                  final prompt = homework.essays
                      .firstWhere(
                        (essay) => essay.essayId == answer.essayId,
                        orElse: () => HomeworkEssayModel(
                          essayId: answer.essayId,
                          questionText: 'Essay',
                          points: submission.maxScore,
                        ),
                      )
                      .questionText;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(prompt,
                            style: Theme.of(context)
                                .textTheme
                                .bodyLarge
                                ?.copyWith(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        Text(answer.answerText),
                        TextField(
                          controller: scoreControllers[answer.essayAnswerId],
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Score'),
                        ),
                        TextField(
                          controller: feedbackControllers[answer.essayAnswerId],
                          decoration:
                              const InputDecoration(labelText: 'Feedback'),
                        ),
                      ],
                    ),
                  );
                }),
                TextField(
                  controller: overallFeedback,
                  decoration:
                      const InputDecoration(labelText: 'Overall feedback'),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () {
                      Navigator.pop(
                        context,
                        _EssayGradePayload(
                          essayGrades: submission.essayAnswers.map((answer) {
                            return {
                              'essayAnswerId': answer.essayAnswerId,
                              'score': double.tryParse(
                                    scoreControllers[answer.essayAnswerId]
                                            ?.text
                                            .trim() ??
                                        '',
                                  ) ??
                                  0,
                              'feedback':
                                  feedbackControllers[answer.essayAnswerId]
                                      ?.text
                                      .trim(),
                            };
                          }).toList(),
                          feedback: overallFeedback.text.trim(),
                        ),
                      );
                    },
                    child: const Text('Save grade'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

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
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
  final bool isTutor;
  final bool loading;
  final Future<void> Function(String link) onOpenMeeting;
  final Future<void> Function() onSave;

  const _MeetingLinkCard({
    required this.controller,
    required this.detail,
    required this.isTutor,
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
                if (isTutor) ...[
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
                ] else if (!hasMeetingLink)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'No meeting link yet',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colors.onSurface.withValues(alpha: 0.55),
                      ),
                    ),
                  ),
                Row(
                  children: [
                    if (isTutor) ...[
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: loading ? null : onSave,
                          icon: loading
                              ? const SizedBox(
                                  width: 15,
                                  height: 15,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white),
                                )
                              : const Icon(Icons.save_outlined, size: 17),
                          label: Text(loading ? 'Saving...' : 'Save link'),
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
                    ],
                    Expanded(
                      child: OutlinedButton.icon(
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

    final lessonCompleted = student.lessonStatus.toLowerCase() == 'completed';
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
                        border: Border.all(color: attBorder, width: 0.5),
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  border: Border.all(color: colors.outlineVariant, width: 0.5),
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
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
              color: colors.outlineVariant.withValues(alpha: 0.5), width: 0.5),
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
              color: colors.outlineVariant.withValues(alpha: 0.5), width: 0.5),
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
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
