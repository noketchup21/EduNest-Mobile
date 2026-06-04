import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../providers/app_data_provider.dart';
import '../../widgets/error_banner.dart';
import '../../widgets/money_text.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  static const double minimumPayoutAmount = 10000;

  final amount = TextEditingController();

  final currencyFormatter = NumberFormat.currency(
    locale: 'vi_VN',
    symbol: '₫',
  );

  final dateFormatter = DateFormat('dd/MM/yyyy HH:mm');

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppDataProvider>().loadWallet();
    });
  }

  @override
  void dispose() {
    amount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = context.watch<AppDataProvider>();
    final wallet = data.wallet;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Wallet'),
        actions: [
          IconButton(
            onPressed: data.loading ? null : data.loadWallet,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: data.loadWallet,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 16),
          children: [
            ErrorBanner(data.error),

            Card(
              margin: const EdgeInsets.all(16),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: wallet == null
                    ? const Text('Wallet is available for tutor accounts.')
                    : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Available balance'),
                    MoneyText(
                      wallet.balance,
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      'Pending payout: ${currencyFormatter.format(wallet.pendingBalance)}',
                    ),

                    const SizedBox(height: 16),

                    TextField(
                      controller: amount,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Payout amount',
                        helperText:
                        'Minimum payout amount is ${currencyFormatter.format(minimumPayoutAmount)}',
                        prefixIcon: const Icon(Icons.payments_outlined),
                      ),
                    ),

                    const SizedBox(height: 12),

                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: data.loading || wallet == null
                            ? null
                            : () => _requestPayout(wallet.balance),
                        icon: data.loading
                            ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                            : const Icon(Icons.account_balance_wallet),
                        label: Text(
                          data.loading
                              ? 'Requesting...'
                              : 'Request payout',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Text(
                'Transactions',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            if (data.walletTransactions.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Card(
                  child: ListTile(
                    leading: Icon(Icons.receipt_long_outlined),
                    title: Text('No transactions yet'),
                  ),
                ),
              )
            else
              ...data.walletTransactions.map(
                    (t) => Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  child: ListTile(
                    leading: Icon(
                      t.amount >= 0
                          ? Icons.add_circle_outline
                          : Icons.remove_circle_outline,
                    ),
                    title: Text(
                      '${t.type} • ${currencyFormatter.format(t.amount)}',
                    ),
                    subtitle: Text(
                      '${t.description ?? ''}\n${dateFormatter.format(t.createdAt.toLocal())}',
                    ),
                  ),
                ),
              ),

            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                'Payouts',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            if (data.payouts.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Card(
                  child: ListTile(
                    leading: Icon(Icons.payments_outlined),
                    title: Text('No payout requests yet'),
                  ),
                ),
              )
            else
              ...data.payouts.map(
                    (p) => Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  child: ListTile(
                    leading: _PayoutStatusIcon(status: p.status),
                    title: Text('Payout #${p.payoutId} • ${p.status}'),
                    subtitle: Text(
                      dateFormatter.format(p.requestedAt.toLocal()),
                    ),
                    trailing: MoneyText(p.amount),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _requestPayout(double availableBalance) async {
    final raw = amount.text.trim().replaceAll(',', '');
    final value = double.tryParse(raw) ?? 0;

    if (value < minimumPayoutAmount) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Minimum payout amount is ${currencyFormatter.format(minimumPayoutAmount)}',
          ),
        ),
      );
      return;
    }

    if (value > availableBalance) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Payout amount cannot exceed available balance.'),
        ),
      );
      return;
    }

    try {
      await context.read<AppDataProvider>().requestPayout(value);

      if (!mounted) return;

      amount.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Payout request created'),
        ),
      );
    } catch (_) {
      // ErrorBanner will show provider error.
    }
  }
}

class _PayoutStatusIcon extends StatelessWidget {
  final String status;

  const _PayoutStatusIcon({
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final normalized = status.toLowerCase();

    if (normalized == 'paid') {
      return const Icon(Icons.check_circle_outline);
    }

    if (normalized == 'failed') {
      return const Icon(Icons.cancel_outlined);
    }

    return const Icon(Icons.pending_actions_outlined);
  }
}