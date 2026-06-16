import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class MoneyText extends StatelessWidget {
  final num value;
  final TextStyle? style;
  const MoneyText(this.value, {super.key, this.style});

  @override
  Widget build(BuildContext context) {
    final text =
        NumberFormat.currency(locale: 'vi_VN', symbol: '₫').format(value);
    return Text(text, style: style);
  }
}
