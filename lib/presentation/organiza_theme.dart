import 'package:flutter/material.dart';

@immutable
class OrganizaDesignTokens extends ThemeExtension<OrganizaDesignTokens> {
  const OrganizaDesignTokens({
    required this.spaceXs,
    required this.spaceSm,
    required this.spaceMd,
    required this.spaceLg,
    required this.spaceXl,
    required this.radiusSm,
    required this.radiusMd,
    required this.radiusLg,
    required this.minTapTarget,
    required this.quickActionDiameter,
    required this.hairlineThickness,
    required this.navHeight,
    required this.heroSurface,
    required this.heroSurfaceStrong,
    required this.positive,
    required this.warning,
    required this.neutral,
  });

  final double spaceXs;
  final double spaceSm;
  final double spaceMd;
  final double spaceLg;
  final double spaceXl;
  final double radiusSm;
  final double radiusMd;
  final double radiusLg;
  final double minTapTarget;
  final double quickActionDiameter;
  final double hairlineThickness;
  final double navHeight;
  final Color heroSurface;
  final Color heroSurfaceStrong;
  final Color positive;
  final Color warning;
  final Color neutral;

  static OrganizaDesignTokens of(BuildContext context) =>
      Theme.of(context).extension<OrganizaDesignTokens>() ??
      OrganizaDesignTokens.fallback(Theme.of(context).colorScheme);

  factory OrganizaDesignTokens.fallback(ColorScheme scheme) =>
      OrganizaDesignTokens(
        spaceXs: 4,
        spaceSm: 8,
        spaceMd: 16,
        spaceLg: 24,
        spaceXl: 32,
        radiusSm: 10,
        radiusMd: 16,
        radiusLg: 24,
        minTapTarget: 48,
        quickActionDiameter: 56,
        hairlineThickness: 1,
        navHeight: 76,
        heroSurface: scheme.surfaceContainer,
        heroSurfaceStrong: scheme.surfaceContainerHigh,
        positive: scheme.secondary,
        warning: scheme.tertiary,
        neutral: scheme.onSurfaceVariant,
      );

  @override
  OrganizaDesignTokens copyWith({
    double? spaceXs,
    double? spaceSm,
    double? spaceMd,
    double? spaceLg,
    double? spaceXl,
    double? radiusSm,
    double? radiusMd,
    double? radiusLg,
    double? minTapTarget,
    double? quickActionDiameter,
    double? hairlineThickness,
    double? navHeight,
    Color? heroSurface,
    Color? heroSurfaceStrong,
    Color? positive,
    Color? warning,
    Color? neutral,
  }) =>
      OrganizaDesignTokens(
        spaceXs: spaceXs ?? this.spaceXs,
        spaceSm: spaceSm ?? this.spaceSm,
        spaceMd: spaceMd ?? this.spaceMd,
        spaceLg: spaceLg ?? this.spaceLg,
        spaceXl: spaceXl ?? this.spaceXl,
        radiusSm: radiusSm ?? this.radiusSm,
        radiusMd: radiusMd ?? this.radiusMd,
        radiusLg: radiusLg ?? this.radiusLg,
        minTapTarget: minTapTarget ?? this.minTapTarget,
        quickActionDiameter: quickActionDiameter ?? this.quickActionDiameter,
        hairlineThickness: hairlineThickness ?? this.hairlineThickness,
        navHeight: navHeight ?? this.navHeight,
        heroSurface: heroSurface ?? this.heroSurface,
        heroSurfaceStrong: heroSurfaceStrong ?? this.heroSurfaceStrong,
        positive: positive ?? this.positive,
        warning: warning ?? this.warning,
        neutral: neutral ?? this.neutral,
      );

