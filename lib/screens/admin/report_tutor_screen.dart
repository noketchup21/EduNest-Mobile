// report_tutor_screen.dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_strings.dart';
import '../../providers/app_data_provider.dart';
import '../../widgets/error_banner.dart';

const double _cardRadius = 22;

class ReportTutorScreen extends StatefulWidget {
  final int bookingId;
  final int? lessonId;

  const ReportTutorScreen({
    super.key,
    required this.bookingId,
    this.lessonId,
  });

  @override
  State<ReportTutorScreen> createState() => _ReportTutorScreenState();
}

class _ReportTutorScreenState extends State<ReportTutorScreen> {
  final _formKey = GlobalKey<FormState>();

  final _title = TextEditingController();
  final _description = TextEditingController();

  final _picker = ImagePicker();

  String _category = 'Inappropriate behavior';
  final List<String> _proofPaths = [];

  final categories = const [
    'Inappropriate behavior',
    'Did not attend lesson',
    'Poor teaching quality',
    'Wrong information',
    'Payment or booking issue',
    'Other',
  ];

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = context.watch<AppDataProvider>();
    final colors = Theme.of(context).colorScheme;
    final t = context.l10n;

    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        title: Text(
          t.text('Report tutor'),
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: colors.surface,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            ErrorBanner(data.error),
            _ReportHeroCard(
              bookingId: widget.bookingId,
              lessonId: widget.lessonId,
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 0,
              color: colors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(_cardRadius),
                side: BorderSide(color: colors.outlineVariant),
              ),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _SectionHeader(
                        icon: Icons.assignment_outlined,
                        title: t.text('Report details'),
                        subtitle: t.text(
                          'Describe the problem clearly so admin can review it faster.',
                        ),
                      ),
                      const SizedBox(height: 18),
                      DropdownButtonFormField<String>(
                        value: _category,
                        isExpanded: true,
                        borderRadius: BorderRadius.circular(18),
                        decoration: _inputDecoration(
                          context,
                          label: t.text('Category'),
                          icon: Icons.category_outlined,
                        ),
                        items: categories
                            .map(
                              (x) => DropdownMenuItem(
                                value: x,
                                child: Text(
                                  t.text(x),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            )
                            .toList(),
                        selectedItemBuilder: (context) {
                          return categories.map((x) {
                            return Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                t.text(x),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList();
                        },
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() => _category = value);
                        },
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _title,
                        decoration: _inputDecoration(
                          context,
                          label: t.text('Title'),
                          icon: Icons.title,
                          hintText: t.text('Brief summary of the issue'),
                        ),
                        validator: _required,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _description,
                        decoration: _inputDecoration(
                          context,
                          label: t.text('Description'),
                          icon: Icons.description_outlined,
                          hintText: t.text(
                            'Explain what happened and include important details',
                          ),
                        ).copyWith(alignLabelWithHint: true),
                        minLines: 4,
                        maxLines: 8,
                        validator: _required,
                      ),
                      const SizedBox(height: 22),
                      _ProofPicker(
                        paths: _proofPaths,
                        onAdd: _pickProofImages,
                        onRemove: (path) {
                          setState(() => _proofPaths.remove(path));
                        },
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        height: 52,
                        child: FilledButton.icon(
                          onPressed: data.loading ? null : _submit,
                          style: FilledButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          icon: data.loading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.report_outlined),
                          label: Text(
                            t.text(data.loading
                                ? 'Submitting...'
                                : 'Submit report'),
                            style: const TextStyle(fontWeight: FontWeight.w900),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String? _required(String? value) {
    if (value == null || value.trim().isEmpty) {
      return AppStrings.of(context, listen: false).thisFieldRequired;
    }

    return null;
  }

  Future<void> _pickProofImages() async {
    if (_proofPaths.length >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppStrings.of(context, listen: false)
              .text('Maximum 5 proof images allowed')),
        ),
      );
      return;
    }

    final files = await _picker.pickMultiImage(
      imageQuality: 80,
      maxWidth: 1600,
    );

    if (files.isEmpty) return;

    setState(() {
      for (final file in files) {
        if (_proofPaths.length < 5) {
          _proofPaths.add(file.path);
        }
      }
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_proofPaths.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppStrings.of(context, listen: false)
                .text('Please upload at least one proof image'),
          ),
        ),
      );
      return;
    }

    try {
      await context.read<AppDataProvider>().createTutorReport(
            bookingId: widget.bookingId,
            lessonId: widget.lessonId,
            category: _category,
            title: _title.text.trim(),
            description: _description.text.trim(),
            proofImagePaths: _proofPaths,
          );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(AppStrings.of(context, listen: false)
                .text('Report submitted'))),
      );

