import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_strings.dart';
import '../../models/mvp_models.dart';
import '../../providers/app_data_provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_ui.dart';
import '../../widgets/error_banner.dart';

class HomeworkTakeScreen extends StatefulWidget {
  final int lessonId;
  final int homeworkId;

  const HomeworkTakeScreen({
    super.key,
    required this.lessonId,
    required this.homeworkId,
  });

  @override
  State<HomeworkTakeScreen> createState() => _HomeworkTakeScreenState();
}

class _HomeworkTakeScreenState extends State<HomeworkTakeScreen> {
  final selectedOptions = <int, int>{};
  final essayControllers = <int, TextEditingController>{};
  int? preparedHomeworkId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _reload();
    });
  }

  @override
  void dispose() {
    for (final controller in essayControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _reload({bool force = false}) {
    return context
        .read<AppDataProvider>()
        .loadLessonHomeworks(widget.lessonId, force: force);
  }

  void _prepare(HomeworkModel homework) {
    if (preparedHomeworkId == homework.homeworkId) return;

    for (final controller in essayControllers.values) {
      controller.dispose();
    }

    selectedOptions.clear();
    essayControllers
      ..clear()
      ..addEntries(
        homework.essays.map(
          (essay) => MapEntry(essay.essayId, TextEditingController()),
        ),
      );
    preparedHomeworkId = homework.homeworkId;
  }

  Future<void> _submit(HomeworkModel homework) async {
    if (homework.isMultipleChoice &&
        selectedOptions.length != homework.questions.length) {
      _showSnack('Please answer every question.');
      return;
    }

    if (homework.isEssay &&
        essayControllers.values
            .any((controller) => controller.text.trim().isEmpty)) {
      _showSnack('Please answer every essay prompt.');
      return;
    }

    try {
      await context.read<AppDataProvider>().submitHomework(
            lessonId: widget.lessonId,
            homeworkId: homework.homeworkId,
            multipleChoiceAnswers: homework.isMultipleChoice
                ? selectedOptions.entries.map((entry) {
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
          );
      if (!mounted) return;
      _showSnack(
          AppStrings.of(context, listen: false).text('Homework submitted'));
    } catch (_) {}
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
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
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final homework = _homework(data);
    final lesson = _lesson(data);
    final canSubmit =
        homework != null && auth.isLearner && homework.mySubmission == null;

    if (homework != null) {
      _prepare(homework);
    }

    return Scaffold(
      backgroundColor: colors.surfaceContainerLowest,
      appBar: AppBar(
        titleSpacing: 8,
        title: Text(
          context.l10n.homework,
          style:
              theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: IconButton.outlined(
              onPressed: data.loading ? null : () => _reload(force: true),
              tooltip: context.l10n.refresh,
              icon: const Icon(Icons.refresh_rounded, size: 20),
              style: IconButton.styleFrom(
                side: BorderSide(color: colors.outlineVariant, width: 0.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                minimumSize: const Size(36, 36),
                padding: EdgeInsets.zero,
              ),
            ),
          ),
        ],
      ),
      body: homework == null
          ? _MissingHomeworkBody(
              loading: data.loading,
              onBack: () => context.pop(),
            )
          : RefreshIndicator(
              onRefresh: () => _reload(force: true),
              child: ListView(
                padding: EdgeInsets.fromLTRB(16, 12, 16, canSubmit ? 112 : 32),
                children: [
                  ErrorBanner(data.error),
                  _HomeworkHeader(homework: homework, lesson: lesson),
                  const SizedBox(height: 24),
                  if (auth.isTutor) ...[
                    AppSectionHeader(
                      icon: Icons.fact_check_rounded,
                      title: context.l10n.text('Assignment details'),
                      subtitle: context.l10n.text(
                        'Review the questions and learner submissions.',
                      ),
                    ),
                    const SizedBox(height: 12),
                    _TutorDetailView(homework: homework)
                  ] else if (homework.mySubmission != null) ...[
                    AppSectionHeader(
                      icon: Icons.workspace_premium_rounded,
                      title: context.l10n.text('Your result'),
                      subtitle: context.l10n.text(
                        'Your score and tutor feedback appear here.',
                      ),
                    ),
                    const SizedBox(height: 12),
                    _ResultView(homework: homework)
                  ] else ...[
                    if (_isOverdue(homework))
                      _InfoBox(
                        icon: Icons.error_outline_rounded,
                        text: context.l10n.text(
                          'This homework is past its due date.',
                        ),
                        warning: true,
                      ),
                    if (_isOverdue(homework)) const SizedBox(height: 20),
                    AppSectionHeader(
                      icon: homework.isEssay
                          ? Icons.edit_note_rounded
                          : Icons.quiz_rounded,
                      title: homework.isEssay
                          ? context.l10n.text('Write your response')
                          : context.l10n.text('Choose your answers'),
                      subtitle: homework.isEssay
                          ? context.l10n
                              .text('Complete every prompt before submitting.')
                          : context.l10n
                              .text('Select one answer for each question.'),
                    ),
                    const SizedBox(height: 12),
                    _QuestionForm(
                      homework: homework,
                      selectedOptions: selectedOptions,
                      essayControllers: essayControllers,
                      onChanged: () => setState(() {}),
                    ),
                  ],
                ],
              ),
            ),
      bottomNavigationBar: canSubmit
          ? SafeArea(
              top: false,
              child: Material(
                color: colors.surface,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
                  child: FilledButton.icon(
                    onPressed: data.loading ? null : () => _submit(homework),
                    icon: data.loading
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: colors.onPrimary,
                            ),
                          )
                        : const Icon(Icons.upload_file_rounded),
                    label: Text(
                      context.l10n
                          .text(data.loading ? 'Submitting...' : 'Submit'),
                    ),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(54),
                      shape: const StadiumBorder(),
                    ),
                  ),
                ),
              ),
            )
          : null,
    );
  }

  HomeworkModel? _homework(AppDataProvider data) {
    for (final homework in data.lessonHomeworks[widget.lessonId] ?? []) {
      if (homework.homeworkId == widget.homeworkId) {
        return homework;
      }
    }
    return null;
  }

  LessonModel? _lesson(AppDataProvider data) {
    for (final lesson in data.lessons) {
      if (lesson.lessonId == widget.lessonId) {
        return lesson;
      }
    }
    return null;
  }
}

