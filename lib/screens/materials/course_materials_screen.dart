import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../l10n/app_strings.dart';
import '../../models/mvp_models.dart';
import '../../providers/app_data_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../widgets/app_ui.dart';
import '../../widgets/error_banner.dart';

class CourseMaterialsScreen extends StatefulWidget {
  const CourseMaterialsScreen({super.key});

  @override
  State<CourseMaterialsScreen> createState() => _CourseMaterialsScreenState();
}

const int _maxMaterialUploadBytes = 10 * 1024 * 1024;

class _CourseMaterialsScreenState extends State<CourseMaterialsScreen> {
  int? selectedAvailabilityId;
  bool initialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadDashboard());
  }

  Future<void> _loadDashboard({bool force = false}) async {
    final data = context.read<AppDataProvider>();
    final auth = context.read<AuthProvider>();

    try {
      if (auth.isTutor) {
        await data.loadMyAvailability();
      }
      await data.loadLessons();
    } catch (_) {
      if (!mounted) return;
    }

    if (!mounted) return;

    final courses = _coursesFor(data, auth);
    final nextId = _selectedOrDefaultCourseId(courses);

    setState(() {
      initialized = true;
      selectedAvailabilityId = nextId;
    });

    if (nextId != null) {
      try {
        await data.loadCourseMaterials(nextId, force: force);
      } catch (_) {
        if (!mounted) return;
      }
    }
  }

  Future<void> _reload() async {
    final id = selectedAvailabilityId;
    if (id == null) {
      await _loadDashboard(force: true);
      return;
    }

    try {
      await context.read<AppDataProvider>().loadCourseMaterials(
            id,
            force: true,
          );
    } catch (_) {}
  }

  Future<void> _selectCourse(int availabilityId) async {
    setState(() => selectedAvailabilityId = availabilityId);
    try {
      await context.read<AppDataProvider>().loadCourseMaterials(availabilityId);
    } catch (_) {}
  }

  Future<void> _addSection() async {
    final availabilityId = selectedAvailabilityId;
    if (availabilityId == null) return;
    final data = context.read<AppDataProvider>();
    final t = AppStrings.of(context, listen: false);
    final successMessage = t.text('Section added');

    final payload = await showMaterialSectionEditor(context);
    if (payload == null || !mounted) return;

    try {
      await data.createMaterialSection(
        availabilityId: availabilityId,
        title: payload.title,
        description: payload.description,
      );
      _showSnack(successMessage);
    } catch (_) {}
  }

  Future<void> _editSection(CourseMaterialSectionModel section) async {
    final t = AppStrings.of(context, listen: false);

    if (section.sectionId == 0) {
      _showSnack(
        t.text(
          'This default section can be edited after backend sections are enabled.',
        ),
      );
      return;
    }

    final data = context.read<AppDataProvider>();
    final successMessage = t.text('Section updated');
    final payload = await showMaterialSectionEditor(context, section: section);
    if (payload == null || !mounted) return;

    try {
      await data.updateMaterialSection(
        availabilityId: section.availabilityId,
        sectionId: section.sectionId,
        title: payload.title,
        description: payload.description,
      );
      _showSnack(successMessage);
    } catch (_) {}
  }

  Future<void> _deleteSection(CourseMaterialSectionModel section) async {
    final t = AppStrings.of(context, listen: false);

    if (section.sectionId == 0) {
      _showSnack(t.text('This default section cannot be deleted.'));
      return;
    }

    final data = context.read<AppDataProvider>();
    final successMessage = t.text('Section deleted');
    final confirmed = await _confirm(
      title: t.text('Delete section?'),
      message: t.deleteSectionMessage(section.title),
    );
    if (confirmed != true || !mounted) return;

    try {
      await data.deleteMaterialSection(
        availabilityId: section.availabilityId,
        sectionId: section.sectionId,
      );
      _showSnack(successMessage);
    } catch (_) {}
  }

  Future<void> _addMaterial(CourseMaterialSectionModel section) async {
    final availabilityId = selectedAvailabilityId;
    if (availabilityId == null) return;
    final data = context.read<AppDataProvider>();
    final t = AppStrings.of(context, listen: false);
    final successMessage = t.text('Material added');

    final payload = await showMaterialEditor(context);
    if (payload == null || !mounted) return;

    try {
      await data.createMaterialItem(
        availabilityId: availabilityId,
        sectionId: section.sectionId,
        title: payload.title,
        description: payload.description,
        linkUrl: payload.linkUrl,
        file: payload.file,
      );
      _showSnack(successMessage);
    } catch (_) {}
  }

  Future<void> _editMaterial(CourseMaterialItemModel item) async {
    final data = context.read<AppDataProvider>();
    final t = AppStrings.of(context, listen: false);
    final successMessage = t.text('Material updated');
    final sections = data.courseMaterials[item.availabilityId] ??
        <CourseMaterialSectionModel>[];
    final payload = await showMaterialEditor(
      context,
      item: item,
      sections: sections,
    );
    if (payload == null || !mounted) return;

    try {
      await data.updateMaterialItem(
        availabilityId: item.availabilityId,
        materialId: item.materialId,
        title: payload.title,
        description: payload.description,
        linkUrl: payload.linkUrl,
        file: payload.file,
        sectionId: payload.sectionId,
      );
      _showSnack(successMessage);
    } catch (_) {}
  }

  Future<void> _deleteMaterial(CourseMaterialItemModel item) async {
    final data = context.read<AppDataProvider>();
    final t = AppStrings.of(context, listen: false);
    final successMessage = t.text('Material deleted');
    final confirmed = await _confirm(
      title: t.text('Delete material?'),
      message: t.deleteMaterialMessage(item.title),
    );
    if (confirmed != true || !mounted) return;

    try {
      await data.deleteMaterialItem(
        availabilityId: item.availabilityId,
        materialId: item.materialId,
      );
      _showSnack(successMessage);
    } catch (_) {}
  }

  Future<void> _openMaterial(CourseMaterialItemModel item) async {
    final t = AppStrings.of(context, listen: false);
    final uri = materialUri(item);
    if (uri == null) {
      _showSnack(
        t.text('No file or link is available for this material.'),
      );
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

  int? _selectedOrDefaultCourseId(List<_MaterialCourse> courses) {
    if (courses.isEmpty) return null;
    if (selectedAvailabilityId != null &&
        courses
            .any((course) => course.availabilityId == selectedAvailabilityId)) {
      return selectedAvailabilityId;
    }
    return courses.first.availabilityId;
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
    final t = context.l10n;
    final courses = _coursesFor(data, auth);
    final selectedId = _selectedOrDefaultCourseId(courses);
    final sections = selectedId == null
        ? <CourseMaterialSectionModel>[]
        : (data.courseMaterials[selectedId] ?? <CourseMaterialSectionModel>[]);

    return Scaffold(
      backgroundColor: colors.surfaceContainerLowest,
      appBar: AppBar(
        title: Text(t.materials),
        backgroundColor: colors.surface,
        surfaceTintColor: Colors.transparent,
        actions: [
          IconButton.outlined(
            onPressed: data.loading ? null : _reload,
            tooltip: t.refresh,
            icon: const Icon(Icons.refresh_rounded, size: 20),
          ),
          if (auth.isTutor)
            Padding(
              padding: const EdgeInsets.only(right: 12, left: 8),
              child: FilledButton.icon(
                onPressed:
                    selectedId == null || data.loading ? null : _addSection,
                icon: const Icon(Icons.create_new_folder_outlined, size: 18),
                label: Text(t.section),
              ),
            )
          else
            const SizedBox(width: 12),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _reload,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            ErrorBanner(data.error),
            _MaterialsIntro(isTutor: auth.isTutor),
            const SizedBox(height: 12),
            _CourseDropdown(
              courses: courses,
              selectedAvailabilityId: selectedId,
              onChanged: _selectCourse,
            ),
            const SizedBox(height: 12),
            if (data.loading && !initialized)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 48),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (courses.isEmpty)
              _EmptyMaterialsState(
                icon: Icons.school_outlined,
                text: auth.isTutor
                    ? t.noMaterialCoursesTutor
                    : t.noMaterialCoursesLearner,
              )
            else if (data.loading && sections.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 48),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (sections.isEmpty)
              _EmptyMaterialsState(
                icon: Icons.folder_open_outlined,
                text: auth.isTutor
                    ? t.text('No material sections in this course yet.')
                    : t.text(
                        'No materials have been shared for this course yet.',
                      ),
              )
            else
              ...sections.asMap().entries.map(
                    (entry) => _MaterialSectionTile(
                      section: entry.value,
                      isTutor: auth.isTutor,
                      initiallyExpanded: entry.key == 0,
                      onAddMaterial: () => _addMaterial(entry.value),
                      onEditSection: () => _editSection(entry.value),
                      onDeleteSection: () => _deleteSection(entry.value),
                      onOpenMaterial: _openMaterial,
                      onEditMaterial: _editMaterial,
                      onDeleteMaterial: _deleteMaterial,
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}

class _MaterialsIntro extends StatelessWidget {
  final bool isTutor;

  const _MaterialsIntro({required this.isTutor});

  @override
  Widget build(BuildContext context) {
    return AppSurfaceCard(
      child: AppSectionHeader(
        icon: Icons.folder_copy_outlined,
        title: context.l10n.text(
          isTutor ? 'Manage course materials' : 'Course materials',
        ),
        subtitle: isTutor
            ? context.l10n.text(
                'Organize files and links by section for each class.',
              )
            : context.l10n.text(
                'Open shared files and links from your enrolled classes.',
              ),
      ),
    );
  }
}

class _CourseDropdown extends StatelessWidget {
  final List<_MaterialCourse> courses;
  final int? selectedAvailabilityId;
  final ValueChanged<int> onChanged;

  const _CourseDropdown({
    required this.courses,
    required this.selectedAvailabilityId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (courses.isEmpty) return const SizedBox.shrink();

    final colors = Theme.of(context).colorScheme;
    final selectedValue = courses.any(
      (course) => course.availabilityId == selectedAvailabilityId,
    )
        ? selectedAvailabilityId
        : courses.first.availabilityId;

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
          value: course.availabilityId,
          child: _CourseMenuItem(course: course),
        );
      }).toList(),
      onChanged: (value) {
        if (value != null && value != selectedAvailabilityId) {
          onChanged(value);
        }
      },
    );
  }
}

class _CourseMenuItem extends StatelessWidget {
  final _MaterialCourse course;

  const _CourseMenuItem({required this.course});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Row(
      children: [
        Icon(Icons.class_outlined, size: 20, color: colors.primary),
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
                course.subtitle,
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

class _MaterialSectionTile extends StatelessWidget {
  final CourseMaterialSectionModel section;
  final bool isTutor;
  final bool initiallyExpanded;
  final VoidCallback onAddMaterial;
  final VoidCallback onEditSection;
  final VoidCallback onDeleteSection;
  final ValueChanged<CourseMaterialItemModel> onOpenMaterial;
  final ValueChanged<CourseMaterialItemModel> onEditMaterial;
  final ValueChanged<CourseMaterialItemModel> onDeleteMaterial;

  const _MaterialSectionTile({
    required this.section,
    required this.isTutor,
    required this.initiallyExpanded,
    required this.onAddMaterial,
    required this.onEditSection,
    required this.onDeleteSection,
    required this.onOpenMaterial,
    required this.onEditMaterial,
    required this.onDeleteMaterial,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final l10n = context.l10n;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          key: PageStorageKey('material-section-${section.sectionId}'),
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
          leading: Icon(Icons.folder_outlined, color: colors.primary),
          title: Text(
            section.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          subtitle: Text(
            section.description?.trim().isNotEmpty == true
                ? section.description!
                : context.l10n.materialsN(section.items.length),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _CountBadge(count: section.items.length),
              if (isTutor)
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'add') onAddMaterial();
                    if (value == 'edit') onEditSection();
                    if (value == 'delete') onDeleteSection();
                  },
                  itemBuilder: (menuContext) => [
                    PopupMenuItem(
                      value: 'add',
                      child: Text(l10n.text('Add material')),
                    ),
                    PopupMenuItem(
                      value: 'edit',
                      child: Text(l10n.text('Edit section')),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Text(l10n.text('Delete section')),
                    ),
                  ],
                )
              else
                const SizedBox(width: 8),
              const Icon(Icons.expand_more_rounded),
            ],
          ),
          children: [
            if (isTutor)
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: OutlinedButton.icon(
                    onPressed: onAddMaterial,
                    icon: const Icon(Icons.upload_file_outlined, size: 18),
                    label: Text(context.l10n.text('Add material')),
                  ),
                ),
              ),
            if (section.items.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  context.l10n.text('No materials in this section yet.'),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              )
            else
              ...section.items.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: _MaterialItemCard(
                    item: item,
                    isTutor: isTutor,
                    onOpen: () => onOpenMaterial(item),
                    onEdit: () => onEditMaterial(item),
                    onDelete: () => onDeleteMaterial(item),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _MaterialItemCard extends StatelessWidget {
  final CourseMaterialItemModel item;
  final bool isTutor;
  final VoidCallback onOpen;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _MaterialItemCard({
    required this.item,
    required this.isTutor,
    required this.onOpen,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final l10n = context.l10n;

    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colors.outlineVariant.withValues(alpha: 0.5),
          width: 0.5,
        ),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          _MaterialTypeIcon(type: item.materialType),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (item.description?.trim().isNotEmpty == true) ...[
                  const SizedBox(height: 3),
                  Text(
                    item.description!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
                const SizedBox(height: 5),
                Text(
                  '${item.materialType} · ${DateFormat('dd/MM/yyyy').format(item.createdAt.toLocal())}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onSurface.withValues(alpha: 0.55),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: item.canOpen ? onOpen : null,
            tooltip: context.l10n.text('Open'),
            icon: const Icon(Icons.open_in_new_rounded),
          ),
          if (isTutor)
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') onEdit();
                if (value == 'delete') onDelete();
              },
              itemBuilder: (menuContext) => [
                PopupMenuItem(
                  value: 'edit',
                  child: Text(l10n.text('Edit')),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Text(l10n.text('Delete')),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _MaterialTypeIcon extends StatelessWidget {
  final String type;

  const _MaterialTypeIcon({required this.type});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final value = type.toLowerCase();
    final icon = value.contains('pdf')
        ? Icons.picture_as_pdf_outlined
        : value.contains('image')
            ? Icons.image_outlined
            : value.contains('video')
                ? Icons.play_circle_outline
                : value.contains('link')
                    ? Icons.link_rounded
                    : Icons.insert_drive_file_outlined;

    return CircleAvatar(
      radius: 20,
      backgroundColor: colors.secondaryContainer.withValues(alpha: 0.75),
      child: Icon(icon, color: colors.onSecondaryContainer, size: 21),
    );
  }
}

class _CountBadge extends StatelessWidget {
  final int count;

  const _CountBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      constraints: const BoxConstraints(minWidth: 30),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colors.primaryContainer.withValues(alpha: 0.65),
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

class _EmptyMaterialsState extends StatelessWidget {
  final IconData icon;
  final String text;

  const _EmptyMaterialsState({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: AppEmptyState(
        icon: icon,
        title: text,
        message: context.l10n.text('Select another class or check back later.'),
      ),
    );
  }
}

Future<MaterialSectionEditorResult?> showMaterialSectionEditor(
  BuildContext context, {
  CourseMaterialSectionModel? section,
}) {
  final t = AppStrings.of(context, listen: false);
  final title = TextEditingController(text: section?.title ?? '');
  final description = TextEditingController(text: section?.description ?? '');

  return showDialog<MaterialSectionEditorResult>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(
        t.text(section == null ? 'Add section' : 'Edit section'),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: title,
            decoration: InputDecoration(labelText: t.text('Title')),
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: description,
            decoration: InputDecoration(
              labelText: t.text('Description optional'),
            ),
            maxLines: 3,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(t.cancel),
        ),
        FilledButton(
          onPressed: () {
            if (title.text.trim().isEmpty) return;
            Navigator.pop(
              context,
              MaterialSectionEditorResult(
                title: title.text.trim(),
                description: _optionalText(description.text),
              ),
            );
          },
          child: Text(t.text('Save')),
        ),
      ],
    ),
  );
}

Future<MaterialEditorResult?> showMaterialEditor(
  BuildContext context, {
  CourseMaterialItemModel? item,
  List<CourseMaterialSectionModel> sections = const [],
}) {
  final t = AppStrings.of(context, listen: false);
  final title = TextEditingController(text: item?.title ?? '');
  final description = TextEditingController(text: item?.description ?? '');
  final link = TextEditingController(text: item?.fileUrl ?? '');
  PlatformFile? file;
  String? fileName;
  final editableSections =
      sections.where((section) => section.sectionId > 0).toList();
  int? selectedSectionId = item?.sectionId;
  if (selectedSectionId != null &&
      !editableSections
          .any((section) => section.sectionId == selectedSectionId)) {
    selectedSectionId = null;
  }
  selectedSectionId ??=
      editableSections.isEmpty ? null : editableSections.first.sectionId;

  return showDialog<MaterialEditorResult>(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text(
              t.text(item == null ? 'Add material' : 'Edit material'),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: title,
                    decoration: InputDecoration(
                      labelText: t.text('Title'),
                    ),
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: description,
                    decoration: InputDecoration(
                      labelText: t.text('Description optional'),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: link,
                    decoration: InputDecoration(
                      labelText: t.text('Link or existing file URL'),
                    ),
                    keyboardType: TextInputType.url,
                  ),
                  if (item != null && editableSections.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    DropdownButtonFormField<int>(
                      initialValue: selectedSectionId,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: t.section,
                        prefixIcon: const Icon(Icons.folder_outlined),
                      ),
                      items: editableSections.map((section) {
                        return DropdownMenuItem<int>(
                          value: section.sectionId,
                          child: Text(
                            section.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setDialogState(() => selectedSectionId = value);
                      },
                    ),
                  ],
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final result = await FilePicker.platform.pickFiles(
                        allowMultiple: false,
                        withData: true,
                        type: FileType.any,
                      );
                      final pickedFile = result?.files.single;
                      if (pickedFile == null) return;
                      if (pickedFile.size > _maxMaterialUploadBytes) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                t.text(
                                    'Material file must be 10MB or smaller.'),
                              ),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              margin: const EdgeInsets.all(16),
                            ),
                          );
                        }
                        return;
                      }
                      setDialogState(() {
                        file = pickedFile;
                        fileName = pickedFile.name;
                      });
                    },
                    icon: const Icon(Icons.attach_file_rounded, size: 18),
                    label: Text(fileName ?? t.text('Choose file')),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(t.cancel),
              ),
              FilledButton(
                onPressed: () {
                  final hasFile = file != null;
                  final hasLink = link.text.trim().isNotEmpty;
                  if (title.text.trim().isEmpty) return;
                  if (item == null && !hasFile && !hasLink) return;

                  Navigator.pop(
                    context,
                    MaterialEditorResult(
                      title: title.text.trim(),
                      description: _optionalText(description.text),
                      linkUrl: _optionalText(link.text),
                      file: file,
                      sectionId: item == null ? null : selectedSectionId,
                    ),
                  );
                },
                child: Text(t.text('Save')),
              ),
            ],
          );
        },
      );
    },
  );
}

