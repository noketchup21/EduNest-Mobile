import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../providers/app_data_provider.dart';
import '../../utils/support_report_categories.dart';
import '../../widgets/error_banner.dart';

class CreateSupportReportScreen extends StatefulWidget {
  const CreateSupportReportScreen({super.key});

  @override
  State<CreateSupportReportScreen> createState() =>
      _CreateSupportReportScreenState();
}

class _CreateSupportReportScreenState extends State<CreateSupportReportScreen> {
  final formKey = GlobalKey<FormState>();

  final title = TextEditingController();
  final description = TextEditingController();
  final payoutId = TextEditingController();
  final bookingId = TextEditingController();
  final lessonId = TextEditingController();

  final picker = ImagePicker();
  final proofPaths = <String>[];

  String category = tutorSupportCategories.first;

  @override
  void dispose() {
    title.dispose();
    description.dispose();
    payoutId.dispose();
    bookingId.dispose();
    lessonId.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = context.watch<AppDataProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Report Issue to Admin',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Form(
        key: formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            ErrorBanner(data.error),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Use this form for tutor problems such as missing payment, slow payout, wrong wallet balance, student no-show, booking issue, or app bug.',
                  style: TextStyle(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: category,
              decoration: const InputDecoration(
                labelText: 'Issue category',
                prefixIcon: Icon(Icons.category_outlined),
              ),
              items: [
                for (final item in tutorSupportCategories)
                  DropdownMenuItem(
                    value: item,
                    child: Text(supportCategoryLabel(item)),
                  ),
              ],
              onChanged: (value) {
                if (value == null) return;
                setState(() => category = value);
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: title,
              decoration: const InputDecoration(
                labelText: 'Title',
                hintText: 'Example: My completed lesson was not paid',
                prefixIcon: Icon(Icons.title_outlined),
              ),
              validator: _required,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: description,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'Describe the problem clearly for admin',
                prefixIcon: Icon(Icons.description_outlined),
              ),
              minLines: 4,
              maxLines: 7,
              validator: _required,
            ),
            const SizedBox(height: 16),
            Text(
              'Related IDs optional',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: payoutId,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Payout ID optional',
                prefixIcon: Icon(Icons.payments_outlined),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: bookingId,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Booking ID optional',
                prefixIcon: Icon(Icons.receipt_long_outlined),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: lessonId,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Lesson ID optional',
                prefixIcon: Icon(Icons.menu_book_outlined),
              ),
            ),
            const SizedBox(height: 20),
            _ProofPicker(
              proofPaths: proofPaths,
              onPick: _pickImages,
              onRemove: (index) {
                setState(() => proofPaths.removeAt(index));
              },
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 50,
              child: FilledButton.icon(
                onPressed: data.loading ? null : _submit,
                icon: data.loading
                    ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
                    : const Icon(Icons.send_outlined),
                label: const Text(
                  'Submit to Admin',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImages() async {
    try {
      if (proofPaths.length >= 5) {
        _snack('Maximum 5 proof images allowed');
        return;
      }

      final files = await picker.pickMultiImage(
        imageQuality: 80,
        maxWidth: 1600,
      );

      if (files.isEmpty) return;

      setState(() {
        for (final file in files) {
          if (proofPaths.length < 5) {
            proofPaths.add(file.path);
          }
        }
      });
    } catch (e) {
      _snack('Could not pick images: $e');
    }
  }

  Future<void> _submit() async {
    if (!formKey.currentState!.validate()) return;

    try {
      await context.read<AppDataProvider>().createSupportReport(
        category: category,
        title: title.text.trim(),
        description: description.text.trim(),
        payoutId: _optionalInt(payoutId.text),
        bookingId: _optionalInt(bookingId.text),
        lessonId: _optionalInt(lessonId.text),
        proofImagePaths: proofPaths,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Issue report submitted')),
      );

      context.go('/support-reports/me');
    } catch (_) {}
  }

  int? _optionalInt(String value) {
    final text = value.trim();
    if (text.isEmpty) return null;
    return int.tryParse(text);
  }

  void _snack(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}

class _ProofPicker extends StatelessWidget {
  final List<String> proofPaths;
  final VoidCallback onPick;
  final ValueChanged<int> onRemove;

  const _ProofPicker({
    required this.proofPaths,
    required this.onPick,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Proof images optional',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Upload screenshots of wallet, payout, booking, lesson, or app errors.',
              style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onPick,
              icon: const Icon(Icons.image_outlined),
              label: const Text('Add proof images'),
            ),
            if (proofPaths.isNotEmpty) ...[
              const SizedBox(height: 12),
              SizedBox(
                height: 88,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: proofPaths.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final path = proofPaths[index];

                    return Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            File(path),
                            width: 88,
                            height: 88,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: InkWell(
                            onTap: () => onRemove(index),
                            child: const CircleAvatar(
                              radius: 12,
                              child: Icon(Icons.close, size: 16),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

String? _required(String? value) {
  if (value == null || value.trim().isEmpty) {
    return 'This field is required';
  }

  return null;
}