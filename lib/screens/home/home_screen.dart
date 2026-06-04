import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/mvp_models.dart';
import '../../providers/app_data_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/error_banner.dart';
import '../../widgets/money_text.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _reload();
    });
  }

  Future<void> _reload() async {
    final auth = context.read<AuthProvider>();
    final data = context.read<AppDataProvider>();

    if (auth.isTutor && !auth.isAdmin) {
      await data.loadMyAvailability();
    } else {
      await data.loadHome();
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = context.watch<AppDataProvider>();
    final auth = context.watch<AuthProvider>();

    final isTutor = auth.isTutor && !auth.isAdmin;

    return Scaffold(
      appBar: AppBar(
        title: Text(isTutor ? 'My courses' : 'Available tutors'),
        actions: [
          if (isTutor)
            IconButton(
              onPressed: () => context.push('/availability/create'),
              icon: const Icon(Icons.add_circle_outline),
              tooltip: 'Create course',
            ),
          IconButton(
            onPressed: data.loading ? null : _reload,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _reload,
        child: isTutor
            ? _TutorCourseList(data: data)
            : _LearnerTutorList(data: data),
      ),
    );
  }
}

class _TutorCourseList extends StatelessWidget {
  final AppDataProvider data;

  const _TutorCourseList({
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    final courses = data.myAvailabilities;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ErrorBanner(data.error),

        if (data.loading && courses.isEmpty)
          const Padding(
            padding: EdgeInsets.all(32),
            child: Center(child: CircularProgressIndicator()),
          ),

        if (!data.loading && courses.isEmpty)
          const Card(
            child: ListTile(
              leading: Icon(Icons.menu_book_outlined),
              title: Text('No courses yet'),
              subtitle: Text('Create your first course using the + button.'),
            ),
          ),

        ...courses.map((availability) {
          return _TutorCourseCard(availability: availability);
        }),
      ],
    );
  }
}

class _TutorCourseCard extends StatelessWidget {
  final AvailabilityModel availability;

  const _TutorCourseCard({
    required this.availability,
  });

  @override
  Widget build(BuildContext context) {
    final data = context.watch<AppDataProvider>();

    final status = availability.status.toLowerCase();
    final isActive = status == 'active';
    final total = availability.totalCoursePrice > 0
        ? availability.totalCoursePrice
        : availability.pricePerSlot * availability.slot;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    _subjectText(context, availability),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Chip(
                  label: Text(availability.status),
                  avatar: Icon(
                    isActive ? Icons.check_circle : Icons.pause_circle,
                    size: 16,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            Text(
              '${availability.dayOfWeek} • '
                  '${availability.startTime} - ${availability.endTime}',
            ),
            Text('${availability.mode} • ${availability.level}'),
            Text('Lessons: ${availability.slot}'),
            Text(
              availability.hasBookings
                  ? 'Booking status: Already booked'
                  : 'Booking status: No booking yet',
            ),

            const SizedBox(height: 8),

            Row(
              children: [
                Expanded(
                  child: MoneyText(total),
                ),
                const SizedBox(width: 8),
                FilledButton.tonalIcon(
                  onPressed: data.loading || availability.hasBookings
                      ? null
                      : () => _toggleStatus(context, availability),
                  icon: Icon(
                    isActive
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                  ),
                  label: Text(isActive ? 'Disable' : 'Enable'),
                ),
              ],
            ),

            if (availability.hasBookings) ...[
              const SizedBox(height: 8),
              Text(
                'Booked courses cannot be enabled/disabled.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _toggleStatus(
      BuildContext context,
      AvailabilityModel availability,
      ) async {
    final isActive = availability.status.toLowerCase() == 'active';
    final newStatus = isActive ? 'Inactive' : 'Active';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text('${isActive ? 'Disable' : 'Enable'} course?'),
          content: Text(
            isActive
                ? 'This course will no longer be visible to parent/student users.'
                : 'This course will become visible to parent/student users.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(isActive ? 'Disable' : 'Enable'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !context.mounted) return;

    try {
      await context.read<AppDataProvider>().toggleAvailabilityStatus(
        availabilityId: availability.availabilityId,
        status: newStatus,
      );

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Course set to $newStatus')),
      );
    } catch (_) {
      // ErrorBanner will show data.error.
    }
  }
}

class _LearnerTutorList extends StatelessWidget {
  final AppDataProvider data;

  const _LearnerTutorList({
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    final groups = _groupByTutor(data.availabilities);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ErrorBanner(data.error),

        if (data.loading && data.availabilities.isEmpty)
          const Padding(
            padding: EdgeInsets.all(32),
            child: Center(child: CircularProgressIndicator()),
          ),

        if (!data.loading && data.availabilities.isEmpty)
          const Card(
            child: ListTile(
              leading: Icon(Icons.school_outlined),
              title: Text('No available tutors'),
              subtitle: Text('Please check again later.'),
            ),
          ),

        ...groups.values.map((courses) {
          return _TutorGroupCard(courses: courses);
        }),
      ],
    );
  }

  Map<int, List<AvailabilityModel>> _groupByTutor(
      List<AvailabilityModel> availabilities,
      ) {
    final result = <int, List<AvailabilityModel>>{};

    for (final availability in availabilities) {
      result.putIfAbsent(availability.tutorId, () => []);
      result[availability.tutorId]!.add(availability);
    }

    return result;
  }
}

class _TutorGroupCard extends StatelessWidget {
  final List<AvailabilityModel> courses;

  const _TutorGroupCard({
    required this.courses,
  });

  @override
  Widget build(BuildContext context) {
    final first = courses.first;
    final tutorName = first.tutorName.isEmpty
        ? 'Tutor #${first.tutorId}'
        : first.tutorName;

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: ExpansionTile(
        initiallyExpanded: true,
        leading: CircleAvatar(
          child: Text(
            tutorName.isEmpty ? '?' : tutorName[0].toUpperCase(),
          ),
        ),
        title: Text(
          tutorName,
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        subtitle: Text('${courses.length} available course(s)'),
        trailing: OutlinedButton.icon(
          onPressed: first.tutorUserId <= 0
              ? null
              : () => _startChat(context, first.tutorUserId),
          icon: const Icon(Icons.chat_bubble_outline),
          label: const Text('Chat'),
        ),
        children: courses.map((availability) {
          return _LearnerCourseTile(availability: availability);
        }).toList(),
      ),
    );
  }

  Future<void> _startChat(BuildContext context, int tutorUserId) async {
    try {
      final conversation = await context
          .read<AppDataProvider>()
          .startConversation(tutorUserId);

      if (!context.mounted) return;

      context.push('/chat/${conversation.conversationId}');
    } catch (_) {
      // ErrorBanner will show data.error.
    }
  }
}

class _LearnerCourseTile extends StatelessWidget {
  final AvailabilityModel availability;

  const _LearnerCourseTile({
    required this.availability,
  });

  @override
  Widget build(BuildContext context) {
    final data = context.watch<AppDataProvider>();

    final total = availability.totalCoursePrice > 0
        ? availability.totalCoursePrice
        : availability.pricePerSlot * availability.slot;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _subjectText(context, availability),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),

              const SizedBox(height: 6),

              Text(
                '${availability.dayOfWeek} • '
                    '${availability.startTime} - ${availability.endTime}',
              ),
              Text('${availability.mode} • ${availability.level}'),
              Text('Lessons: ${availability.slot}'),

              const SizedBox(height: 10),

              Row(
                children: [
                  Expanded(
                    child: MoneyText(total),
                  ),
                  FilledButton.icon(
                    onPressed: data.loading
                        ? null
                        : () => _book(context, availability),
                    icon: const Icon(Icons.shopping_bag_outlined),
                    label: const Text('Book'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _book(
      BuildContext context,
      AvailabilityModel availability,
      ) async {
    try {
      final booking = await context.read<AppDataProvider>().book(
        availability.availabilityId,
      );

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Booking #${booking.bookingId} created'),
        ),
      );

      context.go('/bookings');
    } catch (_) {
      // ErrorBanner will show data.error.
    }
  }
}

String _subjectText(
    BuildContext context,
    AvailabilityModel availability,
    ) {
  final data = context.read<AppDataProvider>();

  if ((availability.subjectName ?? '').isNotEmpty) {
    return availability.subjectName!;
  }

  return data.availabilitySubjectName(availability);
}