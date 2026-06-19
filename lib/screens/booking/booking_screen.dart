import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_strings.dart';
import '../../models/mvp_models.dart';
import '../../providers/app_data_provider.dart';
import '../../widgets/error_banner.dart';
import '../../widgets/money_text.dart';
import '../../widgets/tutor_review_sheet.dart';

class BookingScreen extends StatefulWidget {
  const BookingScreen({super.key});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

enum _BookingCategory {
  upcoming,
  confirmed,
  completed,
  cancelledIssues,
}

class _BookingScreenState extends State<BookingScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  bool _selectedInitialTab = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: _BookingCategory.values.length,
      vsync: this,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialBookings();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialBookings() async {
    try {
      await context.read<AppDataProvider>().loadBookings();
    } catch (_) {
      // ErrorBanner renders the provider error state.
    }

    if (!mounted || _selectedInitialTab) return;

    final categories = _groupBookings(context.read<AppDataProvider>().bookings);
    _tabController.animateTo(_defaultCategoryIndex(categories));
    _selectedInitialTab = true;
  }

  @override
  Widget build(BuildContext context) {
    final data = context.watch<AppDataProvider>();
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final t = context.l10n;
    final categories = _groupBookings(data.bookings);

    return Scaffold(
      backgroundColor: colors.surfaceContainerLow,
      appBar: AppBar(
        backgroundColor: colors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        titleSpacing: 20,
        title: Text(
          t.myBookings,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: IconButton(
              onPressed: data.loading ? null : data.loadBookings,
              icon: const Icon(Icons.refresh_rounded),
              style: IconButton.styleFrom(
                backgroundColor:
                    colors.surfaceContainerHighest.withOpacity(0.3),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: ErrorBanner(data.error),
          ),
          _BookingCategoryTabBar(
            controller: _tabController,
            categories: categories,
          ),
          Expanded(
            child: data.loading && data.bookings.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabController,
                    children: _BookingCategory.values
                        .map(
                          (category) => _BookingCategoryList(
                            category: category,
                            bookings: categories[category]!,
                            onRefresh: data.loadBookings,
                          ),
                        )
                        .toList(),
                  ),
          ),
        ],
      ),
    );
  }

  Map<_BookingCategory, List<BookingModel>> _groupBookings(
    List<BookingModel> bookings,
  ) {
    final categories = {
      for (final category in _BookingCategory.values)
        category: <BookingModel>[],
    };

    for (final booking in bookings) {
      categories[_categoryForStatus(booking.status)]!.add(booking);
    }

    return categories;
  }

  _BookingCategory _categoryForStatus(String status) {
    switch (status.trim().toLowerCase()) {
      case 'confirmed':
      case 'paid':
        return _BookingCategory.confirmed;
      case 'completed':
        return _BookingCategory.completed;
      case 'cancelled':
      case 'expired':
      case 'failed':
        return _BookingCategory.cancelledIssues;
      case 'pending':
      default:
        return _BookingCategory.upcoming;
    }
  }

  int _defaultCategoryIndex(
    Map<_BookingCategory, List<BookingModel>> categories,
  ) {
    if (categories[_BookingCategory.upcoming]!.isNotEmpty) {
      return _BookingCategory.upcoming.index;
    }

    return _BookingCategory.confirmed.index;
  }
}

// ─────────────────────────────────────────────────────────
// Booking Card - Modernized with English Translations
// ─────────────────────────────────────────────────────────

class _BookingCategoryTabBar extends StatelessWidget {
  final TabController controller;
  final Map<_BookingCategory, List<BookingModel>> categories;

  const _BookingCategoryTabBar({
    required this.controller,
    required this.categories,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return Container(
          margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: colors.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(16),
          ),
          child: TabBar(
            controller: controller,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            indicatorSize: TabBarIndicatorSize.tab,
            indicatorPadding: EdgeInsets.zero,
            indicator: BoxDecoration(
              color: colors.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            dividerColor: Colors.transparent,
            labelColor: colors.onPrimary,
            unselectedLabelColor: colors.onSurfaceVariant,
            labelPadding: const EdgeInsets.symmetric(horizontal: 12),
            tabs: _BookingCategory.values
                .map(
                  (category) => Tab(
                    height: 44,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _categoryLabel(context, category),
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(width: 6),
                        _BookingCountBadge(
                          count: categories[category]!.length,
                          selected: controller.index == category.index,
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
        );
      },
    );
  }
}

class _BookingCountBadge extends StatelessWidget {
  final int count;
  final bool selected;

  const _BookingCountBadge({
    required this.count,
    required this.selected,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      constraints: const BoxConstraints(minWidth: 22, minHeight: 22),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: selected
            ? colors.onPrimary.withValues(alpha: 0.18)
            : colors.surface,
        borderRadius: BorderRadius.circular(11),
      ),
      child: Text(
        '$count',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: selected ? colors.onPrimary : colors.onSurfaceVariant,
              fontWeight: FontWeight.w800,
            ),
      ),
    );
  }
}

class _BookingCategoryList extends StatelessWidget {
  final _BookingCategory category;
  final List<BookingModel> bookings;
  final Future<void> Function() onRefresh;

