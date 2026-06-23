import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

@immutable
class EduNestThemeTokens extends ThemeExtension<EduNestThemeTokens> {
  final double space4;
  final double space8;
  final double space12;
  final double space16;
  final double space24;
  final BorderRadius controlRadius;
  final BorderRadius cardRadius;
  final BorderRadius featureCardRadius;
  final BorderRadius pillRadius;
  final Color successColor;
  final Color warningColor;
  final Color sectionDivider;
  final List<BoxShadow> marketplaceShadow;
  final List<BoxShadow> primaryActionShadow;

  const EduNestThemeTokens({
    required this.space4,
    required this.space8,
    required this.space12,
    required this.space16,
    required this.space24,
    required this.controlRadius,
    required this.cardRadius,
    required this.featureCardRadius,
    required this.pillRadius,
    required this.successColor,
    required this.warningColor,
    required this.sectionDivider,
    required this.marketplaceShadow,
    required this.primaryActionShadow,
  });

  factory EduNestThemeTokens.light() => const EduNestThemeTokens(
        space4: 4,
        space8: 8,
        space12: 12,
        space16: 16,
        space24: 24,
        controlRadius: BorderRadius.all(Radius.circular(18)),
        cardRadius: BorderRadius.all(Radius.circular(20)),
        featureCardRadius: BorderRadius.all(Radius.circular(26)),
        pillRadius: BorderRadius.all(Radius.circular(28)),
        successColor: Color(0xFF10B981),
        warningColor: Color(0xFFF59E0B),
        sectionDivider: Color(0xFFEDE9FE),
        marketplaceShadow: [
          BoxShadow(
            color: Color(0x1F4F46E5),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
        primaryActionShadow: [
          BoxShadow(
            color: Color(0x474F46E5),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      );

  factory EduNestThemeTokens.dark() => const EduNestThemeTokens(
        space4: 4,
        space8: 8,
        space12: 12,
        space16: 16,
        space24: 24,
        controlRadius: BorderRadius.all(Radius.circular(18)),
        cardRadius: BorderRadius.all(Radius.circular(20)),
        featureCardRadius: BorderRadius.all(Radius.circular(26)),
        pillRadius: BorderRadius.all(Radius.circular(28)),
        successColor: Color(0xFF34D399),
        warningColor: Color(0xFFFCD34D),
        sectionDivider: Color(0xFF2D2B45),
        marketplaceShadow: [
          BoxShadow(
            color: Color(0x66000000),
            blurRadius: 18,
            offset: Offset(0, 7),
          ),
        ],
        primaryActionShadow: [
          BoxShadow(
            color: Color(0x66818CF8),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      );

  @override
  EduNestThemeTokens copyWith({
    double? space4,
    double? space8,
    double? space12,
    double? space16,
    double? space24,
    BorderRadius? controlRadius,
    BorderRadius? cardRadius,
    BorderRadius? featureCardRadius,
    BorderRadius? pillRadius,
    Color? successColor,
    Color? warningColor,
    Color? sectionDivider,
    List<BoxShadow>? marketplaceShadow,
    List<BoxShadow>? primaryActionShadow,
  }) =>
      EduNestThemeTokens(
        space4: space4 ?? this.space4,
        space8: space8 ?? this.space8,
        space12: space12 ?? this.space12,
        space16: space16 ?? this.space16,
        space24: space24 ?? this.space24,
        controlRadius: controlRadius ?? this.controlRadius,
        cardRadius: cardRadius ?? this.cardRadius,
        featureCardRadius: featureCardRadius ?? this.featureCardRadius,
        pillRadius: pillRadius ?? this.pillRadius,
        successColor: successColor ?? this.successColor,
        warningColor: warningColor ?? this.warningColor,
        sectionDivider: sectionDivider ?? this.sectionDivider,
        marketplaceShadow: marketplaceShadow ?? this.marketplaceShadow,
        primaryActionShadow: primaryActionShadow ?? this.primaryActionShadow,
      );

  @override
  EduNestThemeTokens lerp(EduNestThemeTokens? other, double t) {
    if (other is! EduNestThemeTokens) return this;

    return EduNestThemeTokens(
      space4: lerpDouble(space4, other.space4, t)!,
      space8: lerpDouble(space8, other.space8, t)!,
      space12: lerpDouble(space12, other.space12, t)!,
      space16: lerpDouble(space16, other.space16, t)!,
      space24: lerpDouble(space24, other.space24, t)!,
      controlRadius: BorderRadius.lerp(controlRadius, other.controlRadius, t)!,
      cardRadius: BorderRadius.lerp(cardRadius, other.cardRadius, t)!,
      featureCardRadius:
          BorderRadius.lerp(featureCardRadius, other.featureCardRadius, t)!,
      pillRadius: BorderRadius.lerp(pillRadius, other.pillRadius, t)!,
      successColor: Color.lerp(successColor, other.successColor, t)!,
      warningColor: Color.lerp(warningColor, other.warningColor, t)!,
      sectionDivider: Color.lerp(sectionDivider, other.sectionDivider, t)!,
      marketplaceShadow: t < 0.5 ? marketplaceShadow : other.marketplaceShadow,
      primaryActionShadow:
          t < 0.5 ? primaryActionShadow : other.primaryActionShadow,
    );
  }
}

/// The shared visual system for EduNest.
///
/// Screens should use semantic [ColorScheme] roles and component themes rather
/// than introducing screen-specific colours, radii, or button treatments.
class AppTheme {
  /// Indigo-violet is the EduNest brand and selection color.
  static const primaryBlue = Color(0xFF4F46E5);

  /// Retained name for compatibility; the attention accent is now coral-orange.
  static const accentAmber = Color(0xFFF97316);
  static const successTeal = Color(0xFF10B981);
  static const lightCanvas = Color(0xFFF5F3FF);

  static const _fontFallback = [
    'Roboto',
    'Noto Sans',
    'Arial',
    'Segoe UI',
    'sans-serif',
  ];

  static ThemeData light() => _build(Brightness.light);

  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final tokens =
        isDark ? EduNestThemeTokens.dark() : EduNestThemeTokens.light();
    final seededScheme = ColorScheme.fromSeed(
      seedColor: isDark ? const Color(0xFF818CF8) : primaryBlue,
      brightness: brightness,
      dynamicSchemeVariant: DynamicSchemeVariant.tonalSpot,
    );
    final scheme = isDark
        ? seededScheme.copyWith(
            primary: const Color(0xFF818CF8),
            onPrimary: const Color(0xFF17152B),
            primaryContainer: const Color(0xFF37336D),
            onPrimaryContainer: const Color(0xFFE5E3FF),
            secondary: const Color(0xFFFB923C),
            onSecondary: const Color(0xFF3B1700),
            secondaryContainer: const Color(0xFF65310A),
            onSecondaryContainer: const Color(0xFFFFDCC5),
            tertiary: const Color(0xFF38BDF8),
            onTertiary: const Color(0xFF062B3C),
            tertiaryContainer: const Color(0xFF0C4861),
            onTertiaryContainer: const Color(0xFFC7EEFF),
            surface: const Color(0xFF1C1B2E),
            onSurface: const Color(0xFFF5F3FF),
            surfaceContainerLowest: const Color(0xFF0F0E17),
            surfaceContainerLow: const Color(0xFF151424),
            surfaceContainer: const Color(0xFF201F33),
            surfaceContainerHigh: const Color(0xFF28263C),
            surfaceContainerHighest: const Color(0xFF34314D),
            outlineVariant: const Color(0xFF2D2B45),
          )
        : seededScheme.copyWith(
            primary: primaryBlue,
            onPrimary: Colors.white,
            primaryContainer: const Color(0xFFE4E2FF),
            onPrimaryContainer: const Color(0xFF25205C),
            secondary: accentAmber,
            onSecondary: Colors.white,
            secondaryContainer: const Color(0xFFFFE5D2),
            onSecondaryContainer: const Color(0xFF642500),
            tertiary: const Color(0xFF0EA5E9),
            onTertiary: Colors.white,
            tertiaryContainer: const Color(0xFFD9F1FD),
            onTertiaryContainer: const Color(0xFF064A69),
            surface: Colors.white,
            surfaceContainerLowest: lightCanvas,
            surfaceContainerLow: const Color(0xFFFAF9FF),
            surfaceContainer: const Color(0xFFF6F4FF),
            surfaceContainerHigh: const Color(0xFFF0EEFF),
            surfaceContainerHighest: const Color(0xFFE8E6F7),
            outlineVariant: const Color(0xFFEDE9FE),
          );
    final surface = scheme.surface;
    final canvas = isDark ? const Color(0xFF0F0E17) : lightCanvas;
    final outline = tokens.sectionDivider;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      fontFamilyFallback: _fontFallback,
      scaffoldBackgroundColor: canvas,
      splashFactory: InkSparkle.splashFactory,
      visualDensity: VisualDensity.standard,
      extensions: [
        tokens,
      ],
      appBarTheme: AppBarTheme(
        backgroundColor: canvas,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleSpacing: 20,
        titleTextStyle: TextStyle(
          color: scheme.onSurface,
          fontSize: 23,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.35,
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: outline),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        isDense: false,
        filled: true,
        fillColor: isDark ? scheme.surfaceContainerHigh : Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 17),
        labelStyle: TextStyle(color: scheme.onSurfaceVariant),
        hintStyle:
            TextStyle(color: scheme.onSurfaceVariant.withValues(alpha: 0.78)),
        helperStyle: TextStyle(color: scheme.onSurfaceVariant),
        errorMaxLines: 3,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: scheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: scheme.error, width: 2),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 54),
          padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 15),
          elevation: 3,
          shadowColor: scheme.primary.withValues(alpha: 0.30),
          disabledBackgroundColor: scheme.onSurface.withValues(alpha: 0.12),
          disabledForegroundColor: scheme.onSurface.withValues(alpha: 0.38),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          textStyle: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 52),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          side: BorderSide(color: outline),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
          textStyle: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(44, 44),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: const Size(44, 44),
          shape: const CircleBorder(),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: scheme.surfaceContainerHighest.withValues(alpha: 0.52),
        selectedColor: scheme.secondaryContainer,
        secondarySelectedColor: scheme.secondaryContainer,
        side: BorderSide(color: outline),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        labelStyle: TextStyle(
          color: scheme.onSurfaceVariant,
          fontWeight: FontWeight.w700,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      ),
      dividerTheme: DividerThemeData(color: outline, space: 1, thickness: 1),
      navigationBarTheme: NavigationBarThemeData(
        height: 78,
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        indicatorColor: scheme.primaryContainer,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontSize: 11,
            height: 1.1,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w800
                : FontWeight.w600,
            color: states.contains(WidgetState.selected)
                ? scheme.onSurface
                : scheme.onSurfaceVariant,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? scheme.onPrimaryContainer
                : scheme.onSurfaceVariant,
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: scheme.inverseSurface,
        contentTextStyle: TextStyle(color: scheme.onInverseSurface),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        showDragHandle: true,
      ),
      tabBarTheme: TabBarThemeData(
        dividerColor: Colors.transparent,
        labelColor: scheme.onPrimaryContainer,
        unselectedLabelColor: scheme.onSurfaceVariant,
        labelStyle: const TextStyle(fontWeight: FontWeight.w800),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
    );
  }
}
