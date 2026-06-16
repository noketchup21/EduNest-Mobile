import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_language_provider.dart';
import '../l10n/app_strings.dart';

class LanguageSwitcher extends StatelessWidget {
  final bool showLabel;

  const LanguageSwitcher({
    super.key,
    this.showLabel = false,
  });

  @override
  Widget build(BuildContext context) {
    final language = context.watch<AppLanguageProvider>();
    final strings = context.l10n;

    final control = SegmentedButton<String>(
      showSelectedIcon: false,
      segments: [
        ButtonSegment(
          value: 'vi',
          label: const _LanguageOption(flag: '🇻🇳', code: 'VI'),
          tooltip: strings.vietnamese,
        ),
        ButtonSegment(
          value: 'en',
          label: const _LanguageOption(flag: '🇺🇸', code: 'EN'),
          tooltip: strings.english,
        ),
      ],
      selected: {language.languageCode},
      onSelectionChanged: (selection) {
        language.setLanguageCode(selection.first);
      },
      style: ButtonStyle(
        visualDensity: VisualDensity.compact,
        textStyle: WidgetStateProperty.all(
          const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 0,
          ),
        ),
      ),
    );

    if (!showLabel) return control;

    return Row(
      children: [
        Icon(
          Icons.translate_rounded,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            strings.language,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
        ),
        control,
      ],
    );
  }
}

class _LanguageOption extends StatelessWidget {
  final String flag;
  final String code;

  const _LanguageOption({
    required this.flag,
    required this.code,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(flag, style: const TextStyle(fontSize: 14)),
        const SizedBox(width: 4),
        Text(code),
      ],
    );
  }
}
