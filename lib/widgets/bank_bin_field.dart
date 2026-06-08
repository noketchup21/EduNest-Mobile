import 'package:flutter/material.dart';

import '../utils/vietnam_bank_bins.dart';

class BankBinField extends StatelessWidget {
  final TextEditingController controller;

  const BankBinField({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: 'Bank BIN',
        hintText: 'Example: 970422',
        helperText: 'Required for automatic payout and quick transfer QR.',
        prefixIcon: const Icon(Icons.qr_code_2_outlined),
        suffixIcon: IconButton(
          tooltip: 'View bank BIN list',
          icon: const Icon(Icons.help_outline),
          onPressed: () => _showBankBinList(context),
        ),
      ),
      validator: (value) {
        final text = value?.trim() ?? '';

        if (text.isEmpty) {
          return 'Bank BIN is required';
        }

        final exists = realVietnamBankBins.any((bank) => bank.bin == text);

        if (!exists) {
          return 'Please select a valid Vietnamese bank BIN';
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
                decoration: const InputDecoration(
                  labelText: 'Search bank',
                  hintText: 'Search by name, code, or BIN',
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Select the BIN of the tutor real bank account. Do not use wallet/payment app BINs.',
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