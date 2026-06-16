import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../utils/vietnam_bank_bins.dart';

class BankBinField extends StatelessWidget {
  final TextEditingController controller;

  const BankBinField({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;

    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: t.bankBin,
        hintText: t.bankBinHint,
        helperText: t.bankBinHelper,
        prefixIcon: const Icon(Icons.qr_code_2_outlined),
        suffixIcon: IconButton(
          tooltip: t.viewBankBinList,
          icon: const Icon(Icons.help_outline),
          onPressed: () => _showBankBinList(context),
        ),
      ),
      validator: (value) {
        final text = value?.trim() ?? '';

        if (text.isEmpty) {
          return t.bankBinRequired;
        }

        final exists = realVietnamBankBins.any((bank) => bank.bin == text);

        if (!exists) {
          return t.validVietnamBankBin;
        }

        return null;
      },
    );
  }

  Future<void> _showBankBinList(BuildContext context) async {
    final selected = await showModalBottomSheet<VietnamBankBin>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) {
        return const _BankBinBottomSheet();
      },
    );

    if (selected == null) return;

    controller.text = selected.bin;
  }
}

class _BankBinBottomSheet extends StatefulWidget {
  const _BankBinBottomSheet();

  @override
  State<_BankBinBottomSheet> createState() => _BankBinBottomSheetState();
}

class _BankBinBottomSheetState extends State<_BankBinBottomSheet> {
  final search = TextEditingController();

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final query = search.text.trim().toLowerCase();

    final banks = realVietnamBankBins.where((bank) {
      if (query.isEmpty) return true;

      return bank.name.toLowerCase().contains(query) ||
          bank.code.toLowerCase().contains(query) ||
          bank.bin.contains(query);
    }).toList();

    return SafeArea(
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.75,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: TextField(
                controller: search,
                decoration: InputDecoration(
                  labelText: t.searchBank,
                  hintText: t.searchBankHint,
                  prefixIcon: const Icon(Icons.search),
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                t.selectRealBankBin,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.separated(
                itemCount: banks.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final bank = banks[index];

                  return ListTile(
                    leading: const Icon(Icons.account_balance_outlined),
                    title: Text(bank.name),
                    subtitle: Text('${bank.code} • BIN ${bank.bin}'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.of(context).pop(bank),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
