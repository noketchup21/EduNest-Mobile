import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

enum AppSurfaceCardKind { content, marketplace, hero }

/// A reusable surface for cards and grouped content.
///
/// It keeps padding, outline, radius, and press feedback consistent across the
/// learner, tutor, and administrator areas without owning any business logic.
class AppSurfaceCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? color;
  final BorderRadius? borderRadius;
  final AppSurfaceCardKind kind;

  const AppSurfaceCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.color,
    this.borderRadius,
    this.kind = AppSurfaceCardKind.content,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final tokens = Theme.of(context).extension<EduNestThemeTokens>() ??
        EduNestThemeTokens.light();
    final isMarketplace = kind == AppSurfaceCardKind.marketplace;
    final isHero = kind == AppSurfaceCardKind.hero;
    final resolvedRadius = borderRadius ??
        (isMarketplace || isHero
            ? tokens.featureCardRadius
            : tokens.cardRadius);

    return Container(
      decoration: BoxDecoration(
        borderRadius: resolvedRadius,
        boxShadow: isMarketplace ? tokens.marketplaceShadow : null,
      ),
      child: Material(
        color: color ?? colors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: isMarketplace ? 2 : 0,
        shadowColor: colors.shadow.withValues(alpha: 0.18),
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: resolvedRadius,
          side: isMarketplace || isHero
              ? BorderSide.none
              : BorderSide(color: tokens.sectionDivider),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: resolvedRadius,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

/// Reserved for high-attention areas such as a profile header, a dashboard
/// hero, or a payment summary. List rows should use [AppSurfaceCard] instead.
class AppHeroCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Gradient? gradient;

  const AppHeroCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final tokens = Theme.of(context).extension<EduNestThemeTokens>() ??
        EduNestThemeTokens.light();

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        gradient: gradient ??
            LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                colors.primary,
                colors.primary.withValues(alpha: 0.84),
                colors.tertiary,
              ],
            ),
        borderRadius: tokens.featureCardRadius,
        boxShadow: tokens.primaryActionShadow,
      ),
      child: child,
    );
  }
}

class AppSectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? action;
  final IconData? icon;
  final AppStatusTone tone;

  const AppSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.action,
    this.icon,
    this.tone = AppStatusTone.info,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final iconPalette = _statusPalette(context, tone);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (icon != null) ...[
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: iconPalette.$1,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: iconPalette.$2, size: 18),
          ),
          const SizedBox(width: 12),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (subtitle != null && subtitle!.trim().isNotEmpty) ...[
                const SizedBox(height: 3),
                Text(
                  subtitle!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (action != null) ...[
          const SizedBox(width: 12),
          action!,
        ],
      ],
    );
  }
}

class AppEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  const AppEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return AppSurfaceCard(
      kind: AppSurfaceCardKind.content,
      padding: const EdgeInsets.all(24),
      child: Semantics(
        liveRegion: true,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: colors.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: colors.onPrimaryContainer, size: 30),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
            if (action != null) ...[
              const SizedBox(height: 16),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

enum AppStatusTone { success, warning, danger, neutral, info }

class AppStatusBadge extends StatelessWidget {
  final String label;
  final AppStatusTone tone;
  final IconData? icon;

  const AppStatusBadge({
    super.key,
    required this.label,
    this.tone = AppStatusTone.info,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final palette = _statusPalette(context, tone);
    final resolvedIcon = icon ?? _statusIcon(tone);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: palette.$1,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(resolvedIcon, size: 16, color: palette.$2),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: palette.$2,
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class AppMetaChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const AppMetaChip({
    super.key,
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      constraints: const BoxConstraints(minHeight: 30),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withValues(alpha: 0.56),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: colors.onSurfaceVariant),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class AppMetricCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final AppStatusTone tone;
  final String? helper;

  const AppMetricCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.tone = AppStatusTone.info,
    this.helper,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final palette = _statusPalette(context, tone);

    return AppSurfaceCard(
      kind: AppSurfaceCardKind.marketplace,
      padding: const EdgeInsets.all(16),
      color: palette.$1.withValues(alpha: 0.62),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: palette.$1,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, size: 20, color: palette.$2),
          ),
          const Spacer(),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: colors.onSurface,
                ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: colors.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
          ),
          if (helper != null && helper!.trim().isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              helper!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: palette.$2,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
        ],
      ),
    );
  }
}

class AppLoadingState extends StatefulWidget {
  final String? label;
  final EdgeInsetsGeometry padding;

  const AppLoadingState({
    super.key,
    this.label,
    this.padding = const EdgeInsets.symmetric(vertical: 48),
  });

  @override
  State<AppLoadingState> createState() => _AppLoadingStateState();
}

class _AppLoadingStateState extends State<AppLoadingState>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      liveRegion: true,
      label: widget.label ?? 'Loading',
      child: Padding(
        padding: widget.padding,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Opacity(
                opacity: 0.48 + (_controller.value * 0.42),
                child: Column(
                  children: [
                    Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        color: colors.primaryContainer,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.auto_awesome_rounded,
                        color: colors.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      width: 176,
                      height: 12,
                      decoration: BoxDecoration(
                        color: colors.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 124,
                      height: 10,
                      decoration: BoxDecoration(
                        color: colors.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  ],
                ),
              ),
              if (widget.label != null && widget.label!.trim().isNotEmpty) ...[
                const SizedBox(height: 14),
                Text(
                  widget.label!,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

(Color, Color) _statusPalette(BuildContext context, AppStatusTone tone) {
  final colors = Theme.of(context).colorScheme;
  final tokens = Theme.of(context).extension<EduNestThemeTokens>() ??
      EduNestThemeTokens.light();

  return switch (tone) {
    AppStatusTone.success => (
        tokens.successColor.withValues(alpha: 0.14),
        tokens.successColor,
      ),
    AppStatusTone.warning => (
        tokens.warningColor.withValues(alpha: 0.16),
        tokens.warningColor,
      ),
    AppStatusTone.danger => (colors.errorContainer, colors.onErrorContainer),
    AppStatusTone.neutral => (
        colors.surfaceContainerHighest,
        colors.onSurfaceVariant
      ),
    AppStatusTone.info => (colors.primaryContainer, colors.onPrimaryContainer),
  };
}

IconData _statusIcon(AppStatusTone tone) {
  return switch (tone) {
    AppStatusTone.success => Icons.check_circle_rounded,
    AppStatusTone.warning => Icons.hourglass_top_rounded,
    AppStatusTone.danger => Icons.cancel_rounded,
    AppStatusTone.neutral => Icons.info_outline_rounded,
    AppStatusTone.info => Icons.schedule_rounded,
  };
}

class AppRating extends StatelessWidget {
  final double rating;
  final int? count;
  final String emptyLabel;

  const AppRating({
    super.key,
    required this.rating,
    this.count,
    this.emptyLabel = 'New',
  });

  @override
  Widget build(BuildContext context) {
    final hasRating = rating > 0;
    final label = hasRating ? rating.toStringAsFixed(1) : emptyLabel;

    return AppMetaChip(
      icon: hasRating ? Icons.star_rounded : Icons.auto_awesome_outlined,
      label: count == null || count == 0 ? label : '$label ($count)',
    );
  }
}
