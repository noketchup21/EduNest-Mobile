import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../l10n/app_strings.dart';
import '../../models/mvp_models.dart';
import '../../providers/app_data_provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_ui.dart';
import '../../widgets/error_banner.dart';
import '../../widgets/user_avatar.dart';
import '../homework/tutor_homework_screen.dart'
    show
        showEssayGradeSheet,
        showTutorHomeworkEditor,
        showTutorHomeworkLessonPicker;
import '../materials/course_materials_screen.dart'
    show materialUri, showMaterialEditor, showMaterialSectionEditor;

/// A course-first view of the existing lessons, homework, and materials data.
///
/// This screen deliberately owns no domain state: it calls the same provider
/// methods as the legacy course screens and keeps their routes available for
/// detailed lesson, homework, and material actions.
class CourseHubScreen extends StatefulWidget {
  const CourseHubScreen({super.key});

  @override
  State<CourseHubScreen> createState() => _CourseHubScreenState();
}

class _CourseHubScreenState extends State<CourseHubScreen> {
  int? _selectedAvailabilityId;
  bool _initialized = false;
  bool _showPastLessons = false;
  bool _showCompletedHomework = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadHub());
  }

  Future<void> _loadHub({bool force = false}) async {
    final data = context.read<AppDataProvider>();
    final auth = context.read<AuthProvider>();

    try {
      await data.loadLessons();
      if (auth.isTutor) {
        await data.loadMyAvailability();
      }

      if (!mounted) return;
      final courses = _coursesFor(data, auth);
      final selectedId = _selectedCourseId(courses);

      setState(() => _selectedAvailabilityId = selectedId);

      if (selectedId != null) {
        await Future.wait([
          data.loadHomeworkCourse(selectedId, force: force),
          data.loadCourseMaterials(selectedId, force: force),
        ]);
      }
    } catch (_) {
      // The provider retains the user-facing error message for ErrorBanner.
    } finally {
      if (mounted) setState(() => _initialized = true);
    }
  }

  Future<void> _selectCourse(int availabilityId) async {
    if (availabilityId == _selectedAvailabilityId) return;

    setState(() {
      _selectedAvailabilityId = availabilityId;
      _showPastLessons = false;
      _showCompletedHomework = false;
    });

    final data = context.read<AppDataProvider>();
    try {
      await Future.wait([
        data.loadHomeworkCourse(availabilityId),
        data.loadCourseMaterials(availabilityId),
      ]);
    } catch (_) {
      // Existing provider feedback remains visible in the hub.
    }
  }

  Future<void> _createTutorHomework(_CourseHubCourse course) async {
    final t = AppStrings.of(context, listen: false);
    if (course.lessons.isEmpty) {
      _showSnack(t.text('No lesson is available for homework yet.'));
      return;
    }

    final lesson = await showTutorHomeworkLessonPicker(context, course.lessons);
    if (lesson == null || !mounted) return;

    final body = await showTutorHomeworkEditor(context);
    if (body == null || !mounted) return;

    try {
      await context.read<AppDataProvider>().createHomework(
            lessonId: lesson.lessonId,
            body: body,
          );
      if (!mounted) return;
      _showSnack(t.text('Homework created'));
    } catch (_) {
      // Provider error is rendered by the active tab.
    }
  }

  Future<void> _editTutorHomework(_HomeworkItem item) async {
    final t = AppStrings.of(context, listen: false);
    if (item.homework.submissions.isNotEmpty) {
      _showSnack(
        t.text('Homework cannot be edited after a submission is received'),
      );
      return;
    }

    final body = await showTutorHomeworkEditor(
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
      _showSnack(t.text('Homework updated'));
    } catch (_) {
      // Provider error is rendered by the active tab.
    }
  }

  Future<void> _deleteTutorHomework(_HomeworkItem item) async {
    final t = AppStrings.of(context, listen: false);
    final confirmed = await _confirm(
      title: t.text('Delete homework?'),
      message: t.text('Delete homework and its submissions?'),
    );
    if (confirmed != true || !mounted) return;

    try {
      await context.read<AppDataProvider>().deleteHomework(
            lessonId: item.lesson.lessonId,
            homeworkId: item.homework.homeworkId,
          );
      if (!mounted) return;
      _showSnack(t.text('Homework deleted'));
    } catch (_) {
      // Provider error is rendered by the active tab.
    }
  }

  Future<void> _gradeTutorHomework({
    required _HomeworkItem item,
    required HomeworkSubmissionModel submission,
  }) async {
    final t = AppStrings.of(context, listen: false);
    final payload = await showEssayGradeSheet(
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
      _showSnack(t.text('Submission graded'));
    } catch (_) {
      // Provider error is rendered by the active tab.
    }
  }

  Future<void> _createMaterialSection(_CourseHubCourse course) async {
    final t = AppStrings.of(context, listen: false);
    final payload = await showMaterialSectionEditor(context);
    if (payload == null || !mounted) return;

    try {
      await context.read<AppDataProvider>().createMaterialSection(
            availabilityId: course.id,
            title: payload.title,
            description: payload.description,
          );
      if (!mounted) return;
      _showSnack(t.text('Section added'));
    } catch (_) {
      // Provider error is rendered by the active tab.
    }
  }

  Future<void> _editMaterialSection(
    _CourseHubCourse course,
    CourseMaterialSectionModel section,
  ) async {
    final t = AppStrings.of(context, listen: false);
    if (section.sectionId == 0) {
      _showSnack(
        t.text(
          'This default section can be edited after backend sections are enabled.',
        ),
      );
      return;
    }

    final payload = await showMaterialSectionEditor(context, section: section);
    if (payload == null || !mounted) return;

    try {
      await context.read<AppDataProvider>().updateMaterialSection(
            availabilityId: course.id,
            sectionId: section.sectionId,
            title: payload.title,
            description: payload.description,
          );
      if (!mounted) return;
      _showSnack(t.text('Section updated'));
    } catch (_) {
      // Provider error is rendered by the active tab.
    }
  }

  Future<void> _deleteMaterialSection(
    _CourseHubCourse course,
    CourseMaterialSectionModel section,
  ) async {
    final t = AppStrings.of(context, listen: false);
    if (section.sectionId == 0) {
      _showSnack(t.text('This default section cannot be deleted.'));
      return;
    }

    final confirmed = await _confirm(
      title: t.text('Delete section?'),
      message: t.deleteSectionMessage(section.title),
    );
    if (confirmed != true || !mounted) return;

    try {
      await context.read<AppDataProvider>().deleteMaterialSection(
            availabilityId: course.id,
            sectionId: section.sectionId,
          );
      if (!mounted) return;
      _showSnack(t.text('Section deleted'));
    } catch (_) {
      // Provider error is rendered by the active tab.
    }
  }

  Future<void> _addMaterial(
    _CourseHubCourse course,
    CourseMaterialSectionModel section,
  ) async {
    final t = AppStrings.of(context, listen: false);
    final payload = await showMaterialEditor(context);
    if (payload == null || !mounted) return;

    try {
      await context.read<AppDataProvider>().createMaterialItem(
            availabilityId: course.id,
            sectionId: section.sectionId,
            title: payload.title,
            description: payload.description,
            linkUrl: payload.linkUrl,
            file: payload.file,
          );
      if (!mounted) return;
      _showSnack(t.text('Material added'));
    } catch (_) {
      // Provider error is rendered by the active tab.
    }
  }

  Future<void> _editMaterial(
    _CourseHubCourse course,
    CourseMaterialItemModel item,
  ) async {
    final data = context.read<AppDataProvider>();
    final t = AppStrings.of(context, listen: false);
    final payload = await showMaterialEditor(
      context,
      item: item,
      sections: data.courseMaterials[course.id] ?? const [],
    );
    if (payload == null || !mounted) return;

    try {
      await data.updateMaterialItem(
        availabilityId: course.id,
        materialId: item.materialId,
        title: payload.title,
        description: payload.description,
        linkUrl: payload.linkUrl,
        file: payload.file,
        sectionId: payload.sectionId,
      );
      if (!mounted) return;
      _showSnack(t.text('Material updated'));
    } catch (_) {
      // Provider error is rendered by the active tab.
    }
  }

  Future<void> _deleteMaterial(
    _CourseHubCourse course,
    CourseMaterialItemModel item,
  ) async {
    final t = AppStrings.of(context, listen: false);
    final confirmed = await _confirm(
      title: t.text('Delete material?'),
      message: t.deleteMaterialMessage(item.title),
    );
    if (confirmed != true || !mounted) return;

    try {
      await context.read<AppDataProvider>().deleteMaterialItem(
            availabilityId: course.id,
            materialId: item.materialId,
          );
      if (!mounted) return;
      _showSnack(t.text('Material deleted'));
    } catch (_) {
      // Provider error is rendered by the active tab.
    }
  }

  Future<void> _openMaterial(CourseMaterialItemModel item) async {
    final t = AppStrings.of(context, listen: false);
    final uri = materialUri(item);
    if (uri == null) {
      _showSnack(t.text('No file or link is available for this material.'));
      return;
    }

    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && mounted) {
      _showSnack(t.text('Could not open this material.'));
    }
  }

  Future<bool?> _confirm({
    required String title,
    required String message,
  }) {
    final t = AppStrings.of(context, listen: false);
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(t.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(t.delete),
          ),
        ],
      ),
    );
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  int? _selectedCourseId(List<_CourseHubCourse> courses) {
    if (courses.isEmpty) return null;
    if (_selectedAvailabilityId != null &&
        courses.any((course) => course.id == _selectedAvailabilityId)) {
      return _selectedAvailabilityId;
    }
    return courses.first.id;
  }

  @override
  Widget build(BuildContext context) {
    final data = context.watch<AppDataProvider>();
    final auth = context.watch<AuthProvider>();
    final t = context.l10n;
    final colors = Theme.of(context).colorScheme;
    final courses = _coursesFor(data, auth);
    final selectedId = _selectedCourseId(courses);
    final matchingCourses = courses.where((item) => item.id == selectedId);
    final course = matchingCourses.isEmpty ? null : matchingCourses.first;

    return Scaffold(
      appBar: AppBar(
        title: Text(t.text('Learning space')),
        actions: [
          IconButton(
            tooltip: t.refresh,
            onPressed: data.loading ? null : () => _loadHub(force: true),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: !_initialized && data.loading
          ? const Center(child: AppLoadingState())
          : course == null
              ? RefreshIndicator(
                  onRefresh: () => _loadHub(force: true),
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      ErrorBanner(data.error),
                      const SizedBox(height: 28),
                      AppEmptyState(
                        icon: Icons.menu_book_outlined,
                        title: t.noCoursesAvailableYet,
                        message: t.text(
                          'Your lessons, homework, and materials will appear here.',
                        ),
                        action: FilledButton.tonalIcon(
                          onPressed: () => _loadHub(force: true),
                          icon: const Icon(Icons.refresh_rounded),
                          label: Text(t.refresh),
                        ),
                      ),
                    ],
                  ),
                )
              : DefaultTabController(
                  key: ValueKey(course.id),
                  length: 3,
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                        child: _CourseHero(
                          course: course,
                          courses: courses,
                          isTutor: auth.isTutor,
                          onChanged: _selectCourse,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Material(
                        color: colors.surface,
                        child: TabBar(
                          indicatorSize: TabBarIndicatorSize.tab,
                          indicator: BoxDecoration(
                            color: colors.primary,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          labelColor: colors.onPrimary,
                          unselectedLabelColor: colors.onSurfaceVariant,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          tabs: [
                            Tab(text: t.lesson),
                            Tab(text: t.homework),
                            Tab(text: t.materials),
                          ],
                        ),
                      ),
                      Expanded(
                        child: TabBarView(
                          children: [
                            _LessonsTab(
                              course: course,
                              loading: data.loading,
                              error: data.error,
                              showPast: _showPastLessons,
                              onTogglePast: () => setState(
                                () => _showPastLessons = !_showPastLessons,
                              ),
                              onRefresh: () => _loadHub(force: true),
                            ),
                            _HomeworkTab(
                              course: course,
                              homeworkByLesson: data.lessonHomeworks,
                              loading: data.loading,
                              error: data.error,
                              isTutor: auth.isTutor,
                              canOpenHomework: auth.isLearner,
                              showCompleted: _showCompletedHomework,
                              onToggleCompleted: () => setState(
                                () => _showCompletedHomework =
                                    !_showCompletedHomework,
                              ),
                              onRefresh: () => _loadHub(force: true),
                              onCreateTutorHomework: () =>
                                  _createTutorHomework(course),
                              onEditTutorHomework: _editTutorHomework,
                              onDeleteTutorHomework: _deleteTutorHomework,
                              onGradeTutorHomework: _gradeTutorHomework,
                            ),
                            _MaterialsTab(
                              course: course,
                              sections:
                                  data.courseMaterials[course.id] ?? const [],
                              loading: data.loading,
                              error: data.error,
                              isTutor: auth.isTutor,
                              onRefresh: () => _loadHub(force: true),
                              onCreateSection: () =>
                                  _createMaterialSection(course),
                              onEditSection: (section) =>
                                  _editMaterialSection(course, section),
                              onDeleteSection: (section) =>
                                  _deleteMaterialSection(course, section),
                              onAddMaterial: (section) =>
                                  _addMaterial(course, section),
                              onEditMaterial: (item) =>
                                  _editMaterial(course, item),
                              onDeleteMaterial: (item) =>
                                  _deleteMaterial(course, item),
                              onOpenMaterial: _openMaterial,
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

class _CourseHero extends StatelessWidget {
  final _CourseHubCourse course;
  final List<_CourseHubCourse> courses;
  final bool isTutor;
  final ValueChanged<int> onChanged;

  const _CourseHero({
    required this.course,
    required this.courses,
    required this.isTutor,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final colors = Theme.of(context).colorScheme;
    final tokens = Theme.of(context).extension<EduNestThemeTokens>() ??
        EduNestThemeTokens.light();
    final completed = course.lessons
        .where((lesson) => lesson.status.trim().toLowerCase() == 'completed')
        .length;
    final total = course.lessons.length;
    final progress = total == 0 ? 0.0 : completed / total;
    final tutorLabel =
        isTutor ? t.text('Your teaching course') : course.tutorName;

    return AppHeroCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            label: t.text('Choose a course'),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  Icon(
                    Icons.school_rounded,
                    color: colors.onPrimary.withValues(alpha: 0.9),
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        value: course.id,
                        isExpanded: true,
                        menuMaxHeight: 360,
                        dropdownColor: colors.surface,
                        borderRadius: BorderRadius.circular(20),
                        icon: Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: colors.onPrimary.withValues(alpha: 0.88),
                        ),
                        selectedItemBuilder: (context) => courses
                            .map(
                              (item) => Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  item.subject,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall
                                      ?.copyWith(
                                        color: colors.onPrimary,
                                        fontWeight: FontWeight.w900,
                                      ),
                                ),
                              ),
                            )
                            .toList(),
                        items: courses
                            .map(
                              (item) => DropdownMenuItem<int>(
                                value: item.id,
                                child: _CourseMenuItem(course: item),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value != null) onChanged(value);
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              UserAvatar(
                imageUrl: course.tutorAvatarUrl,
                name: tutorLabel,
                radius: 18,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  tutorLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: colors.onPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: colors.onPrimary.withValues(alpha: 0.24),
              valueColor: AlwaysStoppedAnimation(tokens.successColor),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            t.courseProgress(completed, total),
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: colors.onPrimary.withValues(alpha: 0.88),
                  fontWeight: FontWeight.w700,
                ),
          ),
          if (course.mode.isNotEmpty || course.level.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (course.mode.isNotEmpty)
                  _HeroMetaChip(
                    icon: Icons.videocam_outlined,
                    label: course.mode,
                  ),
                if (course.level.isNotEmpty)
                  _HeroMetaChip(
                    icon: Icons.insights_outlined,
                    label: course.level,
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _CourseMenuItem extends StatelessWidget {
  final _CourseHubCourse course;

  const _CourseMenuItem({required this.course});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: colors.primaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.menu_book_rounded,
            size: 18,
            color: colors.onPrimaryContainer,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                course.subject,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (course.tutorName.trim().isNotEmpty)
                Text(
                  course.tutorName,
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

class _HeroMetaChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _HeroMetaChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colors.onPrimary.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: colors.onPrimary),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: colors.onPrimary,
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LessonsTab extends StatelessWidget {
  final _CourseHubCourse course;
  final bool loading;
  final String? error;
  final bool showPast;
  final VoidCallback onTogglePast;
  final RefreshCallback onRefresh;

  const _LessonsTab({
    required this.course,
    required this.loading,
    required this.error,
    required this.showPast,
    required this.onTogglePast,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final ordered = [...course.lessons]
      ..sort((a, b) => a.scheduleTime.compareTo(b.scheduleTime));
    final upcoming = ordered.where(_isUpcomingLesson).toList();
    final past = ordered.where((lesson) => !_isUpcomingLesson(lesson)).toList();
    final next = upcoming.isEmpty ? null : upcoming.first;
    final remainingUpcoming =
        next == null ? const <LessonModel>[] : upcoming.skip(1);

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          if (error != null) ErrorBanner(error),
          if (loading && ordered.isEmpty)
            const AppLoadingState()
          else if (ordered.isEmpty)
            AppEmptyState(
              icon: Icons.event_available_outlined,
              title: t.text('No lessons scheduled yet'),
              message:
                  t.text('New lessons will be shown here when they are ready.'),
            )
          else ...[
            if (next != null) ...[
              AppSectionHeader(
                icon: Icons.play_circle_outline_rounded,
                title: t.nextLesson,
              ),
              const SizedBox(height: 12),
              _NextLessonCard(lesson: next),
              const SizedBox(height: 24),
            ],
            if (remainingUpcoming.isNotEmpty) ...[
              AppSectionHeader(
                icon: Icons.calendar_month_outlined,
                title: t.text('Upcoming'),
              ),
              const SizedBox(height: 12),
              ...remainingUpcoming.map(
                (lesson) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _LessonCard(lesson: lesson),
                ),
              ),
              const SizedBox(height: 14),
            ],
            if (past.isNotEmpty) ...[
              TextButton.icon(
                onPressed: onTogglePast,
                icon: Icon(
                  showPast
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                ),
                label: Text(
                  showPast
                      ? t.text('Hide past lessons')
                      : t.showPastLessons(past.length),
                ),
              ),
              if (showPast) ...[
                const SizedBox(height: 8),
                ...past.map(
                  (lesson) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Opacity(
                      opacity: lesson.status.trim().toLowerCase() == 'completed'
                          ? 0.64
                          : 1,
                      child: _LessonCard(lesson: lesson),
                    ),
                  ),
                ),
              ],
            ],
          ],
        ],
      ),
    );
  }
}

class _NextLessonCard extends StatelessWidget {
  final LessonModel lesson;

  const _NextLessonCard({required this.lesson});

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    return AppSurfaceCard(
      kind: AppSurfaceCardKind.marketplace,
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppStatusBadge(
            label: t.text('Ready to learn'),
            icon: Icons.auto_awesome_rounded,
          ),
          const SizedBox(height: 12),
          Text(
            _lessonTitle(lesson, t),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            _lessonDate(lesson),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: () => context.push('/lessons/${lesson.lessonId}'),
              icon: const Icon(Icons.arrow_forward_rounded),
              label: Text(t.open),
            ),
          ),
        ],
      ),
    );
  }
}

class _LessonCard extends StatelessWidget {
  final LessonModel lesson;

  const _LessonCard({required this.lesson});

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    return AppSurfaceCard(
      onTap: () => context.push('/lessons/${lesson.lessonId}'),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.tertiaryContainer,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              lesson.status.trim().toLowerCase() == 'completed'
                  ? Icons.check_circle_rounded
                  : Icons.play_circle_outline_rounded,
              color: Theme.of(context).colorScheme.onTertiaryContainer,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _lessonTitle(lesson, t),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 3),
                Text(
                  _lessonDate(lesson),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          AppStatusBadge(
            label: _lessonStatus(lesson, t),
            tone: _lessonTone(lesson),
          ),
        ],
      ),
    );
  }
}

class _HomeworkTab extends StatelessWidget {
  final _CourseHubCourse course;
  final Map<int, List<HomeworkModel>> homeworkByLesson;
  final bool loading;
  final String? error;
  final bool isTutor;
  final bool canOpenHomework;
  final bool showCompleted;
  final VoidCallback onToggleCompleted;
  final RefreshCallback onRefresh;
  final VoidCallback onCreateTutorHomework;
  final ValueChanged<_HomeworkItem> onEditTutorHomework;
  final ValueChanged<_HomeworkItem> onDeleteTutorHomework;
  final void Function({
    required _HomeworkItem item,
    required HomeworkSubmissionModel submission,
  }) onGradeTutorHomework;

  const _HomeworkTab({
    required this.course,
    required this.homeworkByLesson,
    required this.loading,
    required this.error,
    required this.isTutor,
    required this.canOpenHomework,
    required this.showCompleted,
    required this.onToggleCompleted,
    required this.onRefresh,
    required this.onCreateTutorHomework,
    required this.onEditTutorHomework,
    required this.onDeleteTutorHomework,
    required this.onGradeTutorHomework,
  });

  @override
  Widget build(BuildContext context) {
    if (isTutor) {
      return _TutorHomeworkTab(
        course: course,
        homeworkByLesson: homeworkByLesson,
        loading: loading,
        error: error,
        onRefresh: onRefresh,
        onCreateHomework: onCreateTutorHomework,
        onEditHomework: onEditTutorHomework,
        onDeleteHomework: onDeleteTutorHomework,
        onGradeHomework: onGradeTutorHomework,
      );
    }

    final t = context.l10n;
    final items = _homeworkItems(course.lessons, homeworkByLesson)
      ..sort((a, b) => a.homework.dueDate.compareTo(b.homework.dueDate));
    final dueSoon = items.where(_needsAttention).toList();
    final assigned = items
        .where((item) =>
            item.homework.mySubmission == null && !_needsAttention(item))
        .toList();
    final submitted = items
        .where((item) =>
            item.homework.mySubmission != null &&
            item.homework.mySubmission?.isGraded != true)
        .toList();
    final completed = items
        .where((item) => item.homework.mySubmission?.isGraded == true)
        .toList();

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          if (error != null) ErrorBanner(error),
          if (loading && items.isEmpty)
            const AppLoadingState()
          else if (items.isEmpty)
            AppEmptyState(
              icon: Icons.assignment_outlined,
              title: t.text('No homework yet'),
              message: t.text('Assignments for this course will appear here.'),
            )
          else ...[
            _HomeworkGroup(
              title: t.text('Due soon'),
              icon: Icons.priority_high_rounded,
              items: dueSoon,
              canOpenHomework: canOpenHomework,
            ),
            _HomeworkGroup(
              title: t.text('Assigned'),
              icon: Icons.assignment_outlined,
              items: assigned,
              canOpenHomework: canOpenHomework,
            ),
            _HomeworkGroup(
              title: t.text('Submitted'),
              icon: Icons.outbox_outlined,
              items: submitted,
              canOpenHomework: canOpenHomework,
            ),
            if (completed.isNotEmpty) ...[
              const SizedBox(height: 4),
              TextButton.icon(
                onPressed: onToggleCompleted,
                icon: Icon(
                  showCompleted
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                ),
                label: Text(
                  showCompleted
                      ? t.text('Hide completed homework')
                      : t.showCompletedHomework(completed.length),
                ),
              ),
              if (showCompleted)
                _HomeworkGroup(
                  title: t.completed,
                  icon: Icons.task_alt_rounded,
                  items: completed,
                  canOpenHomework: canOpenHomework,
                ),
            ],
          ],
        ],
      ),
    );
  }
}