class _MaterialCourse {
  final int availabilityId;
  final String label;
  final String subtitle;

  const _MaterialCourse({
    required this.availabilityId,
    required this.label,
    required this.subtitle,
  });
}

class MaterialSectionEditorResult {
  final String title;
  final String? description;

  const MaterialSectionEditorResult({
    required this.title,
    required this.description,
  });
}

class MaterialEditorResult {
  final String title;
  final String? description;
  final String? linkUrl;
  final PlatformFile? file;
  final int? sectionId;

  const MaterialEditorResult({
    required this.title,
    required this.description,
    required this.linkUrl,
    required this.file,
    required this.sectionId,
  });
}

List<_MaterialCourse> _coursesFor(AppDataProvider data, AuthProvider auth) {
  if (auth.isTutor && data.myAvailabilities.isNotEmpty) {
    return data.myAvailabilities.map((availability) {
      final subject = data.availabilitySubjectName(availability);
      final start = DateFormat('dd/MM/yyyy').format(
        availability.startCourseTime.toLocal(),
      );
      final end = DateFormat('dd/MM/yyyy').format(
        availability.endCourseTime.toLocal(),
      );

      return _MaterialCourse(
        availabilityId: availability.availabilityId,
        label: subject,
        subtitle: '$start - $end · ${availability.slot} lesson slots',
      );
    }).toList()
      ..sort((a, b) => a.label.compareTo(b.label));
  }

  final grouped = <int, List<LessonModel>>{};
  for (final lesson in data.lessons) {
    grouped.putIfAbsent(lesson.availabilityId, () => []).add(lesson);
  }

  return grouped.entries.map((entry) {
    final lessons = _uniqueLearnerCourseLessons(entry.value);
    final first = lessons.first;

    return _MaterialCourse(
      availabilityId: entry.key,
      label: _subjectName(first),
      subtitle:
          '${first.tutorName} · ${lessons.length} lesson${lessons.length == 1 ? '' : 's'}',
    );
  }).toList()
    ..sort((a, b) => a.label.compareTo(b.label));
}

