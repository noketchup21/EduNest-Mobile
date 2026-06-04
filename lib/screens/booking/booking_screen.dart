import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/mvp_models.dart';
import '../../providers/app_data_provider.dart';
import '../../widgets/error_banner.dart';
import '../../widgets/money_text.dart';

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

    return Scaffold(
      appBar: AppBar(
        title: const Text('My bookings'),
        actions: [
          IconButton(
            onPressed: data.loading ? null : data.loadBookings,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: data.loadBookings,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 16),
          children: [
            ErrorBanner(data.error),

            if (data.loading && data.bookings.isEmpty)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              ),

            if (!data.loading && data.bookings.isEmpty)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Text('No bookings yet.'),
              ),

            ...data.bookings.map((booking) {
              return _BookingCard(
                booking: booking,
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _BookingCard extends StatelessWidget {
  final BookingModel booking;

  const _BookingCard({
    required this.booking,
  });

  @override
  Widget build(BuildContext context) {
    final data = context.watch<AppDataProvider>();

    final status = booking.status.toLowerCase();
    final canPay = status == 'pending';
    final canCancel = status == 'pending';
    final canReport = _canReportBooking(booking);

    final subjectName = data.subjectNameById(
      booking.subjectId,
      fallback: 'Subject #${booking.subjectId ?? '-'}',
    );

    return Card(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    subjectName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                _StatusChip(status: booking.status),
              ],
            ),

            const SizedBox(height: 8),

            Text('Booking #${booking.bookingId}'),
            Text('Tutor #${booking.tutorId}'),
            Text('Availability #${booking.availabilityId}'),

            const SizedBox(height: 10),

            MoneyText(
              booking.priceAtBooking,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: canPay && !data.loading
                        ? () => _pay(context, booking.bookingId)
                        : null,
                    icon: const Icon(Icons.payment),
                    label: Text(_payButtonText(status)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: canCancel && !data.loading
                        ? () => _cancel(context, booking.bookingId)
                        : null,
                    icon: const Icon(Icons.cancel_outlined),
                    label: const Text('Cancel'),
                  ),
                ),
              ],
            ),

            if (canReport) ...[
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: data.loading
                      ? null
                      : () {
                    context.push(
                      '/report/booking/${booking.bookingId}',
                    );
                  },
                  icon: const Icon(Icons.report_outlined),
                  label: const Text('Report tutor'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  bool _canReportBooking(BookingModel booking) {
    final status = booking.status.toLowerCase();

    return status == 'confirmed' || status == 'completed';
  }

  String _payButtonText(String status) {
    switch (status) {
      case 'pending':
        return 'Pay now';
      case 'paid':
      case 'confirmed':
        return 'Paid';
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      case 'expired':
        return 'Expired';
      case 'failed':
        return 'Failed';
      default:
        return 'Unavailable';
    }
  }

  Future<void> _pay(BuildContext context, int bookingId) async {
    final data = context.read<AppDataProvider>();

    try {
      final payment = await data.createPayment(bookingId);

      if (!context.mounted) return;

      context.push('/payment', extra: payment);
    } catch (_) {
      // ErrorBanner will show data.error.
    }
  }

  Future<void> _cancel(BuildContext context, int bookingId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Cancel booking?'),
          content: const Text(
            'This will cancel your pending booking. You can book again later.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('No'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Cancel booking'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      await context.read<AppDataProvider>().cancelBooking(bookingId);

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Booking cancelled'),
        ),
      );
    } catch (_) {
      // ErrorBanner will show data.error.
    }
  }
}

class _StatusChip extends StatelessWidget {
  final String status;

  const _StatusChip({
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(status);

    return Chip(
      label: Text(status),
      backgroundColor: color.withValues(alpha: 0.15),
      side: BorderSide(
        color: color.withValues(alpha: 0.4),
      ),
    );
  }

  Color _statusColor(String value) {
    switch (value.toLowerCase()) {
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
}