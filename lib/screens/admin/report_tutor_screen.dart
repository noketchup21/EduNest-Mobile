import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../providers/app_data_provider.dart';
import '../../widgets/error_banner.dart';

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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Report tutor'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            ErrorBanner(data.error),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      DropdownButtonFormField<String>(
                        value: _category,
                        decoration: const InputDecoration(
                          labelText: 'Category',
                          prefixIcon: Icon(Icons.category_outlined),
                        ),
                        items: categories
                            .map(
                              (x) => DropdownMenuItem(
                            value: x,
                            child: Text(x),
                          ),
                        )
                            .toList(),
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() => _category = value);
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _title,
                        decoration: const InputDecoration(
                          labelText: 'Title',
                          prefixIcon: Icon(Icons.title),
                        ),
                        validator: _required,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _description,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                          alignLabelWithHint: true,
                          prefixIcon: Icon(Icons.description_outlined),
                        ),
                        minLines: 4,
                        maxLines: 8,
                        validator: _required,
                      ),
                      const SizedBox(height: 16),
                      _ProofPicker(
                        paths: _proofPaths,
                        onAdd: _pickProofImages,
                        onRemove: (path) {
                          setState(() => _proofPaths.remove(path));
                        },
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: data.loading ? null : _submit,
                          icon: data.loading
                              ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                              : const Icon(Icons.report_outlined),
                          label: Text(data.loading ? 'Submitting...' : 'Submit report'),
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
      return 'This field is required';
    }

    return null;
  }

  Future<void> _pickProofImages() async {
    if (_proofPaths.length >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maximum 5 proof images allowed')),
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
        const SnackBar(content: Text('Please upload at least one proof image')),
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
        const SnackBar(content: Text('Report submitted')),
      );

      context.pop();
    } catch (_) {}
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Proof images',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
            TextButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add_photo_alternate_outlined),
              label: const Text('Add'),
            ),
          ],
        ),
        if (paths.isEmpty)
          const Card(
            child: ListTile(
              leading: Icon(Icons.image_outlined),
              title: Text('No proof images selected'),
              subtitle: Text('At least one proof image is required.'),
            ),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: paths.map((path) {
              return Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      File(path),
                      width: 96,
                      height: 96,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    right: 2,
                    top: 2,
                    child: IconButton.filledTonal(
                      onPressed: () => onRemove(path),
                      icon: const Icon(Icons.close, size: 16),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
      ],
    );
  }
}