import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_strings.dart';
import '../../models/mvp_models.dart';
import '../../providers/app_data_provider.dart';
import '../../widgets/app_ui.dart';
import '../../widgets/error_banner.dart';

class TeachingPreparationGuideScreen extends StatefulWidget {
  final int? initialSubjectId;

  const TeachingPreparationGuideScreen({
    super.key,
    this.initialSubjectId,
  });

  @override
  State<TeachingPreparationGuideScreen> createState() =>
      _TeachingPreparationGuideScreenState();
}

class _TeachingPreparationGuideScreenState
    extends State<TeachingPreparationGuideScreen> {
  final _formKey = GlobalKey<FormState>();
  final _lessonFocus = TextEditingController();

  int? _subjectId;

  @override
  void initState() {
    super.initState();
    _subjectId = widget.initialSubjectId;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final data = context.read<AppDataProvider>();
      if (data.subjects.isEmpty) data.loadSubjects();
    });
  }

  @override
  void dispose() {
    _lessonFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = context.watch<AppDataProvider>();
    final guide = data.teachingPreparationGuide;
    final t = context.l10n;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          t.text('Teaching preparation guide'),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            ErrorBanner(data.error),
            AppSurfaceCard(
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AppSectionHeader(
                      icon: Icons.auto_awesome_outlined,
                      title: t.text('Prepare before you create slides'),
                      subtitle: t.text(
                        'Use the subject objectives set by admin to see the concepts, examples, misconceptions, and preparation you should cover.',
                      ),
                    ),
                    const SizedBox(height: 20),
                    DropdownButtonFormField<int>(
                      initialValue: _subjectId,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: t.text('Base subject'),
                        border: const OutlineInputBorder(),
                      ),
                      items: data.subjects
                          .map(
                            (subject) => DropdownMenuItem(
                              value: subject.subjectId,
                              child: Text(
                                subject.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (value) => setState(() => _subjectId = value),
                      validator: (value) => value == null
                          ? t.text('Please choose a subject')
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _lessonFocus,
                      decoration: InputDecoration(
                        labelText: t.text('Lesson focus optional'),
                        hintText: t.text('Example: Variables and input/output'),
                        border: const OutlineInputBorder(),
                      ),
                      minLines: 1,
                      maxLines: 2,
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: data.loading ? null : _generate,
                        child: data.loading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                t.text('Create preparation guide'),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (guide != null) ...[
              const SizedBox(height: 16),
              _GuideContent(guide: guide),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _generate() async {
    if (!_formKey.currentState!.validate() || _subjectId == null) return;

    await context.read<AppDataProvider>().generateTeachingPreparationGuide(
          subjectId: _subjectId!,
          lessonFocus: _lessonFocus.text.trim(),
        );
  }
}

class _GuideContent extends StatelessWidget {
  final TeachingPreparationGuideModel guide;

  const _GuideContent({required this.guide});

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppSurfaceCard(
          color: Theme.of(context).colorScheme.primaryContainer,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                guide.subjectName,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (guide.lessonFocus.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  '${t.text('Focus')}: ${guide.lessonFocus}',
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              if (guide.objective.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  t.text('Admin objective'),
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(guide.objective),
              ],
            ],
          ),
        ),
        for (final section in guide.sections) ...[
          const SizedBox(height: 12),
          AppSurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.text(section.title),
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                for (final item in section.items)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 7),
                          child: Icon(Icons.circle, size: 7),
                        ),
                        const SizedBox(width: 9),
                        Expanded(child: Text(item)),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
