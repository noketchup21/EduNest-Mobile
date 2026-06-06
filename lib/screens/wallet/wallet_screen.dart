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

  final dateFormatter = DateFormat('MM/dd/yyyy HH:mm');

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
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerLow,
      appBar: AppBar(
        title: const Text('My Wallet', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: false,
        elevation: 0,
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            onPressed: data.loading ? null : data.loadWallet,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: data.loadWallet,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          children: [
            ErrorBanner(data.error),

            // --- SECTION 1: WALLET DASHBOARD ---
            if (wallet == null)
              Card(
                elevation: 0,
                color: theme.colorScheme.errorContainer,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'The Wallet feature is only available for Tutor accounts.',
                    style: TextStyle(color: theme.colorScheme.onErrorContainer),
                  ),
                ),
              )
            else ...[
              // Modern Gradient Balance Card
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [theme.colorScheme.primary, theme.colorScheme.primaryContainer],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.primary.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    )
                  ],
                ),
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Available Balance',
                      style: TextStyle(
                        color: theme.colorScheme.onPrimary.withOpacity(0.8),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    MoneyText(
                      wallet.balance,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onPrimary,
                      ),
                    ),
                    const Divider(height: 24, color: Colors.white24),
                    Row(
                      children: [
                        Icon(Icons.hourglass_empty_rounded,
                            size: 16, color: theme.colorScheme.onPrimary.withOpacity(0.8)),
                        const SizedBox(width: 6),
                        Text(
                          'Pending Clearance: ',
                          style: TextStyle(color: theme.colorScheme.onPrimary.withOpacity(0.8)),
                        ),
                        Text(
                          currencyFormatter.format(wallet.pendingBalance),
                          style: TextStyle(
                            color: theme.colorScheme.onPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // --- SECTION 2: PAYOUT BOX ---
              Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Payout Request',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: amount,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        labelText: 'Amount to Withdraw',
                        helperText: 'Minimum: ${currencyFormatter.format(minimumPayoutAmount)}',
                        prefixIcon: const Icon(Icons.account_balance_wallet_outlined),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: data.loading ? null : () => _requestPayout(wallet.balance),
                        icon: data.loading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.arrow_upward_rounded),
                        label: Text(data.loading ? 'Sending Request...' : 'Submit Payout Request'),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // --- SECTION 3: TRANSACTIONS LIST ---
            _buildSectionHeader(context, 'Transaction History'),
            if (data.walletTransactions.isEmpty)
              _buildEmptyCard(Icons.receipt_long_outlined, 'No transactions yet')
            else
              Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: data.walletTransactions.length,
                  separatorBuilder: (_, __) => const Divider(height: 1, indent: 60, endIndent: 16),
                  itemBuilder: (context, index) {
                    final t = data.walletTransactions[index];
                    final isPositive = t.amount >= 0;
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      leading: CircleAvatar(
                        backgroundColor: isPositive
                            ? Colors.green.withOpacity(0.1)
                            : Colors.red.withOpacity(0.1),
                        child: Icon(
                          isPositive ? Icons.add_rounded : Icons.remove_rounded,
                          color: isPositive ? Colors.green : Colors.red,
                        ),
                      ),
                      title: Text(
                        t.type,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        '${t.description ?? ''}\n${dateFormatter.format(t.createdAt.toLocal())}',
                        style: const TextStyle(height: 1.3),
                      ),
                      trailing: Text(
                        '${isPositive ? "+" : ""}${currencyFormatter.format(t.amount)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: isPositive ? Colors.green : Colors.red,
                        ),
                      ),
                    );
                  },
                ),
              ),

            // --- SECTION 4: PAYOUTS LIST ---
            _buildSectionHeader(context, 'Payout History'),
            if (data.payouts.isEmpty)
              _buildEmptyCard(Icons.payments_outlined, 'No payout requests yet')
            else
              Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: data.payouts.length,
                  separatorBuilder: (_, __) => const Divider(height: 1, indent: 60, endIndent: 16),
                  itemBuilder: (context, index) {
                    final p = data.payouts[index];
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      leading: _PayoutStatusIcon(status: p.status),
                      title: Text(
                        'Request ID: #${p.payoutId}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        dateFormatter.format(p.requestedAt.toLocal()),
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          MoneyText(
                            p.amount,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                          const SizedBox(height: 2),
                          _buildStatusBadge(p.status),
                        ],
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 24, 4, 12),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }

  Widget _buildEmptyCard(IconData icon, String message) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.15)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.grey),
          const SizedBox(width: 12),
          Text(message, style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    final norm = status.toLowerCase();
    Color color = Colors.orange;
    if (norm == 'paid') color = Colors.green;
    if (norm == 'failed') color = Colors.red;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  Future<void> _requestPayout(double availableBalance) async {
    final raw = amount.text.trim().replaceAll(',', '');
    final value = double.tryParse(raw) ?? 0;

    if (value < minimumPayoutAmount) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('The minimum payout amount is ${currencyFormatter.format(minimumPayoutAmount)}'),
        ),
      );
      return;
    }

    if (value > availableBalance) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('The amount requested exceeds your available balance.')),
      );
      return;
    }

    try {
      await context.read<AppDataProvider>().requestPayout(value);
      if (!mounted) return;
      amount.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payout request submitted successfully')),
      );
    } catch (_) {}
  }
}

class _PayoutStatusIcon extends StatelessWidget {
  final String status;
  const _PayoutStatusIcon({required this.status});

  @override
  Widget build(BuildContext context) {
    final normalized = status.toLowerCase();

    if (normalized == 'paid') {
      return CircleAvatar(
        backgroundColor: Colors.green.withOpacity(0.1),
        child: const Icon(Icons.check_circle_rounded, color: Colors.green),
      );
    }
    if (normalized == 'failed') {
      return CircleAvatar(
        backgroundColor: Colors.red.withOpacity(0.1),
        child: const Icon(Icons.cancel_rounded, color: Colors.red),
      );
    }

    return CircleAvatar(
      backgroundColor: Colors.orange.withOpacity(0.1),
      child: const Icon(Icons.timelapse_rounded, color: Colors.orange),
    );
  }
}