import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../models/mvp_models.dart';
import '../../providers/app_data_provider.dart';
import '../../widgets/error_banner.dart';
import '../../widgets/money_text.dart';

class AdminPayoutDetailScreen extends StatefulWidget {
  final int payoutId;

  const AdminPayoutDetailScreen({
    super.key,
    required this.payoutId,
  });

  @override
  State<AdminPayoutDetailScreen> createState() =>
      _AdminPayoutDetailScreenState();
}

class _AdminPayoutDetailScreenState extends State<AdminPayoutDetailScreen> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppDataProvider>().adminLoadPayoutDetail(widget.payoutId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final data = context.watch<AppDataProvider>();
    final detail = data.adminPayoutDetail;

    final hasCorrectData = detail != null && detail.payoutId == widget.payoutId;

    return Scaffold(
      appBar: AppBar(
        title: Text('Payout #${widget.payoutId}'),
        actions: [
          IconButton(
            onPressed: data.loading ? null : _reload,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => _reload(),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            ErrorBanner(data.error),
            if (!hasCorrectData)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              )
            else
              _PayoutDetailContent(
                detail: detail,
                loading: data.loading,
                onStatusChanged: _updateStatus,
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _reload() async {
    await context
        .read<AppDataProvider>()
        .adminLoadPayoutDetail(widget.payoutId);
  }

  Future<void> _updateStatus(String status) async {
    try {
      await context.read<AppDataProvider>().adminUpdatePayout(
        payoutId: widget.payoutId,
        status: status,
      );

      if (!mounted) return;

      await context
          .read<AppDataProvider>()
          .adminLoadPayoutDetail(widget.payoutId);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Payout marked as $status')),
      );
    } catch (_) {
      // ErrorBanner will show provider error.
    }
  }
}

class _PayoutDetailContent extends StatelessWidget {
  final AdminPayoutDetailModel detail;
  final bool loading;
  final Future<void> Function(String status) onStatusChanged;

  const _PayoutDetailContent({
    required this.detail,
    required this.loading,
    required this.onStatusChanged,
  });

  @override
  Widget build(BuildContext context) {
    final status = detail.status.toLowerCase();
    final isPending = status == 'pending';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _HeaderCard(detail: detail),
        const SizedBox(height: 12),

        if (isPending) ...[
          _TransferQrCard(detail: detail),
          const SizedBox(height: 12),
        ],

        _SectionCard(
          title: 'Tutor',
          children: [
            _InfoTile(
              icon: Icons.person_outline,
              label: 'Tutor name',
              value: detail.tutorName,
              copyable: true,
            ),
            _InfoTile(
              icon: Icons.email_outlined,
              label: 'Tutor email',
              value: detail.tutorEmail,
              copyable: true,
            ),
            _InfoTile(
              icon: Icons.badge_outlined,
              label: 'Tutor ID',
              value: detail.tutorId.toString(),
              copyable: true,
            ),
            _InfoTile(
              icon: Icons.person_pin_outlined,
              label: 'Tutor user ID',
              value: detail.tutorUserId.toString(),
              copyable: true,
            ),
          ],
        ),

        const SizedBox(height: 12),

        _SectionCard(
          title: 'Bank account for manual transfer',
          children: [
            _InfoTile(
              icon: Icons.account_balance_outlined,
              label: 'Bank name',
              value: _safe(detail.bankName),
              copyable: _hasValue(detail.bankName),
            ),
            _InfoTile(
              icon: Icons.qr_code_2_outlined,
              label: 'Bank BIN',
              value: _safe(detail.bankBin),
              copyable: _hasValue(detail.bankBin),
            ),
            _InfoTile(
              icon: Icons.numbers_outlined,
              label: 'Account number',
              value: _safe(detail.accountNumber),
              copyable: _hasValue(detail.accountNumber),
            ),
            _InfoTile(
              icon: Icons.person_outline,
              label: 'Account holder name',
              value: _safe(detail.accountHolderName),
              copyable: _hasValue(detail.accountHolderName),
            ),
            _InfoTile(
              icon: Icons.location_city_outlined,
              label: 'Branch',
              value: _safe(detail.branchName),
              copyable: _hasValue(detail.branchName),
            ),
          ],
        ),

        const SizedBox(height: 12),

        _SectionCard(
          title: 'Payout information',
          children: [
            _InfoTile(
              icon: Icons.payments_outlined,
              label: 'Amount',
              value: detail.amount.toStringAsFixed(0),
              copyable: true,
            ),
            _InfoTile(
              icon: Icons.info_outline,
              label: 'Status',
              value: detail.status,
            ),
            _InfoTile(
              icon: Icons.receipt_long_outlined,
              label: 'Transfer content',
              value: _transferContent(detail),
              copyable: true,
            ),
            _InfoTile(
              icon: Icons.calendar_month_outlined,
              label: 'Requested at',
              value: _dateTimeText(detail.requestedAt),
            ),
            if (detail.paidAt != null)
              _InfoTile(
                icon: Icons.check_circle_outline,
                label: 'Paid at',
                value: _dateTimeText(detail.paidAt!),
              ),
          ],
        ),

        const SizedBox(height: 20),

        if (isPending) ...[
          FilledButton.icon(
            onPressed: loading
                ? null
                : () => _confirmStatus(
              context,
              status: 'Paid',
              title: 'Mark payout as Paid?',
              message:
              'Only confirm this after you have successfully transferred money to the tutor bank account. This action cannot be undone.',
            ),
            icon: loading
                ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
                : const Icon(Icons.check_circle_outline),
            label: Text(loading ? 'Processing...' : 'Mark Paid'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: loading
                ? null
                : () => _confirmStatus(
              context,
              status: 'Failed',
              title: 'Mark payout as Failed?',
              message:
              'The payout amount will be returned to the tutor wallet. This payout cannot be updated again after failing.',
            ),
            icon: const Icon(Icons.cancel_outlined),
            label: Text(loading ? 'Processing...' : 'Mark Failed'),
          ),
        ] else
          _FinalStatusCard(status: detail.status),

        const SizedBox(height: 24),
      ],
    );
  }

  Future<void> _confirmStatus(
      BuildContext context, {
        required String status,
        required String title,
        required String message,
      }) async {
    final isPaidAction = status.toLowerCase() == 'paid';
    bool confirmedTransfer = false;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(title),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(message),
                  if (isPaidAction) ...[
                    const SizedBox(height: 16),
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      value: confirmedTransfer,
                      onChanged: (value) {
                        setDialogState(() {
                          confirmedTransfer = value ?? false;
                        });
                      },
                      title: const Text(
                        'I have transferred the money to the tutor.',
                      ),
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: isPaidAction && !confirmedTransfer
                      ? null
                      : () => Navigator.of(dialogContext).pop(true),
                  child: Text(status),
                ),
              ],
            );
          },
        );
      },
    );

    if (confirmed != true || !context.mounted) return;

    await onStatusChanged(status);
  }

  static bool _hasValue(String? value) {
    return value != null && value.trim().isNotEmpty;
  }

  static String _safe(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Not provided';
    }

    return value;
  }
}

