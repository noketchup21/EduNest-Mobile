import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_data_provider.dart';

Future<bool?> showTutorReviewSheet({
  required BuildContext context,
  required int bookingId,
  required int tutorId,
  required String tutorName,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (sheetContext) {
      return _TutorReviewSheet(
        bookingId: bookingId,
        tutorId: tutorId,
        tutorName: tutorName,
      );
    },
  );
}

class _TutorReviewSheet extends StatefulWidget {
  final int bookingId;
  final int tutorId;
  final String tutorName;

  const _TutorReviewSheet({
    required this.bookingId,
    required this.tutorId,
    required this.tutorName,
  });

  @override
  State<_TutorReviewSheet> createState() => _TutorReviewSheetState();
}

class _TutorReviewSheetState extends State<_TutorReviewSheet> {
  final comment = TextEditingController();
  int rating = 5;

  @override
  void dispose() {
    comment.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    try {
      await context.read<AppDataProvider>().createTutorReview(
            bookingId: widget.bookingId,
            tutorId: widget.tutorId,
            rating: rating,
            comment: comment.text.trim(),
          );

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final data = context.watch<AppDataProvider>();
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    final tutorName = widget.tutorName.trim().isEmpty
        ? 'Tutor #${widget.tutorId}'
        : widget.tutorName.trim();

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 14, 20, 20 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 5,
              decoration: BoxDecoration(
                color: colors.outlineVariant,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Review $tutorName',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Booking #${widget.bookingId}',
            style: TextStyle(color: colors.onSurfaceVariant),
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              5,
              (index) {
                final value = index + 1;
                return IconButton(
                  onPressed: data.loading
                      ? null
                      : () {
                          setState(() {
                            rating = value;
                          });
                        },
                  icon: Icon(
                    value <= rating
                        ? Icons.star_rounded
                        : Icons.star_border_rounded,
                    size: 34,
                    color: Colors.amber.shade700,
                  ),
                  tooltip: '$value star',
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: comment,
            minLines: 3,
            maxLines: 5,
            textInputAction: TextInputAction.newline,
            decoration: InputDecoration(
              labelText: 'Comment',
              hintText: 'Share what worked well or what could improve',
              alignLabelWithHint: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed:
                      data.loading ? null : () => Navigator.pop(context, false),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: data.loading ? null : _submit,
                  icon: data.loading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.rate_review_rounded),
                  label: Text(data.loading ? 'Sending...' : 'Submit'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(0, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
