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
              _PaginatedTransactions(
                transactions: data.walletTransactions,
                dateFormatter: dateFormatter,
                currencyFormatter: currencyFormatter,
              ),

            // --- SECTION 4: PAYOUTS LIST ---
            _buildSectionHeader(context, 'Payout History'),
            if (data.payouts.isEmpty)
              _buildEmptyCard(Icons.payments_outlined, 'No payout requests yet')
            else
              _PaginatedPayouts(
                payouts: data.payouts,
                dateFormatter: dateFormatter,
                currencyFormatter: currencyFormatter,
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

class _PaginatedTransactions extends StatefulWidget {
  final List transactions;
  final DateFormat dateFormatter;
  final NumberFormat currencyFormatter;

  const _PaginatedTransactions({
    required this.transactions,
    required this.dateFormatter,
    required this.currencyFormatter,
  });

  @override
  State<_PaginatedTransactions> createState() => _PaginatedTransactionsState();
}

class _PaginatedTransactionsState extends State<_PaginatedTransactions> {
  static const int _pageSize = 5;
  int _page = 0;

  int get _totalPages => ((widget.transactions.length - 1) ~/ _pageSize) + 1;

  List get _currentItems {
    final start = _page * _pageSize;
    final end = (start + _pageSize).clamp(0, widget.transactions.length);
    return widget.transactions.sublist(start, end);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: colors.outlineVariant.withOpacity(0.5)),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _currentItems.length,
            separatorBuilder: (_, __) => Divider(
              height: 1,
              indent: 60,
              endIndent: 16,
              color: colors.outlineVariant.withOpacity(0.4),
            ),
            itemBuilder: (context, index) {
              final t = _currentItems[index];
              final isPositive = (t.amount as double) >= 0;
              final color = isPositive ? Colors.green : Colors.red;

              return ListTile(
                contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                leading: CircleAvatar(
                  backgroundColor: color.withOpacity(0.1),
                  child: Icon(
                    isPositive ? Icons.add_rounded : Icons.remove_rounded,
                    color: color,
                    size: 20,
                  ),
                ),
                title: Text(
                  t.type as String,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                subtitle: Text(
                  '${(t.description as String?) ?? ''}\n${widget.dateFormatter.format((t.createdAt as DateTime).toLocal())}',
                  style: TextStyle(
                    height: 1.35,
                    fontSize: 12,
                    color: colors.onSurfaceVariant,
                  ),
                ),
                isThreeLine: true,
                trailing: Text(
                  '${isPositive ? "+" : ""}${widget.currencyFormatter.format(t.amount)}',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: color,
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        _PageControls(
          page: _page,
          totalPages: _totalPages,
          total: widget.transactions.length,
          pageSize: _pageSize,
          onPrev: _page > 0 ? () => setState(() => _page--) : null,
          onNext: _page < _totalPages - 1 ? () => setState(() => _page++) : null,
        ),
      ],
    );
  }
}

class _PaginatedPayouts extends StatefulWidget {
  final List payouts;
  final DateFormat dateFormatter;
  final NumberFormat currencyFormatter;

  const _PaginatedPayouts({
    required this.payouts,
    required this.dateFormatter,
    required this.currencyFormatter,
  });

  @override
  State<_PaginatedPayouts> createState() => _PaginatedPayoutsState();
}

class _PaginatedPayoutsState extends State<_PaginatedPayouts> {
  static const int _pageSize = 5;
  int _page = 0;

  int get _totalPages => ((widget.payouts.length - 1) ~/ _pageSize) + 1;

  List get _currentItems {
    final start = _page * _pageSize;
    final end = (start + _pageSize).clamp(0, widget.payouts.length);
    return widget.payouts.sublist(start, end);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: colors.outlineVariant.withOpacity(0.5)),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _currentItems.length,
            separatorBuilder: (_, __) => Divider(
              height: 1,
              indent: 60,
              endIndent: 16,
              color: colors.outlineVariant.withOpacity(0.4),
            ),
            itemBuilder: (context, index) {
              final p = _currentItems[index];
              final status = (p.status as String).toLowerCase();
              final Color color;
              if (status == 'paid') {
                color = Colors.green;
              } else if (status == 'failed' || status == 'rejected') {
                color = Colors.red;
              } else {
                color = Colors.orange;
              }

              return ListTile(
                contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                leading: _PayoutStatusIcon(status: p.status as String),
                title: Text(
                  'Request #${p.payoutId}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                subtitle: Text(
                  widget.dateFormatter
                      .format((p.requestedAt as DateTime).toLocal()),
                  style: TextStyle(
                    fontSize: 12,
                    color: colors.onSurfaceVariant,
                  ),
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    MoneyText(
                      p.amount as double,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: color.withOpacity(0.25)),
                      ),
                      child: Text(
                        p.status as String,
                        style: TextStyle(
                          color: color,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        _PageControls(
          page: _page,
          totalPages: _totalPages,
          total: widget.payouts.length,
          pageSize: _pageSize,
          onPrev: _page > 0 ? () => setState(() => _page--) : null,
          onNext: _page < _totalPages - 1 ? () => setState(() => _page++) : null,
        ),
      ],
    );
  }
}

class _PageControls extends StatelessWidget {
  final int page;
  final int totalPages;
  final int total;
  final int pageSize;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;

  const _PageControls({
    required this.page,
    required this.totalPages,
    required this.total,
    required this.pageSize,
    required this.onPrev,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final start = page * pageSize + 1;
    final end = ((page + 1) * pageSize).clamp(0, total);

    return Row(
      children: [
        // Range label
        Expanded(
          child: Text(
            '$start–$end of $total',
            style: TextStyle(
              fontSize: 12,
              color: colors.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),

        // Page indicator pills
        ...List.generate(totalPages, (i) {
          final isActive = i == page;
          return GestureDetector(
            onTap: () {
              // handled via prev/next but dots give visual reference
            },
            child: Container(
              width: isActive ? 18 : 7,
              height: 7,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color: isActive
                    ? colors.primary
                    : colors.onSurfaceVariant.withOpacity(0.25),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          );
        }),

        const SizedBox(width: 10),

        // Prev button
        SizedBox(
          width: 34,
          height: 34,
          child: IconButton.outlined(
            padding: EdgeInsets.zero,
            onPressed: onPrev,
            icon: const Icon(Icons.chevron_left_rounded, size: 18),
            style: IconButton.styleFrom(
              side: BorderSide(
                color: onPrev != null
                    ? colors.outlineVariant
                    : colors.outlineVariant.withOpacity(0.3),
              ),
            ),
          ),
        ),
        const SizedBox(width: 6),

        // Next button
        SizedBox(
          width: 34,
          height: 34,
          child: IconButton.outlined(
            padding: EdgeInsets.zero,
            onPressed: onNext,
            icon: const Icon(Icons.chevron_right_rounded, size: 18),
            style: IconButton.styleFrom(
              side: BorderSide(
                color: onNext != null
                    ? colors.outlineVariant
                    : colors.outlineVariant.withOpacity(0.3),
              ),
            ),
          ),
        ),
      ],
    );
  }
}