class _MissingHomeworkBody extends StatelessWidget {
  final bool loading;
  final VoidCallback onBack;

  const _MissingHomeworkBody({
    required this.loading,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.assignment_late_outlined,
              size: 42,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 12),
            Text(context.l10n.text('Homework not found for this lesson.')),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: onBack,
              child: Text(context.l10n.text('Back')),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeworkHeader extends StatelessWidget {
  final HomeworkModel homework;
  final LessonModel? lesson;

  const _HomeworkHeader({
    required this.homework,
    required this.lesson,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final t = context.l10n;
    final typeLabel = t.text(
      homework.isMultipleChoice ? 'Multiple choice' : 'Essay',
    );
    final overdue = _isOverdue(homework);
    final submission = homework.mySubmission;
    final statusLabel = submission != null
        ? (submission.isGraded ? t.text('Reviewed') : t.text('Submitted'))
        : overdue
            ? t.text('Overdue')
            : t.text('Assigned');
    final statusIcon = submission != null
        ? (submission.isGraded
            ? Icons.workspace_premium_rounded
            : Icons.hourglass_top_rounded)
        : overdue
            ? Icons.warning_amber_rounded
            : Icons.assignment_rounded;

    return AppHeroCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: colors.onPrimary.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  homework.isMultipleChoice
                      ? Icons.quiz_rounded
                      : Icons.edit_note_rounded,
                  color: colors.onPrimary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      homework.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: colors.onPrimary,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _HeroHomeworkChip(
                icon: homework.isMultipleChoice
                    ? Icons.quiz_rounded
                    : Icons.edit_note_rounded,
                label: typeLabel,
              ),
              _HeroHomeworkChip(
                icon: Icons.stars_rounded,
                label: t.points(homework.totalPoints.g),
              ),
              _HeroHomeworkChip(icon: statusIcon, label: statusLabel),
            ],
          ),
          const SizedBox(height: 12),
          _HeroHomeworkDetail(
            icon: Icons.schedule_rounded,
            label: t.dueAt(
              DateFormat('dd MMM, HH:mm').format(homework.dueDate.toLocal()),
            ),
          ),
          if (lesson != null) ...[
            const SizedBox(height: 8),
            _HeroHomeworkDetail(
              icon: Icons.school_rounded,
              label: context.l10n.isVi
                  ? '${_subjectName(lesson!)} với ${lesson!.tutorName}'
                  : '${_subjectName(lesson!)} with ${lesson!.tutorName}',
            ),
          ],
          if ((homework.description ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              homework.description!.trim(),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.onPrimary.withValues(alpha: 0.9),
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _HeroHomeworkChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _HeroHomeworkChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: colors.onPrimary.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: colors.onPrimary),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: colors.onPrimary,
                  fontWeight: FontWeight.w800,
                ),
          ),
        ],
      ),
    );
  }
}

