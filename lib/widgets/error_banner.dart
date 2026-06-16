import 'package:flutter/material.dart';

class ErrorBanner extends StatelessWidget {
  final String? message;
  const ErrorBanner(this.message, {super.key});

  @override
  Widget build(BuildContext context) {
    if (message == null || message!.isEmpty) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(message!,
          style:
              TextStyle(color: Theme.of(context).colorScheme.onErrorContainer)),
    );
  }
}