class _FinalStatusCard extends StatelessWidget {
  final String status;

  const _FinalStatusCard({
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final normalized = status.toLowerCase();

    IconData icon;
    String title;
    String subtitle;

    if (normalized == 'paid') {
      icon = Icons.check_circle_outline;
      title = 'Payout is Paid';
      subtitle =
      'This payout has been completed and cannot be updated again.';
    } else if (normalized == 'failed') {
      icon = Icons.cancel_outlined;
      title = 'Payout is Failed';
      subtitle =
      'The payout amount was returned to the tutor wallet. This payout cannot be updated again.';
    } else {
      icon = Icons.info_outline;
      title = 'Payout is $status';
      subtitle = 'No further action is available.';
    }

    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(subtitle),
      ),
    );
  }
}

class _TransferQrCard extends StatelessWidget {
  final AdminPayoutDetailModel detail;

  const _TransferQrCard({
    required this.detail,
  });

  @override
  Widget build(BuildContext context) {
    final hasQr =
        detail.transferQrUrl != null && detail.transferQrUrl!.trim().isNotEmpty;

    if (!hasQr) {
      return Card(
        child: ListTile(
          leading: const Icon(Icons.qr_code_2_outlined),
          title: const Text('Quick transfer QR unavailable'),
          subtitle: Text(
            detail.transferQrNote?.trim().isNotEmpty == true
                ? detail.transferQrNote!
                : 'Enter the tutor bank BIN to enable quick money transfer QR.',
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.qr_code_2_outlined),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Quick transfer QR',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                detail.transferQrUrl!,
                height: 260,
                width: double.infinity,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) {
                  return Container(
                    height: 180,
                    width: double.infinity,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Theme.of(context).dividerColor,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text('Unable to load transfer QR'),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            _CopyRow(
              label: 'Transfer content',
              value: _transferContent(detail),
            ),
            const SizedBox(height: 6),
            Text(
              detail.transferQrNote?.trim().isNotEmpty == true
                  ? detail.transferQrNote!
                  : 'Scan this QR to transfer payout money to the tutor.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _CopyRow extends StatelessWidget {
  final String label;
  final String value;

  const _CopyRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text('$label: $value')),
        IconButton(
          tooltip: 'Copy',
          icon: const Icon(Icons.copy),
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: value));

            if (!context.mounted) return;

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Copied $label')),
            );
          },
        ),
      ],
    );
  }
}

class _HeaderCard extends StatelessWidget {
  final AdminPayoutDetailModel detail;

  const _HeaderCard({
    required this.detail,
  });

  @override
  Widget build(BuildContext context) {
    final status = detail.status.toLowerCase();

    IconData icon;

    if (status == 'paid') {
      icon = Icons.check_circle_outline;
    } else if (status == 'failed') {
      icon = Icons.cancel_outlined;
    } else {
      icon = Icons.pending_actions_outlined;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(icon, size: 56),
            const SizedBox(height: 12),
            Text(
              'Payout #${detail.payoutId}',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            MoneyText(detail.amount),
            const SizedBox(height: 12),
            Chip(
              label: Text('Status: ${detail.status}'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SectionCard({
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.only(top: 14, bottom: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(height: 8),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool copyable;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
    this.copyable = false,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      subtitle: Text(value),
      trailing: copyable
          ? IconButton(
        tooltip: 'Copy',
        icon: const Icon(Icons.copy),
        onPressed: () async {
          await Clipboard.setData(
            ClipboardData(text: value),
          );

          if (!context.mounted) return;

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Copied $label')),
          );
        },
      )
          : null,
    );
  }
}

String _transferContent(AdminPayoutDetailModel detail) {
  if (detail.transferContent.trim().isNotEmpty) {
    return detail.transferContent.trim();
  }

  return 'PAYOUT${detail.payoutId}';
}

String _dateTimeText(DateTime value) {
  final local = value.toLocal();

  String two(int number) => number.toString().padLeft(2, '0');

  return '${two(local.day)}/${two(local.month)}/${local.year} '
      '${two(local.hour)}:${two(local.minute)}';
}