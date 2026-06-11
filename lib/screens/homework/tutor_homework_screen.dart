import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/mvp_models.dart';
import '../../providers/app_data_provider.dart';
import '../../widgets/error_banner.dart';

class TutorHomeworkScreen extends StatefulWidget {
  final int? initialLessonId;

  const TutorHomeworkScreen({
    super.key,
    this.initialLessonId,
  });

  @override
  State<TutorHomeworkScreen> createState() => _TutorHomeworkScreenState();
}

class _TutorHomeworkScreenState extends State<TutorHomeworkScreen> {
  static const int _pageSize = 8;

  int? selectedCourseId;
  int page = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final data = context.read<AppDataProvider>();
      await data.loadHomeworkDashboard();
      if (!mounted) return;
      final courseId = _selectedOrDefaultCourseId(data.lessons);
      if (courseId == null) return;
      setState(() => selectedCourseId = courseId);
      await data.loadHomeworkCourse(courseId);
    });
  }

  Future<void> _reload() async {
    final data = context.read<AppDataProvider>();
    await data.loadHomeworkDashboard(force: true);
    if (!mounted) return;
    final courseId = _selectedOrDefaultCourseId(data.lessons);
    if (courseId == null) return;
    setState(() => selectedCourseId = courseId);
    await data.loadHomeworkCourse(courseId, force: true);
  }

  Future<void> _selectCourse(int courseId) async {
    setState(() {
      selectedCourseId = courseId;
      page = 0;
    });
    await context.read<AppDataProvider>().loadHomeworkCourse(courseId);
  }

  Future<void> _viewHomework(_TutorHomeworkItem item) async {
    await context.push(
      '/homework/${item.lesson.lessonId}/${item.homework.homeworkId}',
    );
  }

  Future<void> _createHomework() async {
    final data = context.read<AppDataProvider>();
    final course = _selectedCourse(_courseGroups(data.lessons));
    if (course == null) {
      _showSnack('No lesson is available for homework yet.');
      return;
    }

    final targetLesson = await _showLessonPicker(context, course.lessons);
    if (targetLesson == null || !mounted) return;
    if (_hasLessonEnded(targetLesson)) {
      _showSnack('Homework cannot be added to an ended lesson');
      return;
    }

    final body = await _showTutorHomeworkEditor(context);
    if (body == null || !mounted) return;

    try {
      await context.read<AppDataProvider>().createHomework(
            lessonId: targetLesson.lessonId,
            body: body,
          );
      if (!mounted) return;
      setState(() => selectedCourseId = targetLesson.availabilityId);
      _showSnack('Homework created');
    } catch (_) {}
  }

  Future<void> _editHomework(_TutorHomeworkItem item) async {
    if (item.homework.submissions.isNotEmpty) {
      _showSnack('Homework cannot be edited after a submission is received');
      return;
    }

    final body = await _showTutorHomeworkEditor(
      context,
      homework: item.homework,
    );
    if (body == null || !mounted) return;

    try {
      await context.read<AppDataProvider>().updateHomework(
            lessonId: item.lesson.lessonId,
            homeworkId: item.homework.homeworkId,
            body: body,
          );
      if (!mounted) return;
      _showSnack('Homework updated');
    } catch (_) {}
  }

  Future<void> _deleteHomework(_TutorHomeworkItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete homework?'),
        content: Text('Delete "${item.homework.title}" and its submissions?'),
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
            lessonId: item.lesson.lessonId,
            homeworkId: item.homework.homeworkId,
          );
      if (!mounted) return;
      _showSnack('Homework deleted');
    } catch (_) {}
  }

  Future<void> _gradeSubmission({
    required _TutorHomeworkItem item,
    required HomeworkSubmissionModel submission,
  }) async {
    final payload = await _showEssayGradeSheet(
      context,
      homework: item.homework,
      submission: submission,
    );
    if (payload == null || !mounted) return;

    try {
      await context.read<AppDataProvider>().gradeEssaySubmission(
            lessonId: item.lesson.lessonId,
            homeworkId: item.homework.homeworkId,
            submissionId: submission.submissionId,
            essayGrades: payload.essayGrades,
            feedback: payload.feedback,
          );
      if (!mounted) return;
      _showSnack('Submission graded');
    } catch (_) {}
  }

  int? _selectedOrDefaultCourseId(List<LessonModel> lessons) {
    final courses = _courseGroups(lessons);
    if (courses.isEmpty) return null;

    final initialLessonId = widget.initialLessonId;
    if (selectedCourseId == null && initialLessonId != null) {
      for (final course in courses) {
        if (course.lessons
            .any((lesson) => lesson.lessonId == initialLessonId)) {
          return course.courseId;
        }
      }
    }

    if (selectedCourseId != null &&
        courses.any((course) => course.courseId == selectedCourseId)) {
      return selectedCourseId;
    }

    return courses.first.courseId;
  }

  _CourseGroup? _selectedCourse(List<_CourseGroup> courses) {
    if (courses.isEmpty) return null;
    final courseId = selectedCourseId;
    if (courseId == null) return courses.first;
    for (final course in courses) {
      if (course.courseId == courseId) return course;
    }
    return courses.first;
  }

  List<_TutorHomeworkItem> _homeworkItems(
    AppDataProvider data,
    List<LessonModel> lessons,
  ) {
    final lessonById = {
      for (final lesson in data.lessons) lesson.lessonId: lesson,
    };
    final byHomeworkId = <int, _TutorHomeworkItem>{};

    for (final lesson in lessons) {
      for (final homework in data.lessonHomeworks[lesson.lessonId] ?? []) {
        final assignedLesson =
            homework.lessonId == null ? null : lessonById[homework.lessonId];
        final item = _TutorHomeworkItem(
          lesson: assignedLesson ?? lesson,
          homework: homework,
        );
        final existing = byHomeworkId[homework.homeworkId];
        if (existing == null ||
            existing.homework.lessonId != existing.lesson.lessonId) {
          byHomeworkId[homework.homeworkId] = item;
        }
      }
    }

    final items = byHomeworkId.values.toList()
      ..sort((a, b) {
        return b.homework.uploadedAt.compareTo(a.homework.uploadedAt);
      });
    return items;
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
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final lessons = [...data.lessons]
      ..sort((a, b) => a.scheduleTime.compareTo(b.scheduleTime));
    final courses = _courseGroups(lessons);
    final selectedCourse = _selectedCourse(courses);
    final courseLessons = selectedCourse?.lessons ?? <LessonModel>[];
    final items = _homeworkItems(data, courseLessons);
    final effectivePage = _effectivePage(items.length);
    final pageItems = _pageItems(items, effectivePage);
    final itemsByLesson = _itemsByLesson(pageItems);

    return Scaffold(
      backgroundColor: colors.surfaceContainerLowest,
      appBar: AppBar(
        backgroundColor: colors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        titleSpacing: 20,
        title: Text(
          'Homework',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton.outlined(
            onPressed: data.loading ? null : _reload,
            tooltip: 'Refresh',
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
          const SizedBox(width: 8),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilledButton.icon(
              onPressed: data.loading ? null : _createHomework,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Add'),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(0.5),
          child: Divider(
            height: 0.5,
            thickness: 0.5,
            color: colors.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _reload,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            ErrorBanner(data.error),
            _TutorHomeworkSummary(
              items: items,
              lessonCount: courseLessons.length,
            ),
            const SizedBox(height: 12),
            _CourseFilter(
              courses: courses,
              selectedCourseId: selectedCourse?.courseId,
              onChanged: _selectCourse,
            ),
            const SizedBox(height: 12),
            if (data.loading && items.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 48),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (!data.loading && lessons.isEmpty)
              const _EmptyHomeworkState(
                icon: Icons.school_outlined,
                text: 'No lessons are available for homework yet.',
              )
            else if (!data.loading && items.isEmpty)
              const _EmptyHomeworkState(
                icon: Icons.assignment_outlined,
                text: 'No homework in this course yet.',
              )
            else
              ...itemsByLesson.entries.toList().asMap().entries.map(
                    (entry) => _TutorLessonHomeworkSection(
                      lesson: entry.value.key,
                      items: entry.value.value,
                      loading: data.loading,
                      initiallyExpanded: entry.key == 0,
                      onView: _viewHomework,
                      onEdit: _editHomework,
                      onDelete: _deleteHomework,
                      onGrade: (item, submission) => _gradeSubmission(
                        item: item,
                        submission: submission,
                      ),
                    ),
                  ),
            if (items.isNotEmpty)
              _PaginationControls(
                page: effectivePage,
                pageSize: _pageSize,
                totalItems: items.length,
                onChanged: (value) => setState(() => page = value),
              ),
          ],
        ),
      ),
    );
  }

  int _effectivePage(int totalItems) {
    if (totalItems == 0) return 0;
    final lastPage = ((totalItems - 1) / _pageSize).floor();
    return page.clamp(0, lastPage).toInt();
  }

  List<_TutorHomeworkItem> _pageItems(
    List<_TutorHomeworkItem> items,
    int page,
  ) {
    final start = page * _pageSize;
    if (start >= items.length) return const [];
    final end = (start + _pageSize).clamp(0, items.length);
    return items.sublist(start, end);
  }

  Map<LessonModel, List<_TutorHomeworkItem>> _itemsByLesson(
    List<_TutorHomeworkItem> items,
  ) {
    final grouped = <LessonModel, List<_TutorHomeworkItem>>{};
    for (final item in items) {
      grouped.putIfAbsent(item.lesson, () => []).add(item);
    }
    return grouped;
  }
}

class _TutorHomeworkSummary extends StatelessWidget {
  final List<_TutorHomeworkItem> items;
  final int lessonCount;

  const _TutorHomeworkSummary({
    required this.items,
    required this.lessonCount,
  });

  @override
  Widget build(BuildContext context) {
    final toGrade = items
        .expand((item) => item.homework.submissions.where(
              (submission) => item.homework.isEssay && !submission.isGraded,
            ))
        .length;
    final submitted = items.fold<int>(
      0,
      (total, item) => total + item.homework.submissions.length,
    );

    return _MetricPanel(
      metrics: [
        _MetricData('Lessons', '$lessonCount', Icons.school_outlined),
        _MetricData('Assigned', '${items.length}', Icons.assignment_outlined),
        _MetricData('Submitted', '$submitted', Icons.inbox_outlined),
        _MetricData('To grade', '$toGrade', Icons.rate_review_outlined),
      ],
    );
  }
}

class _CourseFilter extends StatelessWidget {
  final List<_CourseGroup> courses;
  final int? selectedCourseId;
  final ValueChanged<int> onChanged;

  const _CourseFilter({
    required this.courses,
    required this.selectedCourseId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (courses.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final selectedValue = courses.any(
      (course) => course.courseId == selectedCourseId,
    )
        ? selectedCourseId
        : courses.first.courseId;

    return DropdownButtonFormField<int>(
      key: ValueKey(selectedValue),
      initialValue: selectedValue,
      isExpanded: true,
      menuMaxHeight: 360,
      decoration: InputDecoration(
        labelText: 'Class',
        prefixIcon: const Icon(Icons.school_outlined),
        filled: true,
        fillColor: colors.surface,
        contentPadding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: colors.outlineVariant.withValues(alpha: 0.65),
            width: 0.5,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: colors.outlineVariant.withValues(alpha: 0.65),
            width: 0.5,
          ),
        ),
      ),
      selectedItemBuilder: (context) {
        return courses.map((course) {
          return Align(
            alignment: Alignment.centerLeft,
            child: Text(
              course.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          );
        }).toList();
      },
      items: courses.map((course) {
        return DropdownMenuItem<int>(
          value: course.courseId,
          child: _CourseMenuItem(course: course),
        );
      }).toList(),
      onChanged: (value) {
        if (value != null && value != selectedCourseId) {
          onChanged(value);
        }
      },
    );
  }
}

class _CourseMenuItem extends StatelessWidget {
  final _CourseGroup course;

  const _CourseMenuItem({required this.course});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Row(
      children: [
        Icon(
          Icons.class_outlined,
          size: 20,
          color: colors.primary,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                course.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '${course.lessons.length} lesson${course.lessons.length == 1 ? '' : 's'}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
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

class _TutorLessonHomeworkSection extends StatelessWidget {
  final LessonModel lesson;
  final List<_TutorHomeworkItem> items;
  final bool loading;
  final bool initiallyExpanded;
  final ValueChanged<_TutorHomeworkItem> onView;
  final ValueChanged<_TutorHomeworkItem> onEdit;
  final ValueChanged<_TutorHomeworkItem> onDelete;
  final void Function(
    _TutorHomeworkItem item,
    HomeworkSubmissionModel submission,
  ) onGrade;

  const _TutorLessonHomeworkSection({
    required this.lesson,
    required this.items,
    required this.loading,
    required this.initiallyExpanded,
    required this.onView,
    required this.onEdit,
    required this.onDelete,
    required this.onGrade,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final start = lesson.scheduleTime.toLocal();
    final end = start.add(Duration(minutes: lesson.duration));
    final ended = _hasLessonEnded(lesson);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          key: PageStorageKey('tutor-homework-lesson-${lesson.lessonId}'),
          initiallyExpanded: initiallyExpanded,
          tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
          childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
          backgroundColor: colors.surface,
          collapsedBackgroundColor: colors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(
              color: colors.outlineVariant.withValues(alpha: 0.5),
              width: 0.5,
            ),
          ),
          collapsedShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(
              color: colors.outlineVariant.withValues(alpha: 0.5),
              width: 0.5,
            ),
          ),
          leading: Icon(
            Icons.event_note_outlined,
            size: 20,
            color: colors.primary,
          ),
          title: Text(
            _studentName(lesson),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          subtitle: Text(
            '${DateFormat('EEEE, dd/MM/yyyy HH:mm').format(start)} - '
            '${DateFormat('HH:mm').format(end)} (${lesson.duration} min)',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (ended) ...[
                _EndedBadge(),
                const SizedBox(width: 6),
              ],
              _SectionCountBadge(count: items.length),
              const SizedBox(width: 4),
              const Icon(Icons.expand_more_rounded),
            ],
          ),
          children: items.map(
            (item) {
              return Padding(
                padding: const EdgeInsets.only(top: 10),
                child: _TutorHomeworkCard(
                  item: item,
                  loading: loading,
                  onView: () => onView(item),
                  onEdit: () => onEdit(item),
                  onDelete: () => onDelete(item),
                  onGrade: (submission) => onGrade(item, submission),
                ),
              );
            },
          ).toList(),
        ),
      ),
    );
  }
}

class _EndedBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        'Ended',
        style: theme.textTheme.labelSmall?.copyWith(
          color: colors.onSurface.withValues(alpha: 0.6),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _SectionCountBadge extends StatelessWidget {
  final int count;

  const _SectionCountBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      constraints: const BoxConstraints(minWidth: 30),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colors.primaryContainer.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        '$count',
        textAlign: TextAlign.center,
        style: theme.textTheme.labelMedium?.copyWith(
          color: colors.onPrimaryContainer,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _TutorHomeworkCard extends StatelessWidget {
  final _TutorHomeworkItem item;
  final bool loading;
  final VoidCallback onView;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final ValueChanged<HomeworkSubmissionModel> onGrade;

  const _TutorHomeworkCard({
    required this.item,
    required this.loading,
    required this.onView,
    required this.onEdit,
    required this.onDelete,
    required this.onGrade,
  });

  @override
  Widget build(BuildContext context) {
    final homework = item.homework;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final hasSubmissions = homework.submissions.isNotEmpty;
    final toGrade = homework.submissions
        .where((submission) => homework.isEssay && !submission.isGraded)
        .length;
    final typeLabel = homework.isMultipleChoice ? 'Multiple choice' : 'Essay';

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: toGrade > 0
              ? const Color(0xFFFAC775)
              : colors.outlineVariant.withValues(alpha: 0.5),
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
              _TypeIcon(isEssay: homework.isEssay),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      homework.title,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '$typeLabel - ${homework.totalPoints.g} pts - ${_subjectName(item.lesson)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurface.withValues(alpha: 0.55),
                      ),
                    ),
                  ],
                ),
              ),
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
                      hasSubmissions ? 'Edit locked after submission' : 'Edit',
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Text('Delete'),
                  ),
                ],
              ),
            ],
          ),
          if ((homework.description ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              homework.description!.trim(),
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.45),
            ),
          ],
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _InfoChip(
                icon: Icons.event_outlined,
                label:
                    'Due ${DateFormat('dd/MM/yyyy HH:mm').format(homework.dueDate.toLocal())}',
              ),
              _InfoChip(
                icon: Icons.people_outline,
                label: '${homework.submissions.length} submissions',
              ),
              if (toGrade > 0)
                _InfoChip(
                  icon: Icons.warning_amber_rounded,
                  label: '$toGrade to grade',
                  warning: true,
                ),
            ],
          ),
          const SizedBox(height: 12),
          _QuestionPreview(homework: homework),
          const SizedBox(height: 12),
          _SubmissionList(
            homework: homework,
            loading: loading,
            onGrade: onGrade,
          ),
        ],
      ),
    );
  }
}