class _HeroHomeworkDetail extends StatelessWidget {
  final IconData icon;
  final String label;

  const _HeroHomeworkDetail({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 17, color: colors.onPrimary.withValues(alpha: 0.9)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colors.onPrimary.withValues(alpha: 0.9),
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
      ],
    );
  }
}

class _QuestionForm extends StatelessWidget {
  final HomeworkModel homework;
  final Map<int, int> selectedOptions;
  final Map<int, TextEditingController> essayControllers;
  final VoidCallback onChanged;

  const _QuestionForm({
    required this.homework,
    required this.selectedOptions,
    required this.essayControllers,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (homework.isEssay) {
      return Column(
        children: homework.essays.map((essay) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _EssayPromptCard(
              essay: essay,
              controller: essayControllers[essay.essayId]!,
            ),
          );
        }).toList(),
      );
    }

    return Column(
      children: homework.questions.asMap().entries.map((entry) {
        final index = entry.key;
        final question = entry.value;

        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _MultipleChoiceQuestionCard(
            index: index,
            question: question,
            selectedOptionId:
                selectedOptions[question.multipleChoiceQuestionId],
            onSelected: (optionId) {
              selectedOptions[question.multipleChoiceQuestionId] = optionId;
              onChanged();
            },
          ),
        );
      }).toList(),
    );
  }
}

class _TutorDetailView extends StatelessWidget {
  final HomeworkModel homework;

  const _TutorDetailView({required this.homework});

  @override
  Widget build(BuildContext context) {
    final submissions = homework.submissions;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (homework.isMultipleChoice)
          ...homework.questions.asMap().entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _TutorQuestionCard(
                index: entry.key,
                question: entry.value,
              ),
            );
          })
        else
          ...homework.essays.asMap().entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _TutorEssayCard(index: entry.key, essay: entry.value),
            );
          }),
        const SizedBox(height: 2),
        _SubmissionSummary(homework: homework, submissions: submissions),
      ],
    );
  }
}

class _TutorQuestionCard extends StatelessWidget {
  final int index;
  final HomeworkQuestionModel question;