  const _BookingCategoryList({
    required this.category,
    required this.bookings,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      displacement: 20,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: bookings.isEmpty
            ? [_BookingCategoryEmptyState(category: category)]
            : bookings
                .map(
                  (booking) => Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: _BookingCard(booking: booking),
                  ),
                )
                .toList(),
      ),
    );
  }
}

class _BookingCategoryEmptyState extends StatelessWidget {
  final _BookingCategory category;

  const _BookingCategoryEmptyState({required this.category});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final t = context.l10n;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 64, horizontal: 24),
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.calendar_today_rounded,
                size: 40,
                color: colors.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _emptyCategoryTitle(context, category),
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              t.bookingsEmptyMessage,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _categoryLabel(BuildContext context, _BookingCategory category) {
  final t = context.l10n;

  switch (category) {
    case _BookingCategory.upcoming:
      return t.text('Upcoming');
    case _BookingCategory.confirmed:
      return t.confirmed;
    case _BookingCategory.completed:
      return t.completed;
    case _BookingCategory.cancelledIssues:
      return t.text('Cancelled / Issues');
  }
}

String _emptyCategoryTitle(BuildContext context, _BookingCategory category) {
  final t = context.l10n;

  switch (category) {
    case _BookingCategory.upcoming:
      return t.text('No upcoming bookings yet');
    case _BookingCategory.confirmed:
      return t.text('No confirmed bookings yet');
    case _BookingCategory.completed:
      return t.text('No completed bookings yet');
    case _BookingCategory.cancelledIssues:
      return t.text('No cancelled or issue bookings yet');
  }
}

_BookingSchedule? _scheduleForBooking(
  List<AvailabilityModel> availabilities,
  BookingModel booking,
) {
  final bookingSchedule = _BookingSchedule.fromBooking(booking);
  if (bookingSchedule != null) return bookingSchedule;

  for (final availability in availabilities) {
    if (availability.availabilityId == booking.availabilityId) {
      return _BookingSchedule.fromAvailability(availability);
    }
  }

  return null;
}

class _BookingSchedule {
  final String dayOfWeek;
  final DateTime startCourseTime;
  final DateTime endCourseTime;
  final String startTime;
  final String endTime;

  const _BookingSchedule({
    required this.dayOfWeek,
    required this.startCourseTime,
    required this.endCourseTime,
    required this.startTime,
    required this.endTime,
  });

  factory _BookingSchedule.fromAvailability(AvailabilityModel availability) {
    return _BookingSchedule(
      dayOfWeek: availability.dayOfWeek,
      startCourseTime: availability.startCourseTime,
      endCourseTime: availability.endCourseTime,
      startTime: availability.startTime,
      endTime: availability.endTime,
    );
  }

  static _BookingSchedule? fromBooking(BookingModel booking) {
    final dayOfWeek = booking.availabilityDayOfWeek;
    final startCourseTime = booking.availabilityStartCourseTime;
    final endCourseTime = booking.availabilityEndCourseTime;
    final startTime = booking.availabilityStartTime;
    final endTime = booking.availabilityEndTime;

    if (dayOfWeek == null ||
        startCourseTime == null ||
        endCourseTime == null ||
        startTime == null ||
        endTime == null) {
      return null;
    }

    return _BookingSchedule(
      dayOfWeek: dayOfWeek,
      startCourseTime: startCourseTime,
      endCourseTime: endCourseTime,
      startTime: startTime,
      endTime: endTime,
    );
  }
}

class _BookingAvailabilitySchedule extends StatelessWidget {
  final _BookingSchedule schedule;

  const _BookingAvailabilitySchedule({required this.schedule});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final t = context.l10n;
    final startDate = DateFormat(
      'dd/MM/yyyy',
    ).format(schedule.startCourseTime.toLocal());
    final endDate = DateFormat(
      'dd/MM/yyyy',
    ).format(schedule.endCourseTime.toLocal());
    final localizedDays = schedule.dayOfWeek
        .split(',')
        .map((day) => t.text(day.trim()))
        .join(', ');

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _BookingScheduleDetail(
              icon: Icons.calendar_month_rounded,
              title: localizedDays,
              subtitle: '$startDate - $endDate',
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Divider(
                height: 1,
                color: colors.outlineVariant.withValues(alpha: 0.7),
              ),
            ),
            _BookingScheduleDetail(
              icon: Icons.access_time_rounded,
              title: t.text('Class time'),
              subtitle: '${schedule.startTime} - ${schedule.endTime}',
            ),
          ],
        ),
      ),
    );
  }
}

