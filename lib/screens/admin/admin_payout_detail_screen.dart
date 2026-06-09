import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../models/mvp_models.dart';
import '../../providers/app_data_provider.dart';
import '../../widgets/error_banner.dart';
import '../../widgets/money_text.dart';

const double _cardRadius = 22;

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
    final colors = Theme.of(context).colorScheme;

    final hasCorrectData = detail != null && detail.payoutId == widget.payoutId;

    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        title: Text(
          'Payout #${widget.payoutId}',
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: colors.surface,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: IconButton.filledTonal(
              onPressed: data.loading ? null : _reload,
              icon: const Icon(Icons.refresh),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => _reload(),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            ErrorBanner(data.error),
            if (!hasCorrectData)
              const _LoadingCard()
            else
              _PayoutDetailContent(
                detail: detail,
                loading: data.loading,
                onStatusChanged: _updateStatus,
                onPayOSChiApprove: _approveWithPayOSChi,
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _reload() async {
    await context.read<AppDataProvider>().adminLoadPayoutDetail(widget.payoutId);
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

  Future<void> _approveWithPayOSChi() async {
    try {
      await context
          .read<AppDataProvider>()
          .adminApprovePayoutWithPayOSChi(widget.payoutId);

      if (!mounted) return;

      await context
          .read<AppDataProvider>()
          .adminLoadPayoutDetail(widget.payoutId);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Payout approved. payOS Chi is processing.'),
        ),
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
  final Future<void> Function() onPayOSChiApprove;

  const _PayoutDetailContent({
    required this.detail,
    required this.loading,
    required this.onStatusChanged,
    required this.onPayOSChiApprove,
  });

  @override
  Widget build(BuildContext context) {
    final status = detail.status.toLowerCase();
    final isPending = status == 'pending';
    final isProcessing = status == 'processing';
    final isManualQrRequired = status == 'manualqrrequired';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _HeaderCard(detail: detail),
        const SizedBox(height: 14),
        if (isPending || isManualQrRequired) ...[
          _TransferQrCard(detail: detail),
          const SizedBox(height: 14),
        ],
        if (_hasAnyPayOSChiInfo(detail) ||
            isProcessing ||
            isManualQrRequired) ...[
          _PayOSChiCard(detail: detail),
          const SizedBox(height: 14),
        ],
        _SectionCard(
          title: 'Tutor',
          subtitle: 'Tutor receiving this payout',
          icon: Icons.school_outlined,
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
        const SizedBox(height: 14),
        _SectionCard(
          title: 'Bank account',
          subtitle: 'Destination account for payOS Chi or QR/manual backup',
          icon: Icons.account_balance_outlined,
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
        const SizedBox(height: 14),
        _SectionCard(
          title: 'Payout information',
          subtitle: 'Amount, status, transfer content, and timestamps',
          icon: Icons.receipt_long_outlined,
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
              statusColor: _statusColor(detail.status),
            ),
            _InfoTile(
              icon: Icons.account_balance_wallet_outlined,
              label: 'Method',
              value: detail.payoutMethod.trim().isEmpty
                  ? 'ManualQr'
                  : detail.payoutMethod,
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
            if (detail.approvedAt != null)
              _InfoTile(
                icon: Icons.verified_outlined,
                label: 'Approved at',
                value: _dateTimeText(detail.approvedAt!),
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
          SizedBox(
            height: 52,
            child: FilledButton.icon(
              onPressed: loading ? null : () => _confirmPayOSChi(context),
              icon: loading
                  ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
                  : const Icon(Icons.payments_outlined),
              label: Text(
                loading ? 'Processing...' : 'Approve with payOS Chi',
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 52,
            child: OutlinedButton.icon(
              onPressed: loading
                  ? null
                  : () => _confirmStatus(
                context,
                status: 'Paid',
                title: 'Mark payout as Paid manually?',
                message:
                'Only confirm this after you have successfully transferred money to the tutor bank account.',
              ),
              icon: const Icon(Icons.check_circle_outline),
              label: const Text(
                'Mark Paid manually',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 52,
            child: OutlinedButton.icon(
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
              label: const Text(
                'Mark Failed',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ),
        ] else if (isProcessing) ...[
          _ProcessingNoticeCard(detail: detail),
          const SizedBox(height: 10),
          SizedBox(
            height: 52,
            child: OutlinedButton.icon(
              onPressed: loading
                  ? null
                  : () => _confirmStatus(
                context,
                status: 'Paid',
                title: 'Mark payout as Paid manually?',
                message:
                'Only confirm this after you have verified the tutor received the money.',
              ),
              icon: const Icon(Icons.check_circle_outline),
              label: const Text(
                'Mark Paid manually',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 52,
            child: OutlinedButton.icon(
              onPressed: loading
                  ? null
                  : () => _confirmStatus(
                context,
                status: 'Failed',
                title: 'Mark payout as Failed?',
                message:
                'Use this if payOS Chi failed and the amount should be returned to the tutor wallet.',
              ),
              icon: const Icon(Icons.cancel_outlined),
              label: const Text(
                'Mark Failed',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ),
        ] else if (isManualQrRequired) ...[
          _ManualQrRequiredNoticeCard(detail: detail),
          const SizedBox(height: 10),
          SizedBox(
            height: 52,
            child: FilledButton.icon(
              onPressed: loading
                  ? null
                  : () => _confirmStatus(
                context,
                status: 'Paid',
                title: 'Confirm manual transfer?',
                message:
                'Only confirm this after you have transferred the payout using QR/bank app.',
              ),
              icon: const Icon(Icons.check_circle_outline),
              label: const Text(
                'I transferred manually',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 52,
            child: OutlinedButton.icon(
              onPressed: loading
                  ? null
                  : () => _confirmStatus(
                context,
                status: 'Failed',
                title: 'Mark payout as Failed?',
                message:
                'The payout amount will be returned to the tutor wallet.',
              ),
              icon: const Icon(Icons.cancel_outlined),
              label: const Text(
                'Mark Failed',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ),
        ] else
          _FinalStatusCard(status: detail.status),
        const SizedBox(height: 24),
      ],
    );
  }

  Future<void> _confirmPayOSChi(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: const Text(
            'Approve with payOS Chi?',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          content: const Text(
            'This will send the payout request to payOS Chi using the tutor bank information. '
                'If it fails, the backend will switch this payout to QR/manual backup.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Approve'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !context.mounted) return;

    await onPayOSChiApprove();
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
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
              ),
              title: Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(message),
                  if (isPaidAction) ...[
                    const SizedBox(height: 16),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.outlineVariant,
                        ),
                      ),
                      child: CheckboxListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        value: confirmedTransfer,
                        onChanged: (value) {
                          setDialogState(() {
                            confirmedTransfer = value ?? false;
                          });
                        },
                        title: const Text(
                          'I confirm this payout has been handled correctly.',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        controlAffinity: ListTileControlAffinity.leading,
                      ),
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

  static bool _hasAnyPayOSChiInfo(AdminPayoutDetailModel detail) {
    return (detail.payOSChiReferenceId ?? '').trim().isNotEmpty ||
        (detail.payOSChiBatchId ?? '').trim().isNotEmpty ||
        (detail.payOSChiPayoutItemId ?? '').trim().isNotEmpty ||
        (detail.payOSChiApprovalState ?? '').trim().isNotEmpty ||
        (detail.payOSChiTransactionState ?? '').trim().isNotEmpty ||
        (detail.payOSChiFailureReason ?? '').trim().isNotEmpty ||
        detail.payoutMethod.toLowerCase() == 'payoschi';
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

class _PayOSChiCard extends StatelessWidget {
  final AdminPayoutDetailModel detail;

  const _PayOSChiCard({
    required this.detail,
  });

  @override
  Widget build(BuildContext context) {
    final status = detail.status.toLowerCase();
    final isManualQrRequired = status == 'manualqrrequired';

    return _SectionCard(
      title: 'payOS Chi',
      subtitle: isManualQrRequired
          ? 'Automatic payout failed. Use QR/manual transfer backup.'
          : 'Automatic payout tracking information',
      icon: isManualQrRequired ? Icons.warning_amber_rounded : Icons.sync_rounded,
      children: [
        _InfoTile(
          icon: Icons.account_balance_wallet_outlined,
          label: 'Payout method',
          value: detail.payoutMethod.trim().isEmpty
              ? 'ManualQr'
              : detail.payoutMethod,
        ),
        if ((detail.payOSChiReferenceId ?? '').trim().isNotEmpty)
          _InfoTile(
            icon: Icons.tag_outlined,
            label: 'Reference ID',
            value: detail.payOSChiReferenceId!,
            copyable: true,
          ),
        if ((detail.payOSChiBatchId ?? '').trim().isNotEmpty)
          _InfoTile(
            icon: Icons.folder_copy_outlined,
            label: 'Batch / payout ID',
            value: detail.payOSChiBatchId!,
            copyable: true,
          ),
        if ((detail.payOSChiPayoutItemId ?? '').trim().isNotEmpty)
          _InfoTile(
            icon: Icons.receipt_long_outlined,
            label: 'Payout item ID',
            value: detail.payOSChiPayoutItemId!,
            copyable: true,
          ),
        if ((detail.payOSChiApprovalState ?? '').trim().isNotEmpty)
          _InfoTile(
            icon: Icons.verified_outlined,
            label: 'Approval state',
            value: detail.payOSChiApprovalState!,
            statusColor: _statusColor(detail.payOSChiApprovalState!),
          ),
        if ((detail.payOSChiTransactionState ?? '').trim().isNotEmpty)
          _InfoTile(
            icon: Icons.sync_alt_outlined,
            label: 'Transaction state',
            value: detail.payOSChiTransactionState!,
            statusColor: _statusColor(detail.payOSChiTransactionState!),
          ),
        if ((detail.payOSChiFailureReason ?? '').trim().isNotEmpty)
          _InfoTile(
            icon: Icons.error_outline,
            label: 'Failure reason',
            value: detail.payOSChiFailureReason!,
            copyable: true,
            statusColor: Colors.deepOrange,
          ),
      ],
    );
  }
}

class _ProcessingNoticeCard extends StatelessWidget {
  final AdminPayoutDetailModel detail;

  const _ProcessingNoticeCard({
    required this.detail,
  });

  @override
  Widget build(BuildContext context) {
    return _NoticeCard(
      icon: Icons.sync_rounded,
      title: 'payOS Chi is processing',
      message:
      'Do not mark this as paid until you verify the payout result. If needed, you can manually confirm or fail the payout.',
      color: Colors.blue,
    );
  }
}

class _ManualQrRequiredNoticeCard extends StatelessWidget {
  final AdminPayoutDetailModel detail;

  const _ManualQrRequiredNoticeCard({
    required this.detail,
  });

  @override
  Widget build(BuildContext context) {
    final reason = detail.payOSChiFailureReason?.trim() ?? '';

    return _NoticeCard(
      icon: Icons.qr_code_2_outlined,
      title: 'QR/manual backup required',
      message: reason.isEmpty
          ? 'Automatic payout failed. Scan the transfer QR or use the tutor bank information to transfer manually.'
          : 'Automatic payout failed: $reason',
      color: Colors.deepOrange,
    );
  }
}

class _NoticeCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final Color color;

  const _NoticeCard({
    required this.icon,
    required this.title,
    required this.message,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      color: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_cardRadius),
        side: BorderSide(color: color.withOpacity(0.35)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SoftIcon(
              icon: icon,
              color: color,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    message,
                    style: TextStyle(
                      color: colors.onSurfaceVariant,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
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
    final colors = Theme.of(context).colorScheme;
    final statusColor = _statusColor(detail.status);
    final status = detail.status.toLowerCase();

    IconData icon;

    if (status == 'paid' || status == 'completed' || status == 'approved') {
      icon = Icons.check_circle_outline;
    } else if (status == 'failed' ||
        status == 'cancelled' ||
        status == 'rejected') {
      icon = Icons.cancel_outlined;
    } else if (status == 'processing') {
      icon = Icons.sync_rounded;
    } else if (status == 'manualqrrequired') {
      icon = Icons.qr_code_2_outlined;
    } else {
      icon = Icons.pending_actions_outlined;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            statusColor.withOpacity(0.16),
            colors.primaryContainer.withOpacity(0.55),
          ],
        ),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        children: [
          _SoftIcon(
            icon: icon,
            color: statusColor,
            size: 64,
          ),
          const SizedBox(height: 14),
          Text(
            'Payout #${detail.payoutId}',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w900,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 8),
          MoneyText(detail.amount),
          const SizedBox(height: 14),
          _StatusPill(
            label: detail.status,
            color: statusColor,
          ),
        ],
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
    final colors = Theme.of(context).colorScheme;

    if (!hasQr) {
      return _SectionCard(
        title: 'Quick transfer QR',
        subtitle: 'QR is unavailable for this payout',
        icon: Icons.qr_code_2_outlined,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.surfaceVariant.withOpacity(0.25),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: colors.outlineVariant),
            ),
            child: Row(
              children: [
                _SoftIcon(
                  icon: Icons.qr_code_2_outlined,
                  color: Colors.orange,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    detail.transferQrNote?.trim().isNotEmpty == true
                        ? detail.transferQrNote!
                        : 'Enter the tutor bank BIN to enable quick money transfer QR.',
                    style: TextStyle(
                      color: colors.onSurfaceVariant,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return _SectionCard(
      title: 'Quick transfer QR',
      subtitle: 'Scan this code to transfer payout money to the tutor',
      icon: Icons.qr_code_2_outlined,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: colors.surfaceVariant.withOpacity(0.22),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: colors.outlineVariant),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
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
                    color: colors.surface,
                    border: Border.all(color: colors.outlineVariant),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    'Unable to load transfer QR',
                    style: TextStyle(color: colors.onSurfaceVariant),
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 12),
        _CopyRow(
          label: 'Transfer content',
          value: _transferContent(detail),
        ),
        const SizedBox(height: 8),
        Text(
          detail.transferQrNote?.trim().isNotEmpty == true
              ? detail.transferQrNote!
              : 'Scan this QR to transfer payout money to the tutor.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: colors.onSurfaceVariant,
            height: 1.35,
          ),
        ),
      ],
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
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: colors.surfaceVariant.withOpacity(0.25),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '$label: $value',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          IconButton.filledTonal(
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
      ),
    );
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
    Color color;

    if (normalized == 'paid' ||
        normalized == 'completed' ||
        normalized == 'approved') {
      icon = Icons.check_circle_outline;
      title = 'Payout is Paid';
      subtitle = 'This payout has been completed and cannot be updated again.';
      color = Colors.green;
    } else if (normalized == 'failed' ||
        normalized == 'cancelled' ||
        normalized == 'rejected') {
      icon = Icons.cancel_outlined;
      title = 'Payout is Failed';
      subtitle =
      'The payout amount was returned to the tutor wallet. This payout cannot be updated again.';
      color = Colors.red;
    } else {
      icon = Icons.info_outline;
      title = 'Payout is $status';
      subtitle = 'No further action is available.';
      color = Colors.blueGrey;
    }

    final colors = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      color: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_cardRadius),
        side: BorderSide(color: colors.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            _SoftIcon(
              icon: icon,
              color: color,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: colors.onSurfaceVariant,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final List<Widget> children;

  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      color: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_cardRadius),
        side: BorderSide(color: colors.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SoftIcon(icon: icon),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
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
  final Color? statusColor;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
    this.copyable = false,
    this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: colors.surfaceVariant.withOpacity(0.22),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.outlineVariant.withOpacity(0.75)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: _SoftIcon(
          icon: icon,
          size: 38,
          color: statusColor,
        ),
        title: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 3),
          child: statusColor == null
              ? Text(
            value,
            style: TextStyle(color: colors.onSurfaceVariant),
          )
              : Align(
            alignment: Alignment.centerLeft,
            child: _StatusPill(
              label: value,
              color: statusColor!,
            ),
          ),
        ),
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
      ),
    );
  }
}

class _SoftIcon extends StatelessWidget {
  final IconData icon;
  final Color? color;
  final double size;

  const _SoftIcon({
    required this.icon,
    this.color,
    this.size = 42,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final accent = color ?? colors.primary;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: accent.withOpacity(0.12),
        borderRadius: BorderRadius.circular(size * 0.34),
      ),
      child: Icon(
        icon,
        color: accent,
        size: size * 0.52,
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusPill({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      color: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_cardRadius),
        side: BorderSide(color: colors.outlineVariant),
      ),
      child: const Padding(
        padding: EdgeInsets.all(32),
        child: Center(child: CircularProgressIndicator()),
      ),
    );
  }
}

Color _statusColor(String status) {
  final normalized = status.toLowerCase();

  if (normalized == 'paid' ||
      normalized == 'completed' ||
      normalized == 'approved' ||
      normalized == 'success' ||
      normalized == 'succeeded') {
    return Colors.green;
  }

  if (normalized == 'processing') {
    return Colors.blue;
  }

  if (normalized == 'manualqrrequired') {
    return Colors.deepOrange;
  }

  if (normalized == 'failed' ||
      normalized == 'cancelled' ||
      normalized == 'rejected' ||
      normalized == 'error') {
    return Colors.red;
  }

  if (normalized == 'pending' || normalized == 'reviewing') {
    return Colors.orange;
  }

  return Colors.blueGrey;
}

String _transferContent(AdminPayoutDetailModel detail) {
  if (detail.transferContent.trim().isNotEmpty) {
    return detail.transferContent.trim();
  }

  return 'EDUNEST PAYOUT ${detail.payoutId}';
}

String _dateTimeText(DateTime value) {
  final local = value.toLocal();

  String two(int number) => number.toString().padLeft(2, '0');

  return '${two(local.day)}/${two(local.month)}/${local.year} '
      '${two(local.hour)}:${two(local.minute)}';
}