class _TutorHomeworkTab extends StatelessWidget {
  final _CourseHubCourse course;
  final Map<int, List<HomeworkModel>> homeworkByLesson;
  final bool loading;
  final String? error;
  final RefreshCallback onRefresh;
  final VoidCallback onCreateHomework;
  final ValueChanged<_HomeworkItem> onEditHomework;
  final ValueChanged<_HomeworkItem> onDeleteHomework;
  final void Function({
    required _HomeworkItem item,
    required HomeworkSubmissionModel submission,
  }) onGradeHomework;

  const _TutorHomeworkTab({
    required this.course,
    required this.homeworkByLesson,
    required this.loading,
    required this.error,
    required this.onRefresh,
    required this.onCreateHomework,
    required this.onEditHomework,
    required this.onDeleteHomework,
    required this.onGradeHomework,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final items = _homeworkItems(course.lessons, homeworkByLesson)
      ..sort((a, b) {
        final gradeCompare = _pendingEssayGrades(b.homework)
            .compareTo(_pendingEssayGrades(a.homework));
        return gradeCompare != 0
            ? gradeCompare
            : a.homework.dueDate.compareTo(b.homework.dueDate);
      });
    final toGrade = items.fold<int>(
      0,
      (total, item) => total + _pendingEssayGrades(item.homework),
    );

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          if (error != null) ErrorBanner(error),
          AppSectionHeader(
            icon: Icons.rate_review_outlined,
            title: t.text('Homework to grade'),
            subtitle: toGrade == 0
                ? t.text('No submissions need review right now.')
                : '${t.text('To grade')}: $toGrade',
            action: FilledButton.tonalIcon(
              onPressed: loading ? null : onCreateHomework,
              icon: const Icon(Icons.add_rounded),
              label: Text(t.text('Add homework')),
            ),
          ),
          const SizedBox(height: 12),
          if (loading && items.isEmpty)
            const AppLoadingState()
          else if (items.isEmpty)
            AppEmptyState(
              icon: Icons.assignment_outlined,
              title: t.text('No homework in this course yet.'),
              message: t.text('Create an assignment for one of your lessons.'),
              action: FilledButton.icon(
                onPressed: onCreateHomework,
                icon: const Icon(Icons.add_rounded),
                label: Text(t.text('Add homework')),
              ),
            )
          else ...[
            if (toGrade > 0) ...[
              AppStatusBadge(
                label: '${t.text('To grade')}: $toGrade',
                tone: AppStatusTone.warning,
                icon: Icons.rate_review_outlined,
              ),
              const SizedBox(height: 12),
            ],
            ...items.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _TutorHomeworkCard(
                  item: item,
                  loading: loading,
                  onEdit: () => onEditHomework(item),
                  onDelete: () => onDeleteHomework(item),
                  onGrade: (submission) => onGradeHomework(
                    item: item,
                    submission: submission,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TutorHomeworkCard extends StatelessWidget {
  final _HomeworkItem item;
  final bool loading;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final ValueChanged<HomeworkSubmissionModel> onGrade;

  const _TutorHomeworkCard({
    required this.item,
    required this.loading,
    required this.onEdit,
    required this.onDelete,
    required this.onGrade,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final homework = item.homework;
    final gradeQueue = homework.isEssay
        ? homework.submissions
            .where((submission) => !submission.isGraded)
            .toList()
        : const <HomeworkSubmissionModel>[];
    final hasSubmissions = homework.submissions.isNotEmpty;

    return AppSurfaceCard(
      onTap: () => context.push(
        '/homework/${item.lesson.lessonId}/${homework.homeworkId}',
      ),
      kind: gradeQueue.isNotEmpty
          ? AppSurfaceCardKind.marketplace
          : AppSurfaceCardKind.content,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _toneBackground(
                    context,
                    gradeQueue.isNotEmpty
                        ? AppStatusTone.warning
                        : AppStatusTone.info,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  homework.isEssay
                      ? Icons.edit_note_rounded
                      : Icons.fact_check_outlined,
                  color: _toneForeground(
                    context,
                    gradeQueue.isNotEmpty
                        ? AppStatusTone.warning
                        : AppStatusTone.info,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      homework.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${t.text('Due')} ${DateFormat('dd MMM, HH:mm').format(homework.dueDate.toLocal())}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'edit') onEdit();
                  if (value == 'delete') onDelete();
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'edit',
                    enabled: !hasSubmissions,
                    child: Text(
                      t.text(
                        hasSubmissions
                            ? 'Edit locked after submission'
                            : 'Edit',
                      ),
                    ),
                  ),
                  PopupMenuItem(value: 'delete', child: Text(t.delete)),
                ],
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              AppMetaChip(
                icon: Icons.inbox_outlined,
                label:
                    '${homework.submissions.length} ${t.text('submissions')}',
              ),
              if (homework.dueDate.toLocal().isBefore(DateTime.now()))
                AppStatusBadge(
                  label: t.text('Overdue'),
                  tone: AppStatusTone.danger,
                  icon: Icons.error_outline_rounded,
                ),
              if (gradeQueue.isNotEmpty)
                AppStatusBadge(
                  label: '${t.text('To grade')}: ${gradeQueue.length}',
                  tone: AppStatusTone.warning,
                  icon: Icons.rate_review_outlined,
                ),
            ],
          ),
          if (gradeQueue.isNotEmpty) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.tonalIcon(
                onPressed: loading ? null : () => onGrade(gradeQueue.first),
                icon: const Icon(Icons.rate_review_outlined),
                label: Text(t.text('Grade submission')),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _HomeworkGroup extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<_HomeworkItem> items;
  final bool canOpenHomework;

  const _HomeworkGroup({
    required this.title,
    required this.icon,
    required this.items,
    required this.canOpenHomework,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppSectionHeader(icon: icon, title: title),
        const SizedBox(height: 12),
        ...items.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _HomeworkCard(
              item: item,
              canOpenHomework: canOpenHomework,
            ),
          ),
        ),
        const SizedBox(height: 14),
      ],
    );
  }
}

class _HomeworkCard extends StatelessWidget {
  final _HomeworkItem item;
  final bool canOpenHomework;

  const _HomeworkCard({required this.item, required this.canOpenHomework});

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final homework = item.homework;
    final tone = _homeworkTone(homework);

    return AppSurfaceCard(
      onTap: canOpenHomework
          ? () => context.push(
                '/homework/${item.lesson.lessonId}/${homework.homeworkId}',
              )
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _toneBackground(context, tone),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  _homeworkIcon(homework),
                  color: _toneForeground(context, tone),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      homework.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${t.text('Due')} ${DateFormat('dd MMM, HH:mm').format(homework.dueDate.toLocal())}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              AppStatusBadge(label: _homeworkStatus(homework, t), tone: tone),
              const SizedBox(width: 2),
              Icon(
                Icons.chevron_right_rounded,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MaterialsTab extends StatelessWidget {
  final _CourseHubCourse course;
  final List<CourseMaterialSectionModel> sections;
  final bool loading;
  final String? error;
  final bool isTutor;
  final RefreshCallback onRefresh;
  final VoidCallback onCreateSection;
  final ValueChanged<CourseMaterialSectionModel> onEditSection;
  final ValueChanged<CourseMaterialSectionModel> onDeleteSection;
  final ValueChanged<CourseMaterialSectionModel> onAddMaterial;
  final ValueChanged<CourseMaterialItemModel> onEditMaterial;
  final ValueChanged<CourseMaterialItemModel> onDeleteMaterial;
  final ValueChanged<CourseMaterialItemModel> onOpenMaterial;

  const _MaterialsTab({
    required this.course,
    required this.sections,
    required this.loading,
    required this.error,
    required this.isTutor,
    required this.onRefresh,
    required this.onCreateSection,
    required this.onEditSection,
    required this.onDeleteSection,
    required this.onAddMaterial,
    required this.onEditMaterial,
    required this.onDeleteMaterial,
    required this.onOpenMaterial,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          if (error != null) ErrorBanner(error),
          AppSectionHeader(
            icon: Icons.folder_copy_outlined,
            title: isTutor ? t.text('Manage course materials') : t.materials,
            subtitle: isTutor
                ? t.text(
                    'Create sections, files, and useful links for learners.')
                : t.text('Open files and links shared for this course.'),
            action: isTutor
                ? FilledButton.tonalIcon(
                    onPressed: loading ? null : onCreateSection,
                    icon: const Icon(Icons.create_new_folder_outlined),
                    label: Text(t.text('Add section')),
                  )
                : null,
          ),
          const SizedBox(height: 12),
          if (loading && sections.isEmpty)
            const AppLoadingState()
          else if (sections.isEmpty)
            AppEmptyState(
              icon: Icons.folder_open_outlined,
              title: t.text('No materials yet'),
              message: isTutor
                  ? t.text('Create a topic, then add the first file or link.')
                  : t.text('Course files and links will be shared here.'),
              action: isTutor
                  ? FilledButton.icon(
                      onPressed: onCreateSection,
                      icon: const Icon(Icons.create_new_folder_outlined),
                      label: Text(t.text('Add section')),
                    )
                  : null,
            )
          else
            ...sections.map(
              (section) => _MaterialSection(
                section: section,
                isTutor: isTutor,
                loading: loading,
                onEditSection: () => onEditSection(section),
                onDeleteSection: () => onDeleteSection(section),
                onAddMaterial: () => onAddMaterial(section),
                onOpenMaterial: onOpenMaterial,
                onEditMaterial: onEditMaterial,
                onDeleteMaterial: onDeleteMaterial,
              ),
            ),
        ],
      ),
    );
  }
}

class _MaterialSection extends StatelessWidget {
  final CourseMaterialSectionModel section;
  final bool isTutor;
  final bool loading;
  final VoidCallback onEditSection;
  final VoidCallback onDeleteSection;
  final VoidCallback onAddMaterial;
  final ValueChanged<CourseMaterialItemModel> onOpenMaterial;
  final ValueChanged<CourseMaterialItemModel> onEditMaterial;
  final ValueChanged<CourseMaterialItemModel> onDeleteMaterial;

  const _MaterialSection({
    required this.section,
    required this.isTutor,
    required this.loading,
    required this.onEditSection,
    required this.onDeleteSection,
    required this.onAddMaterial,
    required this.onOpenMaterial,
    required this.onEditMaterial,
    required this.onDeleteMaterial,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSectionHeader(
            icon: Icons.topic_outlined,
            title: section.title,
            subtitle: section.description,
            action: isTutor
                ? PopupMenuButton<String>(
                    enabled: !loading,
                    tooltip: t.text('Manage section'),
                    onSelected: (value) {
                      if (value == 'add') onAddMaterial();
                      if (value == 'edit') onEditSection();
                      if (value == 'delete') onDeleteSection();
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'add',
                        child: Text(t.text('Add material')),
                      ),
                      PopupMenuItem(
                        value: 'edit',
                        child: Text(t.text('Edit section')),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Text(t.delete),
                      ),
                    ],
                  )
                : null,
          ),
          const SizedBox(height: 12),
          if (section.items.isEmpty)
            AppSurfaceCard(
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      t.text('No files in this topic yet.'),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ),
                  if (isTutor) ...[
                    const SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: loading ? null : onAddMaterial,
                      icon: const Icon(Icons.add_rounded),
                      label: Text(t.text('Add material')),
                    ),
                  ],
                ],
              ),
            )
          else
            ...section.items.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _MaterialCard(
                  item: item,
                  isTutor: isTutor,
                  loading: loading,
                  onOpen: () => onOpenMaterial(item),
                  onEdit: () => onEditMaterial(item),
                  onDelete: () => onDeleteMaterial(item),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MaterialCard extends StatelessWidget {
  final CourseMaterialItemModel item;
  final bool isTutor;
  final bool loading;
  final VoidCallback onOpen;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _MaterialCard({
    required this.item,
    required this.isTutor,
    required this.loading,
    required this.onOpen,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final icon = _materialIcon(item);
    final color = _materialColor(context, item);
    return AppSurfaceCard(
      onTap: item.canOpen ? onOpen : null,
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                if (item.description?.trim().isNotEmpty == true) ...[
                  const SizedBox(height: 3),
                  Text(
                    item.description!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            onPressed: item.canOpen ? onOpen : null,
            tooltip: t.open,
            icon: const Icon(Icons.open_in_new_rounded),
          ),
          if (isTutor)
            PopupMenuButton<String>(
              enabled: !loading,
              onSelected: (value) {
                if (value == 'edit') onEdit();
                if (value == 'delete') onDelete();
              },
              itemBuilder: (context) => [
                PopupMenuItem(value: 'edit', child: Text(t.text('Edit'))),
                PopupMenuItem(value: 'delete', child: Text(t.delete)),
              ],
            ),
        ],
      ),
    );
  }
}

class _CourseHubCourse {
  final int id;
  final String subject;
  final String tutorName;
  final String? tutorAvatarUrl;
  final String mode;
  final String level;
  final List<LessonModel> lessons;

  const _CourseHubCourse({
    required this.id,
    required this.subject,
    required this.tutorName,
    required this.tutorAvatarUrl,
    required this.mode,
    required this.level,
    required this.lessons,
  });
}

class _HomeworkItem {
  final LessonModel lesson;
  final HomeworkModel homework;

  const _HomeworkItem({required this.lesson, required this.homework});
}

List<_CourseHubCourse> _coursesFor(AppDataProvider data, AuthProvider auth) {
  final lessonsByAvailability = <int, List<LessonModel>>{};
  for (final lesson in data.lessons) {
    lessonsByAvailability
        .putIfAbsent(lesson.availabilityId, () => [])
        .add(lesson);
  }

  final availabilityById = {
    for (final availability in [
      ...data.myAvailabilities,
      ...data.availabilities
    ])
      availability.availabilityId: availability,
  };
  final ids = <int>{...lessonsByAvailability.keys};
  if (auth.isTutor) {
    ids.addAll(data.myAvailabilities.map((item) => item.availabilityId));
  }

  final courses = ids.map((id) {
    final lessons = [...(lessonsByAvailability[id] ?? const <LessonModel>[])]
      ..sort((a, b) => a.scheduleTime.compareTo(b.scheduleTime));
    final availability = availabilityById[id];
    final firstLesson = lessons.isEmpty ? null : lessons.first;
    final subject = availability == null
        ? _lessonTitle(firstLesson, null)
        : data.availabilitySubjectName(availability);

    return _CourseHubCourse(
      id: id,
      subject: subject,
      tutorName: firstLesson?.tutorName ?? '',
      tutorAvatarUrl:
          firstLesson?.tutorAvatarUrl ?? availability?.tutorAvatarUrl,
      mode: availability?.mode.trim() ?? '',
      level: availability?.level.trim() ?? '',
      lessons: lessons,
    );
  }).toList();

  courses.sort((a, b) => a.subject.compareTo(b.subject));
  return courses;
}

List<_HomeworkItem> _homeworkItems(
  List<LessonModel> lessons,
  Map<int, List<HomeworkModel>> homeworkByLesson,
) {
  final unique = <int, _HomeworkItem>{};
  for (final lesson in lessons) {
    for (final homework in homeworkByLesson[lesson.lessonId] ?? const []) {
      unique.putIfAbsent(
        homework.homeworkId,
        () => _HomeworkItem(lesson: lesson, homework: homework),
      );
    }
  }
  return unique.values.toList();
}

bool _isUpcomingLesson(LessonModel lesson) {
  final end =
      lesson.scheduleTime.toLocal().add(Duration(minutes: lesson.duration));
  return lesson.status.trim().toLowerCase() != 'completed' &&
      end.isAfter(DateTime.now());
}

bool _needsAttention(_HomeworkItem item) {
  final homework = item.homework;
  if (homework.mySubmission != null) return false;
  return homework.dueDate.toLocal().difference(DateTime.now()) <=
      const Duration(days: 3);
}

int _pendingEssayGrades(HomeworkModel homework) {
  if (!homework.isEssay) return 0;
  return homework.submissions
      .where((submission) => !submission.isGraded)
      .length;
}

String _lessonTitle(LessonModel? lesson, AppStrings? t) {
  final subject = lesson?.subjectName?.trim() ?? '';
  return subject.isEmpty ? (t?.text('Course') ?? 'Course') : subject;
}

String _lessonDate(LessonModel lesson) {
  final start = lesson.scheduleTime.toLocal();
  return '${DateFormat('EEE, dd MMM').format(start)} · ${DateFormat('HH:mm').format(start)}';
}

String _lessonStatus(LessonModel lesson, AppStrings t) {
  final status = lesson.status.trim().toLowerCase();
  if (status == 'completed') return t.completed;
  if (_isUpcomingLesson(lesson)) return t.text('Upcoming');
  return t.status(lesson.status);
}

AppStatusTone _lessonTone(LessonModel lesson) {
  if (lesson.status.trim().toLowerCase() == 'completed') {
    return AppStatusTone.success;
  }
  return _isUpcomingLesson(lesson) ? AppStatusTone.info : AppStatusTone.warning;
}

String _homeworkStatus(HomeworkModel homework, AppStrings t) {
  if (homework.mySubmission?.isGraded == true) return t.completed;
  if (homework.mySubmission != null) return t.text('Submitted');
  if (homework.dueDate.toLocal().isBefore(DateTime.now())) {
    return t.text('Overdue');
  }
  if (homework.dueDate.toLocal().difference(DateTime.now()) <=
      const Duration(days: 3)) {
    return t.text('Due soon');
  }
  return t.text('Assigned');
}

AppStatusTone _homeworkTone(HomeworkModel homework) {
  if (homework.mySubmission?.isGraded == true) return AppStatusTone.success;
  if (homework.mySubmission != null) return AppStatusTone.info;
  if (homework.dueDate.toLocal().isBefore(DateTime.now())) {
    return AppStatusTone.danger;
  }
  if (homework.dueDate.toLocal().difference(DateTime.now()) <=
      const Duration(days: 3)) {
    return AppStatusTone.warning;
  }
  return AppStatusTone.neutral;
}

IconData _homeworkIcon(HomeworkModel homework) {
  if (homework.mySubmission?.isGraded == true) return Icons.task_alt_rounded;
  if (homework.mySubmission != null) return Icons.outbox_outlined;
  return homework.isEssay ? Icons.edit_note_rounded : Icons.assignment_outlined;
}

Color _toneBackground(BuildContext context, AppStatusTone tone) {
  final colors = Theme.of(context).colorScheme;
  final tokens = Theme.of(context).extension<EduNestThemeTokens>() ??
      EduNestThemeTokens.light();
  return switch (tone) {
    AppStatusTone.success => tokens.successColor.withValues(alpha: 0.14),
    AppStatusTone.warning => tokens.warningColor.withValues(alpha: 0.16),
    AppStatusTone.danger => colors.errorContainer,
    AppStatusTone.info => colors.primaryContainer,
    AppStatusTone.neutral => colors.surfaceContainerHighest,
  };
}

Color _toneForeground(BuildContext context, AppStatusTone tone) {
  final colors = Theme.of(context).colorScheme;
  final tokens = Theme.of(context).extension<EduNestThemeTokens>() ??
      EduNestThemeTokens.light();
  return switch (tone) {
    AppStatusTone.success => tokens.successColor,
    AppStatusTone.warning => tokens.warningColor,
    AppStatusTone.danger => colors.onErrorContainer,
    AppStatusTone.info => colors.onPrimaryContainer,
    AppStatusTone.neutral => colors.onSurfaceVariant,
  };
}

IconData _materialIcon(CourseMaterialItemModel item) {
  final type =
      '${item.contentType ?? ''} ${item.fileName ?? ''} ${item.materialType}'
          .toLowerCase();
  if (type.contains('pdf')) return Icons.picture_as_pdf_rounded;
  if (type.contains('video')) return Icons.play_circle_fill_rounded;
  if (type.contains('image') || type.contains('png') || type.contains('jpg')) {
    return Icons.image_outlined;
  }
  if (type.contains('link') || type.contains('http')) return Icons.link_rounded;
  return Icons.attach_file_rounded;
}

Color _materialColor(BuildContext context, CourseMaterialItemModel item) {
  final colors = Theme.of(context).colorScheme;
  final tokens = Theme.of(context).extension<EduNestThemeTokens>() ??
      EduNestThemeTokens.light();
  final type =
      '${item.contentType ?? ''} ${item.fileName ?? ''} ${item.materialType}'
          .toLowerCase();
  if (type.contains('pdf')) return colors.secondary;
  if (type.contains('video')) return colors.primary;
  if (type.contains('image') || type.contains('png') || type.contains('jpg')) {
    return tokens.successColor;
  }
  if (type.contains('link') || type.contains('http')) return colors.tertiary;
  return colors.primary;
}