class _BookingScheduleDetail extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _BookingScheduleDetail({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Row(
      children: [
        Icon(icon, size: 20, color: colors.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BookingCard extends StatelessWidget {
  final BookingModel booking;

  const _BookingCard({required this.booking});

  @override
  Widget build(BuildContext context) {
    final data = context.watch<AppDataProvider>();
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final t = context.l10n;

    final status = booking.status.toLowerCase();
    final canPay = status == 'pending';
    final canCancel = status == 'pending';
    final canReport = _canReportBooking(booking);
    final canReview = _canReviewBooking(booking);
    final reviewed = data.hasReviewedBooking(booking.bookingId);

    final subjectName = data.subjectNameById(
      booking.subjectId,
      fallback: '${t.text('Subject')} #${booking.subjectId ?? '-'}',
    );
    final tutorName = _displayTutorName(context, booking);
    final schedule = _scheduleForBooking(data.availabilities, booking);

    final statusVisual = _BookingStatusVisual.fromStatus(status);

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.045),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(
          color: colors.outlineVariant.withValues(alpha: 0.55),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
            decoration: BoxDecoration(
              color: statusVisual.color.withValues(alpha: 0.10),
              border: Border(
                bottom: BorderSide(
                  color: statusVisual.color.withValues(alpha: 0.14),
                ),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _StatusIconBadge(visual: statusVisual),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        subjectName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        tutorName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colors.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                _StatusChip(status: booking.status),
              ],
            ),
          ),

          // ── Meta rows ─────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Text(
              '${t.bookingId} #${booking.bookingId}  ·  '
              '${t.tutorId} #${booking.tutorId}  ·  '
              '${t.availabilityId} #${booking.availabilityId}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ),

          // ── Price ─────────────────────────────────────
          if (schedule != null)
            _BookingAvailabilitySchedule(schedule: schedule),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: colors.primaryContainer.withValues(alpha: 0.42),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t.tuitionFee,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  MoneyText(
                    booking.priceAtBooking,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: colors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Divider(
            height: 1,
            thickness: 1,
            color: colors.outlineVariant.withValues(alpha: 0.55),
          ),

          // ── Actions ───────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _ActionButton(
                        icon: Icons.credit_card_rounded,
                        label: _payButtonText(context, status),
                        enabled: canPay && !data.loading,
                        variant: _ButtonVariant.filled,
                        onPressed: () => _pay(context, booking.bookingId),
                      ),
                    ),
                    if (canCancel) ...[
                      const SizedBox(width: 8),
                      Expanded(
                        child: _ActionButton(
                          icon: Icons.close_rounded,
                          label: t.cancelBooking,
                          enabled: !data.loading,
                          variant: _ButtonVariant.outlined,
                          onPressed: () => _cancel(context, booking.bookingId),
                        ),
                      ),
                    ],
                  ],
                ),
                if (canReport) ...[
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: _ActionButton(
                      icon: Icons.flag_rounded,
                      label: t.reportTutor,
                      enabled: !data.loading,
                      variant: _ButtonVariant.danger,
                      onPressed: () => context.push(
                        '/report/booking/${booking.bookingId}',
                      ),
                    ),
                  ),
                ],
                if (canReview) ...[
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: _ActionButton(
                      icon: reviewed
                          ? Icons.check_circle_rounded
                          : Icons.rate_review_rounded,
                      label: reviewed ? t.reviewed : t.reviewTutor,
                      enabled: !reviewed && !data.loading,
                      variant: _ButtonVariant.outlined,
                      onPressed: () => _review(context, booking),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool _canReportBooking(BookingModel booking) {
    final status = booking.status.toLowerCase();
    return status == 'confirmed' || status == 'completed';
  }

  bool _canReviewBooking(BookingModel booking) {
    final status = booking.status.toLowerCase();
    return status == 'paid' || status == 'confirmed' || status == 'completed';
  }

  String _payButtonText(BuildContext context, String status) {
    final t = AppStrings.of(context, listen: false);
    switch (status) {
      case 'pending':
        return t.payNow;
      case 'paid':
      case 'confirmed':
        return t.paid;
      case 'completed':
        return t.completed;
      case 'cancelled':
        return t.cancelled;
      case 'expired':
        return t.expired;
      case 'failed':
        return t.failed;
      default:
        return t.unavailable;
    }
  }

  String _displayTutorName(BuildContext context, BookingModel booking) {
    final name = booking.tutorName?.trim() ?? '';

    if (name.isNotEmpty) {
      return name;
    }

    return '${AppStrings.of(context, listen: false).tutor} #${booking.tutorId}';
  }

  Future<void> _pay(BuildContext context, int bookingId) async {
    final data = context.read<AppDataProvider>();
    try {
      final payment = await data.createPayment(bookingId);
      if (!context.mounted) return;
      context.push('/payment', extra: payment);
    } catch (_) {}
  }

  Future<void> _review(BuildContext context, BookingModel booking) async {
    final created = await showTutorReviewSheet(
      context: context,
      bookingId: booking.bookingId,
      tutorId: booking.tutorId,
      tutorName: _displayTutorName(context, booking),
    );

    if (created == true && context.mounted) {
      final t = AppStrings.of(context, listen: false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.reviewSubmitted)),
      );
    }
  }

  Future<void> _cancel(BuildContext context, int bookingId) async {
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        final theme = Theme.of(sheetContext);
        final colors = theme.colorScheme;
        final t = AppStrings.of(sheetContext, listen: false);
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: colors.outlineVariant,
                  borderRadius: BorderRadius.circular(2.5),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                t.cancelBookingTitle,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                t.cancelBookingMessage,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(sheetContext, false),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        minimumSize: const Size(0, 48),
                      ),
                      child: Text(t.keepBooking),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => Navigator.pop(sheetContext, true),
                      style: FilledButton.styleFrom(
                        backgroundColor: colors.error,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        minimumSize: const Size(0, 48),
                      ),
                      child: Text(t.confirmCancel),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );

    if (confirmed != true) return;
    if (!context.mounted) return;

    final data = context.read<AppDataProvider>();

    try {
      await data.cancelBooking(bookingId);
      if (!context.mounted) return;
      final t = AppStrings.of(context, listen: false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(t.bookingCancelled),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
    } catch (_) {}
  }
}

