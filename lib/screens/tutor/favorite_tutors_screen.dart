import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/mvp_models.dart';
import '../../providers/app_data_provider.dart';
import '../../widgets/error_banner.dart';
import '../../widgets/user_avatar.dart';

class FavoriteTutorsScreen extends StatefulWidget {
  const FavoriteTutorsScreen({super.key});

  @override
  State<FavoriteTutorsScreen> createState() => _FavoriteTutorsScreenState();
}

class _FavoriteTutorsScreenState extends State<FavoriteTutorsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppDataProvider>().loadFavoriteTutors();
    });
  }

  @override
  Widget build(BuildContext context) {
    final data = context.watch<AppDataProvider>();
    final favorites = data.favoriteTutors;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      backgroundColor: colors.surfaceContainerLow,
      appBar: AppBar(
        title: const Text('Favorite Tutors'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 2,
        actions: [
          IconButton(
            onPressed: data.loading ? null : data.loadFavoriteTutors,
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: data.loadFavoriteTutors,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
          children: [
            ErrorBanner(data.error),
            if (data.loading && favorites.isEmpty)
              const Padding(
                padding: EdgeInsets.all(48),
                child: Center(child: CircularProgressIndicator()),
              ),
            if (!data.loading && favorites.isEmpty)
              Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.favorite_border_rounded,
                      size: 44,
                      color: colors.onSurfaceVariant,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No favorite tutors yet',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Tap the heart on a tutor profile to save it here.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: colors.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ...favorites.map(
              (favorite) => _FavoriteTutorTile(favorite: favorite),
            ),
          ],
        ),
      ),
    );
  }
}

class _FavoriteTutorTile extends StatelessWidget {
  final FavoriteTutorModel favorite;

  const _FavoriteTutorTile({required this.favorite});

  @override
  Widget build(BuildContext context) {
    final data = context.watch<AppDataProvider>();
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final displayName = favorite.name.trim().isNotEmpty
        ? favorite.name.trim()
        : 'Tutor #${favorite.tutorId}';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: colors.outlineVariant.withValues(alpha: 0.45),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        leading: UserAvatar(
          imageUrl: favorite.avatarUrl,
          name: displayName,
          radius: 24,
        ),
        title: Text(
          displayName,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        subtitle: Text(
          favorite.rating > 0
              ? '${favorite.rating.toStringAsFixed(1)} rating'
              : favorite.isVerified
                  ? 'Verified tutor'
                  : 'Saved tutor',
          style: TextStyle(color: colors.onSurfaceVariant),
        ),
        onTap: () => context.push('/tutors/${favorite.tutorId}'),
        trailing: IconButton(
          onPressed: data.loading
              ? null
              : () => context.read<AppDataProvider>().toggleFavoriteTutor(
                    tutorId: favorite.tutorId,
                    name: displayName,
                    userId: favorite.userId,
                    avatarUrl: favorite.avatarUrl,
                  ),
          icon: const Icon(Icons.favorite_rounded),
          color: colors.error,
          tooltip: 'Remove favorite',
        ),
      ),
    );
  }
}
