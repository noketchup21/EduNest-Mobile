import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/mvp_models.dart';
import '../../providers/app_data_provider.dart';
import '../../widgets/error_banner.dart';
import '../../widgets/money_text.dart';
import '../../widgets/user_avatar.dart';

class TutorDetailScreen extends StatefulWidget {
  final int tutorId;

  const TutorDetailScreen({
    super.key,
    required this.tutorId,
  });

  @override
  State<TutorDetailScreen> createState() => _TutorDetailScreenState();
}

class _TutorDetailScreenState extends State<TutorDetailScreen> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppDataProvider>().loadTutorDetail(widget.tutorId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final data = context.watch<AppDataProvider>();
    final tutor = data.selectedTutor?.tutorId == widget.tutorId
        ? data.selectedTutor
        : null;
    final courses = data.selectedTutorAvailabilities
        .where((course) => course.tutorId == widget.tutorId)
        .toList();
    final avatarUrl = courses.isEmpty ? null : courses.first.tutorAvatarUrl;
    final name = tutor?.name.trim().isNotEmpty == true
        ? tutor!.name.trim()
        : courses.isNotEmpty
            ? courses.first.tutorName
            : 'Tutor #${widget.tutorId}';
    final tutorUserId =
        courses.isNotEmpty ? courses.first.tutorUserId : tutor?.userId ?? 0;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLow,
      appBar: AppBar(
        title: const Text('Tutor Profile'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 2,
      ),
      body: RefreshIndicator(
        onRefresh: () =>
            context.read<AppDataProvider>().loadTutorDetail(widget.tutorId),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            ErrorBanner(data.error),
            if (data.loading && tutor == null && courses.isEmpty)
              const Padding(
                padding: EdgeInsets.all(48),
                child: Center(child: CircularProgressIndicator()),
              )
            else ...[
              _TutorHeroCard(
                tutor: tutor,
                name: name,
                avatarUrl: avatarUrl,
                courseCount: courses.length,
                onChat: tutorUserId <= 0
                    ? null
                    : () => _startChat(context, tutorUserId),
              ),
              const SizedBox(height: 14),
              _BioCard(bio: tutor?.bio ?? ''),
              const SizedBox(height: 18),
              Text(
                'Available courses',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 10),
              if (courses.isEmpty)
                const _EmptyCoursesCard()
              else
                ...courses.map(
                  (course) => _CourseCard(
                    availability: course,
                    onBook: () => _book(context, course),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _startChat(BuildContext context, int tutorUserId) async {
    try {
      final conversation =
          await context.read<AppDataProvider>().startConversation(tutorUserId);

      if (context.mounted) {
        context.push('/chat/${conversation.conversationId}');
      }
    } catch (_) {}
  }

  Future<void> _book(
    BuildContext context,
    AvailabilityModel availability,
  ) async {
    try {
      await context.read<AppDataProvider>().book(availability.availabilityId);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Enrolled in class successfully!')),
        );
        context.go('/bookings');
      }
    } catch (_) {}
  }
}

class _TutorHeroCard extends StatelessWidget {
  final TutorPublicModel? tutor;
  final String name;
  final String? avatarUrl;
  final int courseCount;
  final VoidCallback? onChat;

  const _TutorHeroCard({
    required this.tutor,
    required this.name,
    required this.avatarUrl,
    required this.courseCount,
    required this.onChat,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final rating = tutor?.rating ?? 0;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              UserAvatar(
                imageUrl: avatarUrl,
                name: name,
                radius: 36,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _InfoChip(
                          icon: Icons.verified_rounded,
                          label: tutor?.isVerified == true
                              ? 'Verified tutor'
                              : 'Tutor',
                        ),
                        _InfoChip(
                          icon: Icons.menu_book_rounded,
                          label: '$courseCount courses',
                        ),
                        _InfoChip(
                          icon: Icons.star_rounded,
                          label: rating > 0
                              ? rating.toStringAsFixed(1)
                              : 'New tutor',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: onChat,
                  icon: const Icon(Icons.chat_bubble_rounded),
                  label: const Text('Chat'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BioCard extends StatelessWidget {
  final String bio;

  const _BioCard({required this.bio});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final text = bio.trim().isEmpty
        ? 'This tutor has not added an introduction yet.'
        : bio.trim();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.45),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'About',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            text,
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.45),
          ),
        ],
      ),
    );
  }
}

class _CourseCard extends StatelessWidget {
  final AvailabilityModel availability;
  final VoidCallback onBook;

  const _CourseCard({
    required this.availability,
    required this.onBook,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final total = availability.totalCoursePrice > 0
        ? availability.totalCoursePrice
        : availability.pricePerSlot * availability.slot;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  _subjectName(context, availability),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              _ModePill(label: availability.mode),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              _InfoChip(
                icon: Icons.event_rounded,
                label: availability.dayOfWeek,
              ),
              _InfoChip(
                icon: Icons.schedule_rounded,
                label: '${availability.startTime} - ${availability.endTime}',
              ),
              _InfoChip(
                icon: Icons.layers_rounded,
                label: availability.level,
              ),
              _InfoChip(
                icon: Icons.list_alt_rounded,
                label: '${availability.slot} lessons',
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Full tuition package',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                    MoneyText(
                      total,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: colors.primary,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              FilledButton(
                onPressed: onBook,
                child: const Text('Enroll'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _subjectName(BuildContext context, AvailabilityModel availability) {
    final direct = availability.subjectName?.trim() ?? '';

    if (direct.isNotEmpty) {
      return direct;
    }

    return context
        .read<AppDataProvider>()
        .availabilitySubjectName(availability);
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: colors.onSurfaceVariant),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: colors.onSurfaceVariant,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ModePill extends StatelessWidget {
  final String label;

  const _ModePill({required this.label});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: colors.secondaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: colors.onSecondaryContainer,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _EmptyCoursesCard extends StatelessWidget {
  const _EmptyCoursesCard();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        'This tutor has no active courses right now.',
        style: TextStyle(color: colors.onSurfaceVariant),
        textAlign: TextAlign.center,
      ),
    );
  }
}
