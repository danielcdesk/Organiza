import 'package:flutter/material.dart';

abstract final class OrganizaTheme {
  static const lime = Color(0xFFF06D3F);
  static const green = Color(0xFF258A5A);
  static const red = Color(0xFFC94D4D);
  static const orange = Color(0xFFF06D3F);

  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    final primary = dark ? const Color(0xFFFF8A5B) : orange;
    final surface = dark ? const Color(0xFF171719) : const Color(0xFFFFFFFF);
    final border = dark ? const Color(0xFF2A2A2D) : const Color(0xFFE4E6EA);
    final scheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: brightness,
      surface: surface,
      error: red,
    ).copyWith(
      primary: primary,
      onPrimary: Colors.white,
      secondary: green,
      onSecondary: Colors.white,
      onSurface: dark ? const Color(0xFFF4F4F5) : const Color(0xFF1D1D1F),
      onSurfaceVariant:
          dark ? const Color(0xFFB7B7BC) : const Color(0xFF686A70),
      outline: border,
      outlineVariant: border,
      surfaceContainerLowest:
          dark ? const Color(0xFF121214) : const Color(0xFFFFFFFF),
      surfaceContainerLow:
          dark ? const Color(0xFF19191C) : const Color(0xFFFAFAFB),
      surfaceContainer:
          dark ? const Color(0xFF1D1D20) : const Color(0xFFF5F6F8),
      surfaceContainerHigh:
          dark ? const Color(0xFF232327) : const Color(0xFFEFF1F4),
      surfaceContainerHighest:
          dark ? const Color(0xFF2A2A2E) : const Color(0xFFE8EAEE),
    );

    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor:
          dark ? const Color(0xFF111113) : const Color(0xFFF3F4F6),
      dividerColor: border,
      fontFamily: 'Segoe UI Variable',
      visualDensity: VisualDensity.compact,
    );

    return base.copyWith(
      textTheme: base.textTheme.copyWith(
        displaySmall: base.textTheme.displaySmall?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: -1.6,
        ),
        headlineMedium: base.textTheme.headlineMedium?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: -1,
        ),
        titleLarge:
            base.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        titleMedium:
            base.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        bodyLarge: base.textTheme.bodyLarge?.copyWith(height: 1.45),
        bodyMedium: base.textTheme.bodyMedium?.copyWith(height: 1.4),
      ),
      cardTheme: CardThemeData(
        elevation: dark ? 0 : .7,
        margin: EdgeInsets.zero,
        color: dark ? const Color(0xFF1B1B1E) : Colors.white,
        shadowColor: Colors.black.withValues(alpha: dark ? .04 : .08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
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
          borderRadius: BorderRadius.circular(13),
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: BorderSide(color: primary, width: 1.5),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 44),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor:
              dark ? const Color(0xFFFF9A70) : const Color(0xFFD9572E),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.onSurface,
          minimumSize: const Size(0, 44),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          side: BorderSide(color: border),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: const Size(42, 42),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        side: BorderSide(color: border),
        selectedColor: primary.withValues(alpha: dark ? .9 : .16),
        labelStyle: const TextStyle(fontWeight: FontWeight.w600),
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
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: dark ? const Color(0xFF1B1B1E) : Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
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
    );
  }
}