      context.pop();
    } catch (_) {}
  }
}

class _ReportHeroCard extends StatelessWidget {
  final int bookingId;
  final int? lessonId;

  const _ReportHeroCard({
    required this.bookingId,
    required this.lessonId,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colors.primaryContainer.withOpacity(0.82),
            colors.secondaryContainer.withOpacity(0.55),
          ],
        ),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SoftIcon(
            icon: Icons.shield_outlined,
            size: 54,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.text('Submit a tutor report'),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  context.l10n.text(
                    'Your report will be reviewed by the admin team with the proof images you provide.',
                  ),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                        height: 1.35,
                      ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _MetaBadge(
                      icon: Icons.event_note_outlined,
                      label: context.l10n.bookingNumber(bookingId),
                    ),
                    if (lessonId != null)
                      _MetaBadge(
                        icon: Icons.menu_book_outlined,
                        label: '${context.l10n.lesson} #$lessonId',
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

class _MetaBadge extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MetaBadge({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: colors.surface.withOpacity(0.78),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: colors.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: colors.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SoftIcon(icon: icon),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                      height: 1.35,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProofPicker extends StatelessWidget {
  final List<String> paths;
  final VoidCallback onAdd;
  final ValueChanged<String> onRemove;

  const _ProofPicker({
    required this.paths,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _SectionHeader(
                icon: Icons.image_outlined,
                title: context.l10n.text('Proof images'),
                subtitle: context.l10n.text(
                  'Upload at least one image. Maximum 5 images.',
                ),
              ),
            ),
            const SizedBox(width: 8),
            FilledButton.tonalIcon(
              onPressed: onAdd,
              icon: const Icon(Icons.add_photo_alternate_outlined, size: 18),
              label: Text('${paths.length}/5'),
            ),
          ],
        ),
        const SizedBox(height: 14),
        if (paths.isEmpty)
          InkWell(
            onTap: onAdd,
            borderRadius: BorderRadius.circular(18),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              decoration: BoxDecoration(
                color: colors.surfaceVariant.withOpacity(0.22),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: colors.outlineVariant),
              ),
              child: Column(
                children: [
                  _SoftIcon(
                    icon: Icons.cloud_upload_outlined,
                    size: 50,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    context.l10n.text('No proof images selected'),
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    context.l10n
                        .text('Tap to add image proof for admin review.'),
                    textAlign: TextAlign.center,
                    style: TextStyle(color: colors.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          )
        else
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: paths.map((path) {
              return _ProofImageTile(
                path: path,
                onRemove: () => onRemove(path),
              );
            }).toList(),
          ),
      ],
    );
  }
}

class _ProofImageTile extends StatelessWidget {
  final String path;
  final VoidCallback onRemove;

  const _ProofImageTile({
    required this.path,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      width: 104,
      height: 104,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(17),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.file(
              File(path),
              fit: BoxFit.cover,
            ),
            Positioned(
              right: 6,
              top: 6,
              child: InkWell(
                onTap: onRemove,
                borderRadius: BorderRadius.circular(999),
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: colors.surface.withOpacity(0.92),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.12),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.close,
                    size: 16,
                    color: colors.error,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SoftIcon extends StatelessWidget {
  final IconData icon;
  final Color? color;
  final double size;

  const _SoftIcon({
    required this.icon,
    this.color,
    this.size = 42,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final accent = color ?? colors.primary;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: accent.withOpacity(0.12),
        borderRadius: BorderRadius.circular(size * 0.34),
      ),
      child: Icon(icon, color: accent, size: size * 0.52),
    );
  }
}

InputDecoration _inputDecoration(
  BuildContext context, {
  required String label,
  required IconData icon,
  String? hintText,
}) {
  final colors = Theme.of(context).colorScheme;

  return InputDecoration(
    labelText: label,
    hintText: hintText,
    prefixIcon: Icon(icon),
    filled: true,
    fillColor: colors.surfaceVariant.withOpacity(0.22),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: colors.outlineVariant),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: colors.outlineVariant),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: colors.primary, width: 1.6),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: colors.error),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: colors.error, width: 1.6),
    ),
  );
}