  @override
  OrganizaDesignTokens lerp(
      covariant ThemeExtension<OrganizaDesignTokens>? other, double t) {
    if (other is! OrganizaDesignTokens) return this;
    return OrganizaDesignTokens(
      spaceXs: _lerp(spaceXs, other.spaceXs, t),
      spaceSm: _lerp(spaceSm, other.spaceSm, t),
      spaceMd: _lerp(spaceMd, other.spaceMd, t),
      spaceLg: _lerp(spaceLg, other.spaceLg, t),
      spaceXl: _lerp(spaceXl, other.spaceXl, t),
      radiusSm: _lerp(radiusSm, other.radiusSm, t),
      radiusMd: _lerp(radiusMd, other.radiusMd, t),
      radiusLg: _lerp(radiusLg, other.radiusLg, t),
      minTapTarget: _lerp(minTapTarget, other.minTapTarget, t),
      quickActionDiameter:
          _lerp(quickActionDiameter, other.quickActionDiameter, t),
      hairlineThickness: _lerp(hairlineThickness, other.hairlineThickness, t),
      navHeight: _lerp(navHeight, other.navHeight, t),
      heroSurface: Color.lerp(heroSurface, other.heroSurface, t)!,
      heroSurfaceStrong:
          Color.lerp(heroSurfaceStrong, other.heroSurfaceStrong, t)!,
      positive: Color.lerp(positive, other.positive, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      neutral: Color.lerp(neutral, other.neutral, t)!,
    );
  }

  static double _lerp(double a, double b, double t) => a + (b - a) * t;
}

abstract final class OrganizaTheme {
  // A warm, editorial accent keeps the product distinctive without turning
  // the financial data into decoration. Neutrals deliberately stay quiet.
  static const lime = Color(0xFFB64F21);
  static const green = Color(0xFF1B7548);
  static const red = Color(0xFFB3261E);
  static const orange = Color(0xFFB64F21);
  static const espresso = Color(0xFF231816);
  static const paper = Color(0xFFF8F7F5);

  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  /// Ajustes de densidade e navegação para o fluxo móvel.
  /// Mantém a mesma escolha de tema, mas dá ao celular uma identidade própria
  /// e deixa mais conteúdo visível sem reduzir a legibilidade.
  static ThemeData mobile(ThemeData base) {
    final dark = base.brightness == Brightness.dark;
    final border = base.colorScheme.outline;
    final surface = dark ? const Color(0xFF101114) : const Color(0xFFF7F7FA);
    final card = dark ? const Color(0xFF15161A) : Colors.white;
    final primary = base.colorScheme.primary;
    return base.copyWith(
      scaffoldBackgroundColor: dark ? const Color(0xFF08090B) : surface,
      cardTheme: base.cardTheme.copyWith(
        color: card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(17),
          side: BorderSide(color: border),
        ),
      ),
      appBarTheme: base.appBarTheme.copyWith(
        backgroundColor: dark ? const Color(0xFF08090B) : card,
        elevation: 0,
        scrolledUnderElevation: 0,
        toolbarHeight: 58,
        shape: Border(bottom: BorderSide(color: border)),
      ),
      navigationBarTheme: base.navigationBarTheme.copyWith(
        height: 68,
        backgroundColor: dark ? const Color(0xFF0D0E11) : card,
        indicatorColor:
            dark ? const Color(0xFF3A250D) : primary.withValues(alpha: .14),
        labelTextStyle: WidgetStatePropertyAll(
          TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            color: base.colorScheme.onSurface,
          ),
        ),
      ),
      inputDecorationTheme: base.inputDecorationTheme.copyWith(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primary, width: 1.5),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  static ThemeData _build(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    final primary = dark ? const Color(0xFFFF8A00) : const Color(0xFFB64F21);
    final surface = dark ? const Color(0xFF101114) : const Color(0xFFFFFFFF);
    final border = dark ? const Color(0xFF5F606A) : const Color(0xFF767680);
    final secondary = dark ? const Color(0xFF2ED47A) : const Color(0xFF1B7548);
    final error = dark ? const Color(0xFFFF6675) : const Color(0xFFB3261E);
    final scheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: brightness,
      surface: surface,
      error: error,
    ).copyWith(
      primary: primary,
      onPrimary: dark ? const Color(0xFF17110A) : Colors.white,
      secondary: secondary,
      onSecondary: dark ? const Color(0xFF08170F) : Colors.white,
      tertiary: dark ? const Color(0xFF9B8CFF) : const Color(0xFF7164D8),
      onSurface: dark ? const Color(0xFFF7F3EE) : const Color(0xFF25242B),
      onSurfaceVariant:
          dark ? const Color(0xFFA9A6AD) : const Color(0xFF6F6D78),
      outline: border,
      outlineVariant: border,
      surfaceContainerLowest:
          dark ? const Color(0xFF08090B) : const Color(0xFFFFFFFF),
      surfaceContainerLow:
          dark ? const Color(0xFF101114) : const Color(0xFFF9F9FC),
      surfaceContainer:
          dark ? const Color(0xFF16171A) : const Color(0xFFF2F2F7),
      surfaceContainerHigh:
          dark ? const Color(0xFF202126) : const Color(0xFFECECF2),
      surfaceContainerHighest:
          dark ? const Color(0xFF2B2C32) : const Color(0xFFE4E4EC),
    );
    final focusSide = WidgetStateProperty.resolveWith<BorderSide?>((states) {
      if (states.contains(WidgetState.focused)) {
        return BorderSide(color: primary, width: 2);
      }
      return null;
    });

    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor:
          dark ? const Color(0xFF08090B) : const Color(0xFFF4F4F8),
      dividerColor: border,
      focusColor: primary.withValues(alpha: .22),
      fontFamily: 'Segoe UI Variable',
      visualDensity: VisualDensity.standard,
    );