  const _TutorQuestionCard({
    required this.index,
    required this.question,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final tokens =
        theme.extension<EduNestThemeTokens>() ?? EduNestThemeTokens.light();

    return AppSurfaceCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Question ${index + 1} - ${question.point.g} pts',
            style: theme.textTheme.labelMedium?.copyWith(
              color: colors.onSurface.withValues(alpha: 0.55),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            question.questionText,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          ...question.options.map((option) {
            final correct = option.isCorrect == true;

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 11,
                ),
                decoration: BoxDecoration(
                  color: correct
                      ? tokens.successColor.withValues(alpha: 0.12)
                      : colors.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color:
                        correct ? tokens.successColor : colors.outlineVariant,
                    width: 0.7,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      correct
                          ? Icons.check_circle_outline_rounded
                          : Icons.circle_outlined,
                      size: 18,
                      color: correct
                          ? tokens.successColor
                          : colors.onSurface.withValues(alpha: 0.45),
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: Text(option.content)),
                    if (correct)
                      Text(
                        context.l10n.text('Correct'),
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: tokens.successColor,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _TutorEssayCard extends StatelessWidget {
  final int index;
  final HomeworkEssayModel essay;

  const _TutorEssayCard({
    required this.index,
    required this.essay,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colors.outlineVariant.withValues(alpha: 0.5),
          width: 0.5,
        ),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Essay ${index + 1} - ${essay.points.g} pts',
            style: theme.textTheme.labelMedium?.copyWith(
              color: colors.onSurface.withValues(alpha: 0.55),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            essay.questionText,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _SubmissionSummary extends StatelessWidget {
  final HomeworkModel homework;
  final List<HomeworkSubmissionModel> submissions;

  const _SubmissionSummary({required this.homework, required this.submissions});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return AppSurfaceCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSectionHeader(
            icon: Icons.inbox_rounded,
            title: context.l10n.text('Submissions'),
            subtitle:
                '${submissions.length} ${context.l10n.text('submissions')}',
          ),
          const SizedBox(height: 8),
          if (submissions.isEmpty)
            Text(
              'No submissions yet',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.onSurface.withValues(alpha: 0.55),
              ),
            )
          else
            ...submissions.map(
              (submission) => _TutorSubmissionTile(
                homework: homework,
                submission: submission,
              ),
            ),
        ],
      ),
    );
  }
}

class _TutorSubmissionTile extends StatelessWidget {
  final HomeworkModel homework;
  final HomeworkSubmissionModel submission;

  const _TutorSubmissionTile(
      {required this.homework, required this.submission});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final t = context.l10n;
    final isEssay = homework.isEssay;

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Container(
        decoration: BoxDecoration(
          color: colors.surfaceContainerHighest.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(16),
        ),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          leading: CircleAvatar(
            radius: 18,
            backgroundColor: colors.primaryContainer,
            foregroundColor: colors.onPrimaryContainer,
            child: Text(
              submission.studentName.trim().isEmpty
                  ? '?'
                  : submission.studentName.trim().substring(0, 1).toUpperCase(),
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          title: Text(
            submission.studentName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          subtitle: Text(
            '${t.submittedAt(DateFormat('dd MMM, HH:mm').format(submission.submittedAt.toLocal()))} · ${submission.totalScore.g}/${submission.maxScore.g}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          children: [
            if (isEssay) ...[
              AppSectionHeader(
                icon: Icons.edit_note_rounded,
                title: t.text('Essay answers'),
              ),
              const SizedBox(height: 10),
              if (submission.essayAnswers.isEmpty)
                Text(
                  t.text('No submissions yet'),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                )
              else
                ...submission.essayAnswers.asMap().entries.map(
                      (entry) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _TutorEssayAnswerCard(
                          homework: homework,
                          index: entry.key,
                          answer: entry.value,
                        ),
                      ),
                    ),
            ] else
              const SizedBox.shrink(),
          ],
        ),
      ),
    );
  }
}

class _TutorEssayAnswerCard extends StatelessWidget {
  final HomeworkModel homework;
  final int index;
  final EssayAnswerModel answer;

  const _TutorEssayAnswerCard({
    required this.homework,
    required this.index,
    required this.answer,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final prompt = _firstWhereOrNull<HomeworkEssayModel>(
      homework.essays,
      (essay) => essay.essayId == answer.essayId,
    )?.questionText;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${context.l10n.text('Essay')} ${index + 1}',
            style: theme.textTheme.labelLarge?.copyWith(
              color: colors.primary,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (prompt != null && prompt.trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              prompt,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          const SizedBox(height: 10),
          Text(
            context.l10n.text('Answer'),
            style: theme.textTheme.labelMedium?.copyWith(
              color: colors.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 3),
          Text(answer.answerText, style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _MultipleChoiceQuestionCard extends StatelessWidget {
  final int index;
  final HomeworkQuestionModel question;
  final int? selectedOptionId;
  final ValueChanged<int> onSelected;

  const _MultipleChoiceQuestionCard({
    required this.index,
    required this.question,
    required this.selectedOptionId,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return AppSurfaceCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppMetaChip(
            icon: Icons.help_outline_rounded,
            label: '${context.l10n.text('Question')} ${index + 1}',
          ),
          const SizedBox(height: 10),
          Text(
            question.questionText,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          ...question.options.map((option) {
            final selected = selectedOptionId == option.questionOptionId;

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                onTap: () => onSelected(option.questionOptionId),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 11,
                  ),
                  decoration: BoxDecoration(
                    color: selected
                        ? colors.primaryContainer.withValues(alpha: 0.55)
                        : colors.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: selected ? colors.primary : colors.outlineVariant,
                      width: selected ? 1.2 : 0.7,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        selected
                            ? Icons.radio_button_checked_rounded
                            : Icons.radio_button_unchecked_rounded,
                        color: selected
                            ? colors.primary
                            : colors.onSurface.withValues(alpha: 0.5),
                      ),
                      const SizedBox(width: 10),
                      Expanded(child: Text(option.content)),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _EssayPromptCard extends StatelessWidget {
  final HomeworkEssayModel essay;
  final TextEditingController controller;

  const _EssayPromptCard({
    required this.essay,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppSurfaceCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppMetaChip(
            icon: Icons.edit_note_rounded,
            label: context.l10n.text('Essay'),
          ),
          const SizedBox(height: 10),
          Text(
            essay.questionText,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: controller,
            minLines: 7,
            maxLines: 12,
            decoration: InputDecoration(
              hintText: context.l10n.text('Write your answer'),
              alignLabelWithHint: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultView extends StatelessWidget {
  final HomeworkModel homework;

  const _ResultView({required this.homework});

  @override
  Widget build(BuildContext context) {
    final submission = homework.mySubmission!;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final tokens =
        theme.extension<EduNestThemeTokens>() ?? EduNestThemeTokens.light();
    final scorePercent = submission.maxScore <= 0
        ? 0.0
        : submission.totalScore / submission.maxScore;
    final scoreColor =
        submission.isGraded ? tokens.successColor : tokens.warningColor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: colors.outlineVariant.withValues(alpha: 0.5),
              width: 0.5,
            ),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: scoreColor.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      submission.isGraded
                          ? Icons.check_circle_outline_rounded
                          : Icons.hourglass_bottom_rounded,
                      color: scoreColor,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          submission.isGraded
                              ? context.l10n.text('Essay result')
                              : context.l10n.text('Essay submitted'),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          submission.isGraded
                              ? '${context.l10n.text('Graded')} ${DateFormat('dd/MM/yyyy HH:mm').format((submission.gradedAt ?? submission.submittedAt).toLocal())}'
                              : context.l10n.text('Waiting for tutor grading'),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colors.onSurface.withValues(alpha: 0.55),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: scoreColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Text(
                      '${submission.totalScore.g}/${submission.maxScore.g}',
                      style: TextStyle(
                        color: scoreColor,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(100),
                child: LinearProgressIndicator(
                  value: scorePercent.clamp(0, 1),
                  minHeight: 8,
                  backgroundColor: colors.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation(scoreColor),
                ),
              ),
              const SizedBox(height: 10),
              _MetaRow(
                icon: Icons.upload_file_outlined,
                label: context.l10n.submittedAt(
                  DateFormat('dd/MM/yyyy HH:mm').format(
                    submission.submittedAt.toLocal(),
                  ),
                ),
              ),
              if ((submission.feedback ?? '').trim().isNotEmpty) ...[
                const SizedBox(height: 12),
                _ResultFeedbackBox(
                  title: context.l10n.text('Tutor feedback'),
                  text: submission.feedback!.trim(),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (homework.isMultipleChoice)
          ...submission.multipleChoiceAnswers.map(
            (answer) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _ChoiceResultCard(homework: homework, answer: answer),
            ),
          )
        else ...[
          Text(
            context.l10n.text('Essay answers'),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          ...submission.essayAnswers.asMap().entries.map(
                (entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _EssayResultCard(
                    index: entry.key,
                    homework: homework,
                    answer: entry.value,
                    isGraded: submission.isGraded,
                  ),
                ),
              ),
        ],
      ],
    );
  }
}

class _ResultFeedbackBox extends StatelessWidget {
  final String title;
  final String text;

  const _ResultFeedbackBox({
    required this.title,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: colors.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            text,
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.45),
          ),
        ],
      ),
    );
  }
}

class _ChoiceResultCard extends StatelessWidget {
  final HomeworkModel homework;
  final MultipleChoiceAnswerModel answer;

  const _ChoiceResultCard({
    required this.homework,
    required this.answer,
  });

  @override
  Widget build(BuildContext context) {
    final question = _firstWhereOrNull<HomeworkQuestionModel>(
      homework.questions,
      (q) => q.multipleChoiceQuestionId == answer.multipleChoiceQuestionId,
    );
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final good = answer.isCorrect;

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: good ? const Color(0xFFC0DD97) : const Color(0xFFF7C1C1),
          width: 0.5,
        ),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question?.questionText ?? context.l10n.text('Question'),
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                good
                    ? Icons.check_circle_outline_rounded
                    : Icons.cancel_outlined,
                color: good ? const Color(0xFF3B6D11) : const Color(0xFFA32D2D),
                size: 18,
              ),
              const SizedBox(width: 7),
              Expanded(child: Text(answer.selectedOption)),
              Text(context.l10n.points(answer.score.g)),
            ],
          ),
        ],
      ),
    );
  }
}

class _EssayResultCard extends StatelessWidget {
  final int index;
  final HomeworkModel homework;
  final EssayAnswerModel answer;
  final bool isGraded;

  const _EssayResultCard({
    required this.index,
    required this.homework,
    required this.answer,
    required this.isGraded,
  });

  @override
  Widget build(BuildContext context) {
    final prompt = _firstWhereOrNull<HomeworkEssayModel>(
      homework.essays,
      (essay) => essay.essayId == answer.essayId,
    )?.questionText;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final maxPoints = _firstWhereOrNull<HomeworkEssayModel>(
      homework.essays,
      (essay) => essay.essayId == answer.essayId,
    )?.points;

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: colors.outlineVariant.withValues(alpha: 0.5),
          width: 0.5,
        ),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1EAF8),
                  borderRadius: BorderRadius.circular(9),
                ),
                alignment: Alignment.center,
                child: Text(
                  '${index + 1}',
                  style: const TextStyle(
                    color: Color(0xFF735099),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      prompt ?? context.l10n.text('Essay'),
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      maxPoints == null
                          ? context.l10n.text('Essay response')
                          : '${context.l10n.points(maxPoints.g)} ${context.l10n.text('possible')}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurface.withValues(alpha: 0.55),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: isGraded
                      ? const Color(0xFFEAF3DE)
                      : const Color(0xFFFAEEDA),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  maxPoints == null
                      ? context.l10n.points(answer.score.g)
                      : '${answer.score.g}/${maxPoints.g}',
                  style: TextStyle(
                    color: isGraded
                        ? const Color(0xFF3B6D11)
                        : const Color(0xFF854F0B),
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.surfaceContainerHighest.withValues(alpha: 0.65),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              answer.answerText,
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
            ),
          ),
          if ((answer.feedback ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            _ResultFeedbackBox(
              title: context.l10n.text('Question feedback'),
              text: answer.feedback!.trim(),
            ),
          ] else if (!isGraded) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(
                  Icons.hourglass_bottom_rounded,
                  size: 17,
                  color: Color(0xFF854F0B),
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    context.l10n.text('Waiting for tutor feedback'),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF854F0B),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoBox extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool warning;

  const _InfoBox({
    required this.icon,
    required this.text,
    this.warning = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final bg = warning ? const Color(0xFFFCEBEB) : colors.surface;
    final fg = warning ? const Color(0xFFA32D2D) : colors.onSurfaceVariant;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: warning
              ? const Color(0xFFF7C1C1)
              : colors.outlineVariant.withValues(alpha: 0.5),
          width: 0.5,
        ),
      ),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Icon(icon, color: fg),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: fg, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MetaRow({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Row(
      children: [
        Icon(icon, size: 17, color: colors.onSurface.withValues(alpha: 0.45)),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: colors.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ),
      ],
    );
  }
}

extension _ScoreFormat on double {
  String get g =>
      this == roundToDouble() ? toInt().toString() : toStringAsFixed(1);
}

bool _isOverdue(HomeworkModel homework) {
  return homework.mySubmission == null &&
      homework.dueDate.toLocal().isBefore(DateTime.now());
}

String _subjectName(LessonModel lesson) {
  final name = lesson.subjectName;
  if (name != null && name.trim().isNotEmpty) return name.trim();
  return 'Subject #${lesson.subjectId ?? '-'}';
}

T? _firstWhereOrNull<T>(Iterable<T> items, bool Function(T item) test) {
  for (final item in items) {
    if (test(item)) return item;
  }
  return null;
}
