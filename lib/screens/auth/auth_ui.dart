import 'package:flutter/material.dart';

import '../../widgets/language_switcher.dart';

const _ink = Color(0xFF0F172A);
const _muted = Color(0xFF64748B);
const _border = Color(0xFFE2E8F0);
const _surface = Colors.white;
const _blue = Color(0xFF2563EB);
const _teal = Color(0xFF0F766E);
const _rose = Color(0xFFFFF1F2);

class AuthScaffold extends StatelessWidget {
  final Widget child;
  final PreferredSizeWidget? appBar;

  const AuthScaffold({
    super.key,
    required this.child,
    this.appBar,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              _rose,
              Color(0xFFF8FAFC),
              Color(0xFFECFDF5),
            ],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(22, 64, 22, 32),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 560),
                    child: child,
                  ),
                ),
              ),
              const Positioned(
                top: 10,
                right: 14,
                child: LanguageSwitcher(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AuthLogoLockup extends StatelessWidget {
  const AuthLogoLockup({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 76,
          height: 76,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: _border),
            boxShadow: const [
              BoxShadow(
                color: Color(0x1A2563EB),
                blurRadius: 30,
                offset: Offset(0, 16),
              ),
            ],
          ),
          child: Image.asset(
            'assets/images/Logo.png',
            errorBuilder: (context, error, stackTrace) =>
                const Icon(Icons.school_rounded, color: _blue, size: 44),
          ),
        ),
        const SizedBox(width: 14),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'EduNest',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: _ink,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
            ),
          ],
        ),
      ],
    );
  }
}

class AuthPanel extends StatelessWidget {
  final Widget child;

  const AuthPanel({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: _border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x140F172A),
            blurRadius: 34,
            offset: Offset(0, 20),
          ),
        ],
      ),
      child: child,
    );
  }
}

class AuthHeader extends StatelessWidget {
  final IconData icon;
  final String eyebrow;
  final String title;
  final String? subtitle;
  final Color color;

  const AuthHeader({
    super.key,
    required this.icon,
    required this.eyebrow,
    required this.title,
    this.subtitle,
    this.color = _blue,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 17, color: color),
              const SizedBox(width: 6),
              Text(
                eyebrow,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Text(
          title,
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                color: _ink,
                fontWeight: FontWeight.w900,
                height: 1.05,
              ),
        ),
        if (subtitle != null && subtitle!.trim().isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            subtitle!,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: _muted,
                  height: 1.35,
                ),
          ),
        ],
      ],
    );
  }
}

class AuthChoiceCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Color color;
  final VoidCallback onTap;

  const AuthChoiceCard({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.color = _blue,
  });

  @override
  State<AuthChoiceCard> createState() => _AuthChoiceCardState();
}

class _AuthChoiceCardState extends State<AuthChoiceCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _pressed ? 0.98 : 1,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: widget.onTap,
          onTapCancel: () => setState(() => _pressed = false),
          onTapDown: (_) => setState(() => _pressed = true),
          onTapUp: (_) => setState(() => _pressed = false),
          child: Ink(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: widget.color.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: widget.color.withValues(alpha: 0.24)),
            ),
            child: Row(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: widget.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(widget.icon, color: widget.color),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: _ink,
                                  fontWeight: FontWeight.w900,
                                ),
                      ),
                      if (widget.subtitle != null &&
                          widget.subtitle!.trim().isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          widget.subtitle!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: _muted,
                                    height: 1.2,
                                  ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: _surface,
                    borderRadius: BorderRadius.circular(10),
                    border:
                        Border.all(color: widget.color.withValues(alpha: 0.18)),
                  ),
                  child: Icon(
                    Icons.arrow_forward_rounded,
                    color: widget.color,
                    size: 19,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class AuthTextField extends StatelessWidget {
  final TextEditingController controller;
  final String labelText;
  final String? hintText;
  final IconData icon;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;
  final int? minLines;
  final int? maxLines;

  const AuthTextField({
    super.key,
    required this.controller,
    required this.labelText,
    required this.icon,
    this.hintText,
    this.keyboardType,
    this.obscureText = false,
    this.suffixIcon,
    this.validator,
    this.minLines,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        prefixIcon: Icon(icon),
        suffixIcon: suffixIcon,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      ),
      keyboardType: keyboardType,
      obscureText: obscureText,
      validator: validator,
      minLines: minLines,
      maxLines: obscureText ? 1 : maxLines,
    );
  }
}

class AuthLinkButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;

  const AuthLinkButton({
    super.key,
    required this.label,
    required this.icon,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: TextButton.styleFrom(
        foregroundColor: _blue,
        textStyle: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

Color authAccentForTutor(bool isTutor) => isTutor ? _teal : _blue;