    return base.copyWith(
      extensions: [
        OrganizaDesignTokens.fallback(scheme).copyWith(
          heroSurface: dark ? const Color(0xFF221A12) : const Color(0xFFFFF1E5),
          heroSurfaceStrong:
              dark ? const Color(0xFF302014) : const Color(0xFFFFE2CC),
          positive: secondary,
          warning: dark ? const Color(0xFFFFC857) : const Color(0xFF8A5A00),
        ),
      ],
      textTheme: base.textTheme.copyWith(
        displaySmall: base.textTheme.displaySmall?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: -1.8,
        ),
        headlineMedium: base.textTheme.headlineMedium?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: -1.1,
        ),
        titleLarge:
            base.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        titleMedium:
            base.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        bodyLarge: base.textTheme.bodyLarge?.copyWith(height: 1.45),
        bodyMedium: base.textTheme.bodyMedium?.copyWith(height: 1.4),
      ),
      cardTheme: CardThemeData(
        elevation: dark ? 0 : .45,
        margin: EdgeInsets.zero,
        color: dark ? const Color(0xFF141518) : Colors.white,
        shadowColor: Colors.black.withValues(alpha: dark ? .04 : .055),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: BorderSide(color: border),
        ),
      ),
      dividerTheme: DividerThemeData(color: border, thickness: 1, space: 1),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: dark ? const Color(0xFF15161A) : const Color(0xFFFFFFFF),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        labelStyle: TextStyle(color: scheme.onSurfaceVariant),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: primary, width: 1.5),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 48),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ).copyWith(side: focusSide),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: dark ? const Color(0xFFFFA52E) : primary,
          minimumSize: const Size(0, 48),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ).copyWith(side: focusSide),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.onSurface,
          minimumSize: const Size(0, 48),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          side: BorderSide(color: border),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ).copyWith(side: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.focused)) {
            return BorderSide(color: primary, width: 2);
          }
          return BorderSide(color: border);
        })),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: const Size(48, 48),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ).copyWith(side: focusSide),
      ),
      chipTheme: base.chipTheme.copyWith(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        side: BorderSide(color: border),
        selectedColor:
            dark ? const Color(0xFF3A250D) : primary.withValues(alpha: .16),
        labelStyle:
            TextStyle(fontWeight: FontWeight.w600, color: scheme.onSurface),
        checkmarkColor: scheme.onSurface,
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? primary
                : Colors.transparent,
          ),
          foregroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? scheme.onPrimary
                : scheme.onSurface,
          ),
          side: WidgetStatePropertyAll(BorderSide(color: border)),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: dark ? const Color(0xFF15161A) : Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(26),
          side: BorderSide(color: border),
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: primary,
        linearTrackColor:
            dark ? const Color(0xFF303138) : const Color(0xFFE9E9EC),
      ),
      scrollbarTheme: ScrollbarThemeData(
        thickness: const WidgetStatePropertyAll(6),
        radius: const Radius.circular(8),
        thumbColor: WidgetStatePropertyAll(
          dark ? const Color(0xFF555762) : const Color(0xFFCBD2CA),
        ),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: dark ? const Color(0xFFF6F0E8) : const Color(0xFF151815),
          borderRadius: BorderRadius.circular(9),
        ),
        textStyle:
            TextStyle(color: dark ? const Color(0xFF151815) : Colors.white),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor:
            dark ? const Color(0xFFEDE7DE) : const Color(0xFF171A17),
        contentTextStyle:
            TextStyle(color: dark ? const Color(0xFF17181B) : Colors.white),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: dark ? const Color(0xFF0B0C0F) : Colors.white,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: .5,
        shape: Border(bottom: BorderSide(color: border)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 74,
        backgroundColor: dark ? const Color(0xFF101114) : Colors.white,
        surfaceTintColor: Colors.transparent,
        indicatorColor:
            dark ? const Color(0xFF3A250D) : primary.withValues(alpha: .14),
        labelTextStyle: WidgetStatePropertyAll(
          TextStyle(fontWeight: FontWeight.w700, color: scheme.onSurface),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: dark ? const Color(0xFF15161A) : Colors.white,
        modalBackgroundColor: dark ? const Color(0xFF15161A) : Colors.white,
        showDragHandle: true,
        dragHandleColor: border,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
        ),
      ),
      drawerTheme: DrawerThemeData(
        backgroundColor: dark ? const Color(0xFF101114) : Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.horizontal(right: Radius.circular(24)),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: dark ? const Color(0xFF1A1B20) : Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: border),
        ),
      ),
    );
  }
}
