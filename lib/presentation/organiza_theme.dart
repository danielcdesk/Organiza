import 'package:flutter/material.dart';

abstract final class OrganizaTheme {
  // A warm, editorial accent keeps the product distinctive without turning
  // the financial data into decoration. Neutrals deliberately stay quiet.
  static const lime = Color(0xFFB85A3B);
  static const green = Color(0xFF258A5A);
  static const red = Color(0xFFC94D4D);
  static const orange = Color(0xFFB85A3B);
  static const espresso = Color(0xFF231816);
  static const paper = Color(0xFFF8F7F5);

  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    final primary = dark ? const Color(0xFFFF9A76) : orange;
    final surface = dark ? const Color(0xFF1B1817) : const Color(0xFFFFFFFF);
    final border = dark ? const Color(0xFF342E2B) : const Color(0xFFE9E3DF);
    final scheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: brightness,
      surface: surface,
      error: red,
    ).copyWith(
      primary: primary,
      onPrimary: dark ? const Color(0xFF301A12) : Colors.white,
      secondary: green,
      onSecondary: Colors.white,
      onSurface: dark ? const Color(0xFFF7F4F2) : const Color(0xFF25211F),
      onSurfaceVariant:
          dark ? const Color(0xFFC7BCB7) : const Color(0xFF716964),
      outline: border,
      outlineVariant: border,
      surfaceContainerLowest:
          dark ? const Color(0xFF151312) : const Color(0xFFFFFFFF),
      surfaceContainerLow:
          dark ? const Color(0xFF1B1817) : const Color(0xFFFDFCFA),
      surfaceContainer:
          dark ? const Color(0xFF211D1B) : const Color(0xFFF5F2EF),
      surfaceContainerHigh:
          dark ? const Color(0xFF2A2421) : const Color(0xFFF0EBE7),
      surfaceContainerHighest:
          dark ? const Color(0xFF332B28) : const Color(0xFFE9E2DD),
    );

    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: dark ? const Color(0xFF131110) : paper,
      dividerColor: border,
      fontFamily: 'Segoe UI Variable',
      visualDensity: VisualDensity.standard,
    );

    return base.copyWith(
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
        color: dark ? const Color(0xFF1E1A18) : Colors.white,
        shadowColor: Colors.black.withValues(alpha: dark ? .04 : .055),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: BorderSide(color: border),
        ),
      ),
      dividerTheme: DividerThemeData(color: border, thickness: 1, space: 1),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: dark ? const Color(0xFF222225) : const Color(0xFFFFFFFF),
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
          minimumSize: const Size(0, 44),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor:
              dark ? const Color(0xFFFF9A70) : const Color(0xFFD9572E),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.onSurface,
          minimumSize: const Size(0, 44),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          side: BorderSide(color: border),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: const Size(44, 44),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        side: BorderSide(color: border),
        selectedColor: primary.withValues(alpha: dark ? .9 : .16),
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
        backgroundColor: dark ? const Color(0xFF1E1A18) : Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(26),
          side: BorderSide(color: border),
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: primary,
        linearTrackColor:
            dark ? const Color(0xFF343438) : const Color(0xFFE9E9EC),
      ),
      scrollbarTheme: ScrollbarThemeData(
        thickness: const WidgetStatePropertyAll(6),
        radius: const Radius.circular(8),
        thumbColor: WidgetStatePropertyAll(
          dark ? const Color(0xFF414941) : const Color(0xFFCBD2CA),
        ),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: dark ? const Color(0xFFF1F4EF) : const Color(0xFF151815),
          borderRadius: BorderRadius.circular(9),
        ),
        textStyle:
            TextStyle(color: dark ? const Color(0xFF151815) : Colors.white),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor:
            dark ? const Color(0xFFE7ECE4) : const Color(0xFF171A17),
        contentTextStyle:
            TextStyle(color: dark ? const Color(0xFF171A17) : Colors.white),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: dark ? const Color(0xFF1B1817) : Colors.white,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: .5,
        shape: Border(bottom: BorderSide(color: border)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 74,
        backgroundColor: dark ? const Color(0xFF1B1817) : Colors.white,
        surfaceTintColor: Colors.transparent,
        indicatorColor: primary.withValues(alpha: dark ? .28 : .14),
        labelTextStyle: WidgetStatePropertyAll(
          TextStyle(fontWeight: FontWeight.w700, color: scheme.onSurface),
        ),
      ),
    );
  }
}