class _QuestionPreview extends StatelessWidget {
  final HomeworkModel homework;

  const _QuestionPreview({required this.homework});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final count =
        homework.isEssay ? homework.essays.length : homework.questions.length;
    final firstText = homework.isEssay
        ? (homework.essays.isEmpty
            ? 'No essay prompts'
            : homework.essays.first.questionText)
        : (homework.questions.isEmpty
            ? 'No questions'
            : homework.questions.first.questionText);

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
            '$count ${homework.isEssay ? 'essay prompts' : 'questions'}',
            style: theme.textTheme.labelMedium?.copyWith(
              color: colors.onSurface.withValues(alpha: 0.55),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            firstText,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _SubmissionList extends StatelessWidget {
  final HomeworkModel homework;
  final bool loading;
  final ValueChanged<HomeworkSubmissionModel> onGrade;

  const _SubmissionList({
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Student submissions',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        ...homework.submissions.map((submission) {
          final needsGrade = homework.isEssay && !submission.isGraded;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: colors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: colors.outlineVariant.withValues(alpha: 0.45),
                  width: 0.5,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          submission.studentName,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${submission.totalScore.g}/${submission.maxScore.g} pts - '
                          'Submitted ${DateFormat('dd/MM HH:mm').format(submission.submittedAt.toLocal())}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colors.onSurface.withValues(alpha: 0.55),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (needsGrade)
                    FilledButton.tonalIcon(
                      onPressed: loading ? null : () => onGrade(submission),
                      icon: const Icon(Icons.rate_review_outlined, size: 16),
                      label: const Text('Grade'),
                    )
                  else
                    _StatusPill(
                      label: submission.isGraded ? 'Graded' : 'Auto scored',
                      good: submission.isGraded || homework.isMultipleChoice,
                    ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}

class _MetricPanel extends StatelessWidget {
  final List<_MetricData> metrics;

  const _MetricPanel({required this.metrics});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

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
      child: Row(
        children: metrics
            .map(
              (metric) => Expanded(child: _MetricTile(metric: metric)),
            )
            .toList(),
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  final _MetricData metric;

  const _MetricTile({required this.metric});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Column(
      children: [
        Icon(metric.icon, size: 19, color: colors.primary),
        const SizedBox(height: 5),
        Text(
          metric.value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          metric.label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.labelMedium?.copyWith(
            color: colors.onSurface.withValues(alpha: 0.55),
          ),
        ),
      ],
    );
  }
}

class _TypeIcon extends StatelessWidget {
  final bool isEssay;

  const _TypeIcon({required this.isEssay});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: isEssay ? const Color(0xFFF1EAF8) : const Color(0xFFE6F1FB),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(
        isEssay ? Icons.edit_note_rounded : Icons.checklist_rounded,
        size: 21,
        color: isEssay ? const Color(0xFF735099) : const Color(0xFF185FA5),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool warning;

  const _InfoChip({
    required this.icon,
    required this.label,
    this.warning = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final bg =
        warning ? const Color(0xFFFAEEDA) : colors.surfaceContainerHighest;
    final fg = warning ? const Color(0xFF854F0B) : colors.onSurfaceVariant;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: fg),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: fg,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String label;
  final bool good;

  const _StatusPill({
    required this.label,
    required this.good,
  });

  @override
  Widget build(BuildContext context) {
    final bg = good ? const Color(0xFFEAF3DE) : const Color(0xFFFAEEDA);
    final fg = good ? const Color(0xFF3B6D11) : const Color(0xFF854F0B);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: fg,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _EmptyHomeworkState extends StatelessWidget {
  final IconData icon;
  final String text;

  const _EmptyHomeworkState({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          Icon(icon, size: 42, color: colors.onSurface.withValues(alpha: 0.3)),
          const SizedBox(height: 12),
          Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(color: colors.onSurface.withValues(alpha: 0.55)),
          ),
        ],
      ),
    );
  }
}

class _PaginationControls extends StatelessWidget {
  final int page;
  final int pageSize;
  final int totalItems;
  final ValueChanged<int> onChanged;

  const _PaginationControls({
    required this.page,
    required this.pageSize,
    required this.totalItems,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final totalPages = ((totalItems - 1) / pageSize).floor() + 1;
    if (totalPages <= 1) return const SizedBox.shrink();

    final start = page * pageSize + 1;
    final end = (start + pageSize - 1).clamp(1, totalItems);

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '$start-$end of $totalItems',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.onSurface.withValues(alpha: 0.55),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          IconButton.outlined(
            onPressed: page == 0 ? null : () => onChanged(page - 1),
            icon: const Icon(Icons.chevron_left_rounded),
            tooltip: 'Previous page',
          ),
          const SizedBox(width: 8),
          Text(
            '${page + 1}/$totalPages',
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 8),
          IconButton.outlined(
            onPressed:
                page >= totalPages - 1 ? null : () => onChanged(page + 1),
            icon: const Icon(Icons.chevron_right_rounded),
            tooltip: 'Next page',
          ),
        ],
      ),
    );
  }
}

class _TutorHomeworkItem {
  final LessonModel lesson;
  final HomeworkModel homework;

  const _TutorHomeworkItem({
    required this.lesson,
    required this.homework,
  });
}

class _CourseGroup {
  final int courseId;
  final String label;
  final List<LessonModel> lessons;

  const _CourseGroup({
    required this.courseId,
    required this.label,
    required this.lessons,
  });
}

class _MetricData {
  final String label;
  final String value;
  final IconData icon;

  const _MetricData(this.label, this.value, this.icon);
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
        options = options ?? [_OptionDraft(), _OptionDraft()];
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

class _EssayGradePayload {
  final List<Map<String, dynamic>> essayGrades;
  final String? feedback;

  const _EssayGradePayload({
    required this.essayGrades,
    required this.feedback,
  });
}

Future<LessonModel?> _showLessonPicker(
  BuildContext context,
  List<LessonModel> lessons,
) {
  return showModalBottomSheet<LessonModel>(
    context: context,
    builder: (context) {
      return SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          children: [
            Text(
              'Choose lesson',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            ...lessons.map((lesson) {
              final ended = _hasLessonEnded(lesson);
              final start = lesson.scheduleTime.toLocal();
              final end = start.add(Duration(minutes: lesson.duration));

              return ListTile(
                contentPadding: EdgeInsets.zero,
                enabled: !ended,
                leading: Icon(
                  ended ? Icons.lock_clock_outlined : Icons.school_outlined,
                ),
                title: Text(_studentName(lesson)),
                subtitle: Text(
                  '${DateFormat('dd/MM/yyyy HH:mm').format(start)} - '
                  '${DateFormat('HH:mm').format(end)}'
                  ' (${lesson.duration} min)'
                  '${ended ? ' - ended' : ''}',
                ),
                trailing:
                    ended ? const Icon(Icons.block_outlined, size: 18) : null,
                onTap: ended ? null : () => Navigator.pop(context, lesson),
              );
            }),
          ],
        ),
      );
    },
  );
}

Future<Map<String, dynamic>?> _showTutorHomeworkEditor(
  BuildContext context, {
  HomeworkModel? homework,
}) {
  final title = TextEditingController(text: homework?.title ?? '');
  final description = TextEditingController(text: homework?.description ?? '');
  var type = homework?.type == 'Essay' ? 'Essay' : 'MultipleChoice';
  var dueDate = homework?.dueDate.toLocal() ??
      DateTime.now().add(const Duration(days: 7));
  final essayDrafts = homework?.essays.isNotEmpty == true
      ? homework!.essays
          .map((essay) => _EssayDraft(
                question: essay.questionText,
                pointValue: essay.points.g,
              ))
          .toList()
      : [_EssayDraft()];
  final questionDrafts = homework?.questions.isNotEmpty == true
      ? homework!.questions.map((question) {
          final correctIndex =
              question.options.indexWhere((option) => option.isCorrect == true);
          return _QuestionDraft(
            question: question.questionText,
            pointValue: question.point.g,
            options: question.options
                .map((option) => _OptionDraft(text: option.content))
                .toList(),
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
          Future<void> pickDate() async {
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

          Future<void> pickTime() async {
            final picked = await showTimePicker(
              context: context,
              initialTime: TimeOfDay.fromDateTime(dueDate),
            );
            if (picked == null) return;
            setSheetState(() {
              dueDate = DateTime(
                dueDate.year,
                dueDate.month,
                dueDate.day,
                picked.hour,
                picked.minute,
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
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: title,
                      decoration: const InputDecoration(labelText: 'Title'),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: description,
                      minLines: 2,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        alignLabelWithHint: true,
                      ),
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
                      onChanged: homework == null
                          ? (value) {
                              if (value == null) return;
                              setSheetState(() => type = value);
                            }
                          : null,
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        OutlinedButton.icon(
                          onPressed: pickDate,
                          icon: const Icon(Icons.event_outlined, size: 18),
                          label: Text(DateFormat('dd/MM/yyyy').format(dueDate)),
                        ),
                        OutlinedButton.icon(
                          onPressed: pickTime,
                          icon: const Icon(Icons.schedule_outlined, size: 18),
                          label: Text(DateFormat('HH:mm').format(dueDate)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (type == 'MultipleChoice')
                      _QuestionDraftList(
                        questions: questionDrafts,
                        onChanged: setSheetState,
                      )
                    else
                      _EssayDraftList(
                        essays: essayDrafts,
                        onChanged: setSheetState,
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

class _QuestionDraftList extends StatelessWidget {
  final List<_QuestionDraft> questions;
  final void Function(void Function()) onChanged;

  const _QuestionDraftList({
    required this.questions,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ...questions.asMap().entries.map((entry) {
          final index = entry.key;
          final question = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(
                  color: Theme.of(context).colorScheme.outlineVariant,
                  width: 0.5,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text('Question ${index + 1}')),
                      IconButton(
                        onPressed: questions.length == 1
                            ? null
                            : () => onChanged(() => questions.removeAt(index)),
                        icon: const Icon(Icons.delete_outline),
                        tooltip: 'Remove question',
                      ),
                    ],
                  ),
                  TextField(
                    controller: question.text,
                    decoration:
                        const InputDecoration(labelText: 'Question text'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: question.points,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Points'),
                  ),
                  const SizedBox(height: 8),
                  ...question.options.asMap().entries.map((option) {
                    return Row(
                      children: [
                        Checkbox(
                          value: question.correctIndex == option.key,
                          onChanged: (_) => onChanged(
                            () => question.correctIndex = option.key,
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
                              : () => onChanged(() {
                                    question.options.removeAt(option.key);
                                    if (question.correctIndex == option.key) {
                                      question.correctIndex = 0;
                                    } else if (question.correctIndex >
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
                    onPressed: () => onChanged(
                      () => question.options.add(_OptionDraft()),
                    ),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Add option'),
                  ),
                ],
              ),
            ),
          );
        }),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () => onChanged(() => questions.add(_QuestionDraft())),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add question'),
          ),
        ),
      ],
    );
  }
}

class _EssayDraftList extends StatelessWidget {
  final List<_EssayDraft> essays;
  final void Function(void Function()) onChanged;

  const _EssayDraftList({
    required this.essays,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ...essays.asMap().entries.map((entry) {
          final index = entry.key;
          final essay = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(
                  color: Theme.of(context).colorScheme.outlineVariant,
                  width: 0.5,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(child: Text('Essay ${index + 1}')),
                      IconButton(
                        onPressed: essays.length == 1
                            ? null
                            : () => onChanged(() => essays.removeAt(index)),
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
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: essay.points,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Points'),
                  ),
                ],
              ),
            ),
          );
        }),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () => onChanged(() => essays.add(_EssayDraft())),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add essay'),
          ),
        ),
      ],
    );
  }
}

Future<_EssayGradePayload?> _showEssayGradeSheet(
  BuildContext context, {
  required HomeworkModel homework,
  required HomeworkSubmissionModel submission,
}) {
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
                        fontWeight: FontWeight.w700,
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
                        Text(
                          prompt,
                          style:
                              Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(answer.answerText),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: scoreControllers[answer.essayAnswerId],
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Score'),
                        ),
                        const SizedBox(height: 8),
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

extension _ScoreFormat on double {
  String get g =>
      this == roundToDouble() ? toInt().toString() : toStringAsFixed(1);
}

String _subjectName(LessonModel lesson) {
  final name = lesson.subjectName;
  if (name != null && name.trim().isNotEmpty) return name.trim();
  return 'Subject #${lesson.subjectId ?? '-'}';
}

String _studentName(LessonModel lesson) {
  final name = lesson.studentName;
  if (name != null && name.trim().isNotEmpty) return name.trim();
  return 'Student #${lesson.bookingId}';
}

bool _hasLessonEnded(LessonModel lesson) {
  final end = lesson.scheduleTime.toLocal().add(
        Duration(minutes: lesson.duration),
      );
  return end.isBefore(DateTime.now()) ||
      lesson.status.toLowerCase() == 'completed';
}

String _courseDuration(List<LessonModel> lessons) {
  if (lessons.isEmpty) return '0 lessons';
  final sorted = [...lessons]
    ..sort((a, b) => a.scheduleTime.compareTo(b.scheduleTime));
  final first = sorted.first.scheduleTime.toLocal();
  final last = sorted.last.scheduleTime.toLocal().add(
        Duration(minutes: sorted.last.duration),
      );
  final lessonLabel = lessons.length == 1 ? 'lesson' : 'lessons';
  return '${lessons.length} $lessonLabel, '
      '${DateFormat('dd/MM').format(first)}-${DateFormat('dd/MM').format(last)}';
}

List<_CourseGroup> _courseGroups(List<LessonModel> lessons) {
  final grouped = <int, List<LessonModel>>{};
  for (final lesson in lessons) {
    grouped.putIfAbsent(lesson.availabilityId, () => []).add(lesson);
  }

  final courses = grouped.entries.map((entry) {
    final courseLessons = [...entry.value]
      ..sort((a, b) => a.scheduleTime.compareTo(b.scheduleTime));
    final first = courseLessons.first;
    return _CourseGroup(
      courseId: entry.key,
      label: '${_subjectName(first)} - ${_studentName(first)}'
          ' (${_courseDuration(courseLessons)})',
      lessons: courseLessons,
    );
  }).toList()
    ..sort(
      (a, b) => a.lessons.first.scheduleTime.compareTo(
        b.lessons.first.scheduleTime,
      ),
    );

  return courses;
}
