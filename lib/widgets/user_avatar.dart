import 'package:flutter/material.dart';

class UserAvatar extends StatelessWidget {
  final String? imageUrl;
  final String name;
  final double radius;

  const UserAvatar({
    super.key,
    required this.imageUrl,
    required this.name,
    this.radius = 22,
  });

  @override
  Widget build(BuildContext context) {
    final url = imageUrl?.trim() ?? '';
    final hasImage = url.isNotEmpty;
    final theme = Theme.of(context);

    return CircleAvatar(
      radius: radius,
      backgroundColor: theme.colorScheme.primaryContainer,
      backgroundImage: hasImage ? NetworkImage(url) : null,
      child: hasImage
          ? null
          : Text(
              name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase(),
              style: TextStyle(
                color: theme.colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.w900,
              ),
            ),
    );
  }
}