List<LessonModel> _uniqueLearnerCourseLessons(List<LessonModel> lessons) {
  final uniqueBySchedule = <String, LessonModel>{};

  for (final lesson in lessons) {
    final key = lesson.scheduleTime.toUtc().toIso8601String();
    uniqueBySchedule.putIfAbsent(key, () => lesson);
  }

  return uniqueBySchedule.values.toList()
    ..sort((a, b) => a.scheduleTime.compareTo(b.scheduleTime));
}

String _subjectName(LessonModel lesson) {
  final name = lesson.subjectName;
  if (name != null && name.trim().isNotEmpty) return name.trim();
  return 'Subject #${lesson.subjectId ?? '-'}';
}

String? _optionalText(String value) {
  final text = value.trim();
  return text.isEmpty ? null : text;
}

Uri? materialUri(CourseMaterialItemModel item) {
  final value = item.fileUrl?.trim() ?? '';
  if (value.isEmpty) return null;

  final direct = Uri.tryParse(value);
  final backendBase = Uri.tryParse(ApiService.baseUrl);
  final isBackendUpload = value.startsWith('/uploads/') ||
      (direct != null &&
          backendBase != null &&
          direct.hasScheme &&
          direct.host == backendBase.host &&
          direct.path.startsWith('/uploads/'));

  if (item.materialId > 0 && isBackendUpload) {
    return Uri.tryParse(
      '${ApiService.baseUrl}/api/material/items/${item.materialId}/download',
    );
  }

  if (direct != null && direct.hasScheme) return direct;

  final path = item.materialId > 0
      ? '/api/material/items/${item.materialId}/download'
      : (value.startsWith('/') ? value : '/$value');
  return Uri.tryParse('${ApiService.baseUrl}$path');
}
