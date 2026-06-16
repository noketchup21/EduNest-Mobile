import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../l10n/app_strings.dart';
import '../../models/mvp_models.dart';
import '../../providers/app_data_provider.dart';
import '../../widgets/error_banner.dart';
import '../../widgets/money_text.dart';

class PaymentScreen extends StatefulWidget {
  final PaymentModel payment;

  const PaymentScreen({
    super.key,
    required this.payment,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  late PaymentModel payment;

  @override
  void initState() {
    super.initState();
    payment = widget.payment;
  }

  Future<void> _openCheckoutLink(BuildContext context) async {
    final t = AppStrings.of(context, listen: false);
    final checkout = payment.checkoutUrl;

    if (checkout == null || checkout.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(t.text('Payment link is empty')),
        ),
      );
      return;
    }

    final uri = Uri.tryParse(checkout);

    if (uri == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(t.text('Invalid payment link')),
        ),
      );
      return;
    }

    final opened = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );

    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(t.text('Could not open payment link')),
        ),
      );
    }
  }

  Future<void> _checkPayment(BuildContext context) async {
    try {
      final updated =
          await context.read<AppDataProvider>().syncPayment(payment.bookingId);

      if (!context.mounted) return;

      setState(() {
        payment = updated;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${AppStrings.of(context, listen: false).text('Payment status')}: ${AppStrings.of(context, listen: false).status(updated.status)}',
          ),
        ),
      );

      if (updated.status.toLowerCase() == 'paid') {
        context.go('/lessons');
      }
    } catch (_) {
      // ErrorBanner will show provider error.
    }
  }

  bool get _isPaid => payment.status.toLowerCase() == 'paid';

  Future<bool> _confirmLeavePayment() async {
    final t = AppStrings.of(context, listen: false);
    final shouldLeave = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(t.text('Leave payment screen?')),
          content: Text(
            t.text(
              'If you already paid, tap "I have paid / Check payment" before leaving so EduNest can confirm your booking and create lessons.',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(t.text('Stay')),
            ),
            FilledButton.tonal(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(t.text('Leave anyway')),
            ),
          ],
        );
      },
    );

    return shouldLeave == true;
  }

  @override
  Widget build(BuildContext context) {
    final data = context.watch<AppDataProvider>();
    final t = context.l10n;

    final qr = payment.qrCode;
    final checkout = payment.checkoutUrl;
    final qrLooksLikeImage = qr != null && qr.startsWith('http');
    final isPaid = _isPaid;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        final shouldLeave = await _confirmLeavePayment();

        if (shouldLeave && context.mounted) {
          context.pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(t.text('Payment')),
          actions: [
            IconButton(
              onPressed: data.loading ? null : () => _checkPayment(context),
              icon: const Icon(Icons.refresh),
              tooltip: t.text('Check payment'),
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            ErrorBanner(data.error),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.bookingNumber(payment.bookingId),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text('${t.text('Provider')}: ${payment.provider}'),
                    Text('${t.text('Status')}: ${t.status(payment.status)}'),
                    Text('${t.text('Description')}: ${payment.description}'),
                    const SizedBox(height: 8),
                    MoneyText(
                      payment.amount,
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w900,
                              ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Text(
                      isPaid
                          ? t.text('Payment completed')
                          : t.text('Scan QR to pay'),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 16),
                    if (isPaid)
                      const Icon(
                        Icons.check_circle,
                        size: 96,
                        color: Colors.green,
                      )
                    else if (qr == null || qr.isEmpty)
                      Text(
                        t.text(
                          'QR code is empty. Check backend PayOS configuration.',
                        ),
                        textAlign: TextAlign.center,
                      )
                    else if (qrLooksLikeImage)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.network(
                          qr,
                          height: 260,
                          fit: BoxFit.contain,
                        ),
                      )
                    else
                      QrImageView(
                        data: qr,
                        size: 260,
                      ),
                    const SizedBox(height: 16),
                    if (!isPaid && checkout != null && checkout.isNotEmpty)
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: data.loading
                              ? null
                              : () => _openCheckoutLink(context),
                          icon: const Icon(Icons.open_in_new),
                          label: Text(t.text('Open payment link')),
                        ),
                      ),
                    const SizedBox(height: 8),
                    if (!isPaid)
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: data.loading
                              ? null
                              : () => _checkPayment(context),
                          icon: data.loading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.refresh),
                          label: Text(t.text('I have paid / Check payment')),
                        ),
                      ),
                    const SizedBox(height: 12),
                    Text(
                      isPaid
                          ? t.text(
                              'Your booking is confirmed. Lessons have been created.',
                            )
                          : t.text(
                              'After transferring money, tap "I have paid / Check payment" to sync PayOS status and create lessons.',
                            ),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