// ─────────────────────────────────────────────────────────
// Helper widgets
// ─────────────────────────────────────────────────────────

class _BookingStatusVisual {
  final Color color;
  final IconData icon;

  const _BookingStatusVisual({
    required this.color,
    required this.icon,
  });

  factory _BookingStatusVisual.fromStatus(String status) {
    switch (status.trim().toLowerCase()) {
      case 'confirmed':
      case 'paid':
        return const _BookingStatusVisual(
          color: Color(0xFF15803D),
          icon: Icons.verified_outlined,
        );
      case 'completed':
        return const _BookingStatusVisual(
          color: Color(0xFF2563EB),
          icon: Icons.task_alt_rounded,
        );
      case 'cancelled':
      case 'expired':
      case 'failed':
        return const _BookingStatusVisual(
          color: Color(0xFFB91C1C),
          icon: Icons.error_outline_rounded,
        );
      case 'pending':
      default:
        return const _BookingStatusVisual(
          color: Color(0xFFB45309),
          icon: Icons.schedule_rounded,
        );
    }
  }
}

class _StatusIconBadge extends StatelessWidget {
  final _BookingStatusVisual visual;

  const _StatusIconBadge({required this.visual});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: visual.color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(visual.icon, color: visual.color, size: 22),
    );
  }
}

enum _ButtonVariant { filled, outlined, danger }

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool enabled;
  final _ButtonVariant variant;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.enabled,
    required this.variant,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final borderRadius = BorderRadius.circular(12);

    final iconWidget = Icon(icon, size: 16);
    final labelWidget =
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold));

    if (variant == _ButtonVariant.filled) {
      return FilledButton.icon(
        onPressed: enabled ? onPressed : null,
        icon: iconWidget,
        label: labelWidget,
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 48),
          shape: RoundedRectangleBorder(borderRadius: borderRadius),
          elevation: enabled ? 1 : 0,
          shadowColor: colors.primary.withValues(alpha: 0.24),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
      );
    }

    if (variant == _ButtonVariant.danger) {
      return FilledButton.icon(
        onPressed: enabled ? onPressed : null,
        icon: iconWidget,
        label: labelWidget,
        style: FilledButton.styleFrom(
          backgroundColor: colors.errorContainer,
          foregroundColor: colors.error,
          minimumSize: const Size(0, 48),
          shape: RoundedRectangleBorder(borderRadius: borderRadius),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
          elevation: 0,
        ),
      );
    }

    return OutlinedButton.icon(
      onPressed: enabled ? onPressed : null,
      icon: iconWidget,
      label: labelWidget,
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: colors.outlineVariant, width: 1),
        minimumSize: const Size(0, 48),
        shape: RoundedRectangleBorder(borderRadius: borderRadius),
        textStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Status Chip - English Localization Mapping
// ─────────────────────────────────────────────────────────

class _StatusChip extends StatelessWidget {
  final String status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final visual = _BookingStatusVisual.fromStatus(status);
    final t = context.l10n;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: visual.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(visual.icon, size: 14, color: visual.color),
          const SizedBox(width: 5),
          Text(
            t.status(status),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: visual.color,
            ),
          ),
        ],
      ),
    );
  }
}
