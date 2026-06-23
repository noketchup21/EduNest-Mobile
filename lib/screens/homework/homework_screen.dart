import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_strings.dart';
import '../../models/mvp_models.dart';
import '../../providers/app_data_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/app_ui.dart';
import '../../widgets/error_banner.dart';

class HomeworkScreen extends StatefulWidget {
  const HomeworkScreen({super.key});

  @override
  State<HomeworkScreen> createState() => _HomeworkScreenState();
}

class _HomeworkScreenState extends State<HomeworkScreen> {
  static const int _pageSize = 8;

  _HomeworkFilter filter = _HomeworkFilter.all;
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
      filter = _HomeworkFilter.all;
      page = 0;
    });
    await context.read<AppDataProvider>().loadHomeworkCourse(courseId);
  }

  Future<void> _openHomework(_HomeworkItem item) async {
    await context.push(
      '/homework/${item.lesson.lessonId}/${item.homework.homeworkId}',
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = context.watch<AppDataProvider>();
    final auth = context.watch<AuthProvider>();
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final t = context.l10n;
    final courses = _courseGroups(data.lessons);
    final selectedCourse = _selectedCourse(courses);
    final courseLessons = selectedCourse?.lessons ?? <LessonModel>[];
    final allItems = _homeworkItems(data, courseLessons)
      ..sort((a, b) {
        return b.homework.uploadedAt.compareTo(a.homework.uploadedAt);
      });
    final items = _filteredItems(allItems);
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
          t.homework,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: IconButton.outlined(
              onPressed: data.loading ? null : _reload,
              tooltip: t.refresh,
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
            _HomeworkSummary(items: allItems),
            const SizedBox(height: 12),
            _CourseFilterBar(
              courses: courses,
              selectedCourseId: selectedCourse?.courseId,
              onChanged: _selectCourse,
            ),
            const SizedBox(height: 12),
            _HomeworkFilterBar(
              selected: filter,
              onChanged: (value) => setState(() {
                filter = value;
                page = 0;
              }),
              items: allItems,
            ),
            const SizedBox(height: 12),
            if (data.loading && allItems.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 48),
                child: Center(child: CircularProgressIndicator()),
              ),
            if (!data.loading && courses.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: AppEmptyState(
                  icon: Icons.school_outlined,
                  title: t.noCoursesAvailableYet,
                  message: t.text('Choose a course to see its homework.'),
                ),
              )
            else if (!data.loading && items.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: AppEmptyState(
                  icon: Icons.assignment_outlined,
                  title: allItems.isEmpty
                      ? t.text('No homework assigned in this course yet.')
                      : t.text('No homework in this view.'),
                  message: t.text('Try another filter or check back later.'),
                ),
              ),
            ...itemsByLesson.entries.toList().asMap().entries.map(
                  (entry) => _LessonHomeworkSection(
                    lesson: entry.value.key,
                    items: entry.value.value,
                    canSubmit: auth.isLearner,
                    loading: data.loading,
                    initiallyExpanded: entry.key == 0,
                    onOpenHomework: _openHomework,
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

  List<_HomeworkItem> _filteredItems(List<_HomeworkItem> items) {
    return switch (filter) {
      _HomeworkFilter.all => items,
      _HomeworkFilter.todo => items
          .where(
            (item) =>
                item.homework.mySubmission == null &&
                !_isOverdue(item.homework),
          )
          .toList(),
      _HomeworkFilter.dueSoon =>
        items.where((item) => _isDueSoon(item.homework)).toList(),
      _HomeworkFilter.submitted => items
          .where(
            (item) =>
                item.homework.mySubmission != null &&
                item.homework.mySubmission?.isGraded != true,
          )
          .toList(),
      _HomeworkFilter.graded => items
          .where((item) => item.homework.mySubmission?.isGraded == true)
          .toList(),
    };
  }

  int _effectivePage(int totalItems) {
    if (totalItems == 0) return 0;
    final lastPage = ((totalItems - 1) / _pageSize).floor();
    return page.clamp(0, lastPage).toInt();
  }

  List<_HomeworkItem> _pageItems(List<_HomeworkItem> items, int page) {
    final start = page * _pageSize;
    if (start >= items.length) return const [];
    final end = (start + _pageSize).clamp(0, items.length);
    return items.sublist(start, end);
  }

  int? _selectedOrDefaultCourseId(List<LessonModel> lessons) {
    final courses = _courseGroups(lessons);
    if (courses.isEmpty) return null;
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

  List<_HomeworkItem> _homeworkItems(
    AppDataProvider data,
    List<LessonModel> lessons,
  ) {
    final byHomeworkId = <int, _HomeworkItem>{};
    final lessonById = {
      for (final lesson in data.lessons) lesson.lessonId: lesson,
    };

    for (final lesson in lessons) {
      for (final homework in data.lessonHomeworks[lesson.lessonId] ?? []) {
        final assignedLesson =
            homework.lessonId == null ? null : lessonById[homework.lessonId];
        final item = _HomeworkItem(
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

    return byHomeworkId.values.toList();
  }

  Map<LessonModel, List<_HomeworkItem>> _itemsByLesson(
    List<_HomeworkItem> items,
  ) {
    final grouped = <LessonModel, List<_HomeworkItem>>{};
    for (final item in items) {
      grouped.putIfAbsent(item.lesson, () => []).add(item);
    }
    return grouped;
  }
}

enum _HomeworkFilter {
  all,
  todo,
  dueSoon,
  submitted,
  graded,
}

class _CourseFilterBar extends StatelessWidget {
  final List<_CourseGroup> courses;
  final int? selectedCourseId;
  final ValueChanged<int> onChanged;

  const _CourseFilterBar({
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
        labelText: context.l10n.text('Class'),
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
                context.l10n.lessonsN(course.lessons.length),
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

class _HomeworkSummary extends StatelessWidget {
  final List<_HomeworkItem> items;

  const _HomeworkSummary({required this.items});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final pending = items
        .where((item) =>
            item.homework.mySubmission == null &&
            item.homework.dueDate.toLocal().isAfter(DateTime.now()))
        .length;
    final dueSoon = items.where((item) => _isDueSoon(item.homework)).length;
    final graded = items
        .where((item) => item.homework.mySubmission?.isGraded == true)
        .length;

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
      child: Row(
        children: [
          Expanded(
            child: _SummaryMetric(
              label: context.l10n.text('Pending'),
              value: '$pending',
              icon: Icons.assignment_outlined,
            ),
          ),
          Expanded(
            child: _SummaryMetric(
              label: context.l10n.text('Due soon'),
              value: '$dueSoon',
              icon: Icons.warning_amber_rounded,
            ),
          ),
          Expanded(
            child: _SummaryMetric(
              label: context.l10n.text('Graded'),
              value: '$graded',
              icon: Icons.check_circle_outline_rounded,
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeworkFilterBar extends StatelessWidget {
  final _HomeworkFilter selected;
  final ValueChanged<_HomeworkFilter> onChanged;
  final List<_HomeworkItem> items;

  const _HomeworkFilterBar({
    required this.selected,
    required this.onChanged,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final filters = [
      _FilterOption(
          _HomeworkFilter.all, context.l10n.text('All'), items.length),
      _FilterOption(
        _HomeworkFilter.todo,
        context.l10n.text('To do'),
        items
            .where(
              (item) =>
                  item.homework.mySubmission == null &&
                  !_isOverdue(item.homework),
            )
            .length,
      ),
      _FilterOption(
        _HomeworkFilter.dueSoon,
        context.l10n.text('Due soon'),
        items.where((item) => _isDueSoon(item.homework)).length,
      ),
      _FilterOption(
        _HomeworkFilter.submitted,
        context.l10n.text('Submitted'),
        items
            .where(
              (item) =>
                  item.homework.mySubmission != null &&
                  item.homework.mySubmission?.isGraded != true,
            )
            .length,
      ),
      _FilterOption(
        _HomeworkFilter.graded,
        context.l10n.text('Graded'),
        items
            .where((item) => item.homework.mySubmission?.isGraded == true)
            .length,
      ),
    ];

    return SizedBox(
      height: 42,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: filters.map((filter) {
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              selected: selected == filter.value,
              label: Text('${filter.label} ${filter.count}'),
              onSelected: (_) => onChanged(filter.value),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _FilterOption {
  final _HomeworkFilter value;
  final String label;
  final int count;

  const _FilterOption(this.value, this.label, this.count);
}

class _SummaryMetric extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _SummaryMetric({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Column(
      children: [
        Icon(icon, size: 20, color: colors.primary),
        const SizedBox(height: 5),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: colors.onSurface.withValues(alpha: 0.55),
          ),
        ),
      ],
    );
  }
}

class _LessonHomeworkSection extends StatelessWidget {
  final LessonModel lesson;
  final List<_HomeworkItem> items;
  final bool canSubmit;
  final bool loading;
  final bool initiallyExpanded;
  final Future<void> Function(_HomeworkItem item) onOpenHomework;

  const _LessonHomeworkSection({
    required this.lesson,
    required this.items,
    required this.canSubmit,
    required this.loading,
    required this.initiallyExpanded,
    required this.onOpenHomework,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final start = lesson.scheduleTime.toLocal();

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          key: PageStorageKey('homework-lesson-${lesson.lessonId}'),
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
            DateFormat('EEEE, dd/MM/yyyy').format(start),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          subtitle: Text(
            '${DateFormat('HH:mm').format(start)} with ${lesson.tutorName}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _SectionCountBadge(count: items.length),
              const SizedBox(width: 4),
              const Icon(Icons.expand_more_rounded),
            ],
          ),
          children: items.map(
            (item) {
              return Padding(
                padding: const EdgeInsets.only(top: 10),
                child: _HomeworkCard(
                  item: item,
                  canSubmit: canSubmit,
                  loading: loading,
                  onOpenHomework: () => onOpenHomework(item),
                ),
              );
            },
          ).toList(),
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

class _HomeworkCard extends StatelessWidget {
  final _HomeworkItem item;
  final bool canSubmit;
  final bool loading;
  final VoidCallback onOpenHomework;

  const _HomeworkCard({
    required this.item,
    required this.canSubmit,
    required this.loading,
    required this.onOpenHomework,
  });

  @override
  Widget build(BuildContext context) {
    final homework = item.homework;
    final lesson = item.lesson;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final submission = homework.mySubmission;
    final overdue = _isOverdue(homework);
    final dueSoon = _isDueSoon(homework);
    final typeLabel = context.l10n.text(
      homework.isMultipleChoice ? 'Multiple choice' : 'Essay',
    );

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: overdue
              ? const Color(0xFFF7C1C1)
              : dueSoon
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
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFFE6F1FB),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  homework.isMultipleChoice
                      ? Icons.checklist_rounded
                      : Icons.edit_note_rounded,
                  color: const Color(0xFF185FA5),
                  size: 21,
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
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${_subjectName(lesson)} - $typeLabel - ${context.l10n.points(homework.totalPoints.g)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurface.withValues(alpha: 0.55),
                      ),
                    ),
                  ],
                ),
              ),
              _HomeworkStatusChip(homework: homework),
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
          _DueWarning(homework: homework),
          const SizedBox(height: 10),
          _MetaRow(
            icon: Icons.event_outlined,
            label: context.l10n.dueAt(
              DateFormat('dd/MM/yyyy HH:mm').format(
                homework.dueDate.toLocal(),
              ),
            ),
          ),
          const SizedBox(height: 6),
          _MetaRow(
            icon: Icons.school_outlined,
            label: context.l10n.lessonWithTutor(
              DateFormat('dd/MM/yyyy HH:mm').format(
                lesson.scheduleTime.toLocal(),
              ),
              lesson.tutorName,
            ),
          ),
          const SizedBox(height: 12),
          if (submission == null)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () =>
                        context.push('/lessons/${lesson.lessonId}'),
                    icon: const Icon(Icons.open_in_new_rounded, size: 16),
                    label: Text(context.l10n.text('Open lesson')),
                  ),
                ),
                if (canSubmit) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: loading || overdue ? null : onOpenHomework,
                      icon: const Icon(Icons.upload_file_rounded, size: 17),
                      label: Text(
                        context.l10n.text(overdue ? 'Overdue' : 'Do homework'),
                      ),
                    ),
                  ),
                ],
              ],
            )
          else ...[
            _SubmissionResult(submission: submission),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onOpenHomework,
                icon: const Icon(Icons.visibility_outlined, size: 17),
                label: Text(context.l10n.text('View result')),
              ),
            ),
          ],
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
              context.l10n.rangeOf(start, end, totalItems),
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.onSurface.withValues(alpha: 0.55),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          IconButton.outlined(
            onPressed: page == 0 ? null : () => onChanged(page - 1),
            icon: const Icon(Icons.chevron_left_rounded),
            tooltip: context.l10n.text('Previous page'),
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
            tooltip: context.l10n.text('Next page'),
          ),
        ],
      ),
    );
  }
}

class _DueWarning extends StatelessWidget {
  final HomeworkModel homework;

  const _DueWarning({required this.homework});

  @override
  Widget build(BuildContext context) {
    final submission = homework.mySubmission;
    if (submission != null ||
        (!_isDueSoon(homework) && !_isOverdue(homework))) {
      return const SizedBox.shrink();
    }

    final overdue = _isOverdue(homework);
    final bg = overdue ? const Color(0xFFFCEBEB) : const Color(0xFFFAEEDA);
    final fg = overdue ? const Color(0xFFA32D2D) : const Color(0xFF854F0B);
    final icon =
        overdue ? Icons.error_outline_rounded : Icons.warning_amber_rounded;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: fg),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              overdue
                  ? context.l10n.text('This homework is past its due date.')
                  : context.l10n.text(
                      'This homework is close to its due date.',
                    ),
              style: TextStyle(
                color: fg,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SubmissionResult extends StatelessWidget {
  final HomeworkSubmissionModel submission;

  const _SubmissionResult({required this.submission});

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
          Row(
            children: [
              Icon(
                submission.isGraded
                    ? Icons.check_circle_outline_rounded
                    : Icons.hourglass_bottom_rounded,
                size: 18,
                color: submission.isGraded
                    ? const Color(0xFF3B6D11)
                    : const Color(0xFF854F0B),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  submission.isGraded
                      ? context.l10n.text('Result available')
                      : context.l10n.text('Submitted'),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                context.l10n.points(
                    '${submission.totalScore.g}/${submission.maxScore.g}'),
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            context.l10n.submittedAt(
              DateFormat('dd/MM/yyyy HH:mm').format(
                submission.submittedAt.toLocal(),
              ),
            ),
            style: theme.textTheme.bodySmall?.copyWith(
              color: colors.onSurface.withValues(alpha: 0.55),
            ),
          ),
          if ((submission.feedback ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              submission.feedback!.trim(),
              style: theme.textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }
}

class _HomeworkStatusChip extends StatelessWidget {
  final HomeworkModel homework;

  const _HomeworkStatusChip({required this.homework});

  @override
  Widget build(BuildContext context) {
    final submission = homework.mySubmission;
    String label;
    Color bg;
    Color fg;
    Color border;

    if (submission?.isGraded == true) {
      label = context.l10n.text('Graded');
      bg = const Color(0xFFEAF3DE);
      fg = const Color(0xFF3B6D11);
      border = const Color(0xFFC0DD97);
    } else if (submission != null) {
      label = context.l10n.text('Submitted');
      bg = const Color(0xFFE6F1FB);
      fg = const Color(0xFF185FA5);
      border = const Color(0xFFBFDDF5);
    } else if (_isOverdue(homework)) {
      label = context.l10n.text('Overdue');
      bg = const Color(0xFFFCEBEB);
      fg = const Color(0xFFA32D2D);
      border = const Color(0xFFF7C1C1);
    } else if (_isDueSoon(homework)) {
      label = context.l10n.text('Due soon');
      bg = const Color(0xFFFAEEDA);
      fg = const Color(0xFF854F0B);
      border = const Color(0xFFFAC775);
    } else {
      label = context.l10n.text('Pending');
      bg = Theme.of(context).colorScheme.surfaceContainerHighest;
      fg = Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.65);
      border = Theme.of(context).colorScheme.outlineVariant;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: border, width: 0.5),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: fg),
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

class _HomeworkItem {
  final LessonModel lesson;
  final HomeworkModel homework;

  const _HomeworkItem({
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

extension _ScoreFormat on double {
  String get g =>
      this == roundToDouble() ? toInt().toString() : toStringAsFixed(1);
}

bool _isOverdue(HomeworkModel homework) {
  return homework.mySubmission == null &&
      homework.dueDate.toLocal().isBefore(DateTime.now());
}

bool _isDueSoon(HomeworkModel homework) {
  if (homework.mySubmission != null) return false;
  final now = DateTime.now();
  final due = homework.dueDate.toLocal();
  return due.isAfter(now) && due.difference(now) <= const Duration(days: 2);
}

String _subjectName(LessonModel lesson) {
  final name = lesson.subjectName;
  if (name != null && name.trim().isNotEmpty) return name.trim();
  return 'Subject #${lesson.subjectId ?? '-'}';
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
      label: '${_subjectName(first)} - ${first.tutorName}',
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
