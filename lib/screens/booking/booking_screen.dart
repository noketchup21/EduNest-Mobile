import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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

class _BookingScreenState extends State<BookingScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppDataProvider>().loadBookings();
    });
  }

  @override
  Widget build(BuildContext context) {
    final data = context.watch<AppDataProvider>();
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final t = context.l10n;

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
      body: RefreshIndicator(
        onRefresh: data.loadBookings,
        displacement: 20,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            ErrorBanner(data.error),
            if (data.loading && data.bookings.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 64),
                child: Center(child: CircularProgressIndicator()),
              ),
            if (!data.loading && data.bookings.isEmpty)
              Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 64, horizontal: 24),
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
                        t.noBookingsFound,
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
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
              ),
            ...data.bookings.map((booking) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: _BookingCard(booking: booking),
              );
            }),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Booking Card - Modernized with English Translations
// ─────────────────────────────────────────────────────────

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

    final statusColor = _getIndicatorColor(status);

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: colors.outlineVariant.withOpacity(0.4),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 6,
            height: canReport && canReview
                ? 318
                : canReport || canReview
                    ? 266
                    : 210,
            color: statusColor,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header ────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          subjectName,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _StatusChip(status: booking.status),
                    ],
                  ),
                ),

                const Divider(height: 1, thickness: 1),

                // ── Meta rows ─────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Column(
                    children: [
                      _MetaRow(
                        icon: Icons.tag_rounded,
                        label: '${t.bookingId}: #${booking.bookingId}',
                        iconColor: Colors.blue,
                      ),
                      const SizedBox(height: 6),
                      _MetaRow(
                        icon: Icons.person_outline_rounded,
                        label: '${t.tutorId}: #${booking.tutorId}',
                        iconColor: Colors.purple,
                      ),
                      const SizedBox(height: 6),
                      _MetaRow(
                        icon: Icons.calendar_month_outlined,
                        label:
                            '${t.availabilityId}: #${booking.availabilityId}',
                        iconColor: Colors.teal,
                      ),
                    ],
                  ),
                ),

                // ── Price ─────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            t.tuitionFee,
                            style: TextStyle(
                                fontSize: 11, color: colors.onSurfaceVariant),
                          ),
                          MoneyText(
                            booking.priceAtBooking,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w900,
                              color: colors.primary,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '#${booking.bookingId}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colors.onSurface.withOpacity(0.3),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                const Divider(height: 1, thickness: 1),

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
                                onPressed: () =>
                                    _cancel(context, booking.bookingId),
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

  Color _getIndicatorColor(String status) {
    switch (status) {
      case 'confirmed':
      case 'paid':
      case 'completed':
        return Colors.green;
      case 'cancelled':
      case 'expired':
      case 'failed':
        return Colors.red;
      case 'pending':
      default:
        return Colors.orange;
    }
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
      tutorName:
          '${AppStrings.of(context, listen: false).tutor} #${booking.tutorId}',
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

class _MetaRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color iconColor;

  const _MetaRow({
    required this.icon,
    required this.label,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(
            icon,
            size: 16,
            color: iconColor,
          ),
        ),
        const SizedBox(width: 10),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: colors.onSurfaceVariant,
          ),
        ),
      ],
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
          minimumSize: const Size(0, 44),
          shape: RoundedRectangleBorder(borderRadius: borderRadius),
          textStyle: const TextStyle(fontSize: 14),
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
          minimumSize: const Size(0, 44),
          shape: RoundedRectangleBorder(borderRadius: borderRadius),
          textStyle: const TextStyle(fontSize: 14),
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
        minimumSize: const Size(0, 44),
        shape: RoundedRectangleBorder(borderRadius: borderRadius),
        textStyle: const TextStyle(fontSize: 14),
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
    final (bg, fg) = _statusColors(status);
    final t = context.l10n;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        t.status(status),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: fg,
        ),
      ),
    );
  }

  (Color, Color) _statusColors(String value) {
    switch (value.toLowerCase()) {
      case 'confirmed':
      case 'paid':
      case 'completed':
        return (
          Colors.green.withOpacity(0.12),
          Colors.green.shade800,
        );
      case 'cancelled':
      case 'expired':
      case 'failed':
        return (
          Colors.red.withOpacity(0.12),
          Colors.red.shade800,
        );
      case 'pending':
      default:
        return (
          Colors.orange.withOpacity(0.12),
          Colors.orange.shade800,
        );
    }
  }
}
