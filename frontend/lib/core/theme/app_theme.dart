import 'package:flutter/material.dart';

/// Warm, readable surfaces with separate colours for text and dark overlays.
class QB {
  static const bg = Color(0xFFFFF9F3);
  static const surface = Color(0xFFFFFFFF);
  static const raised = Color(0xFFFFFCF8);
  static const text = Color(0xFF29251F);
  static const muted = Color(0xFF6E6258);
  static const border = Color(0xFFE8DCCF);
  static const gold = Color(0xFFB94119);
  static const cream = Color(0xFFFFF8EE);
  static const green = Color(0xFF246447);
  static const red = Color(0xFFB53532);
  static const lift = Color(0xFFF6E9DB);
  static const skeleton = Color(0xFFEFE6DC);
  static const skeletonSheen = Color(0xFFFAF5EE);
  static const mint = Color(0xFFEAF4E9);
  static const peach = Color(0xFFFFECDD);
  static const ink = Color(0xFF203F32);
  static const onDark = Color(0xFFFFFAF2);
  static const mutedOnDark = Color(0xFFD7E4D9);
  static const fire = Color(0xFFEF7646);
  static const ember = Color(0xFFFFC68C);
  static const radius = 24.0;
  static const gap = 20.0;

  static ThemeData get theme {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: 'Inter',
      scaffoldBackgroundColor: bg,
      colorScheme: const ColorScheme.light(
        primary: gold,
        onPrimary: Colors.white,
        primaryContainer: peach,
        onPrimaryContainer: gold,
        secondary: green,
        onSecondary: Colors.white,
        secondaryContainer: mint,
        onSecondaryContainer: green,
        surface: surface,
        onSurface: text,
        onSurfaceVariant: muted,
        outline: Color(0xFFAC9C8E),
        outlineVariant: border,
        error: red,
        onError: Colors.white,
        errorContainer: Color(0xFFFFEAE7),
        onErrorContainer: red,
        inverseSurface: ink,
        onInverseSurface: onDark,
      ),
      visualDensity: VisualDensity.standard,
    );
    // Copy the base styles, then apply colours LAST. Replacing a TextStyle
    // after applying colours was leaving some headings without a text colour.
    final type = base.textTheme.copyWith(
      headlineLarge: base.textTheme.headlineLarge?.copyWith(
        fontSize: 52, fontWeight: FontWeight.w800, height: 1.1,
        letterSpacing: -1.2,
      ),
      headlineMedium: base.textTheme.headlineMedium?.copyWith(
        fontSize: 30, fontWeight: FontWeight.w800, height: 1.2,
        letterSpacing: -.7,
      ),
      titleLarge: base.textTheme.titleLarge?.copyWith(
        fontSize: 22, fontWeight: FontWeight.w700, letterSpacing: -.3,
      ),
      titleMedium: base.textTheme.titleMedium?.copyWith(
        fontSize: 17, fontWeight: FontWeight.w700,
      ),
      titleSmall: base.textTheme.titleSmall?.copyWith(
        fontSize: 14, fontWeight: FontWeight.w600,
      ),
      labelSmall: base.textTheme.labelSmall?.copyWith(
        fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1,
      ),
      bodyLarge: base.textTheme.bodyLarge?.copyWith(fontSize: 16, height: 1.6),
      bodyMedium: base.textTheme.bodyMedium?.copyWith(fontSize: 14, height: 1.55),
      bodySmall: base.textTheme.bodySmall?.copyWith(fontSize: 12, height: 1.5),
    ).apply(bodyColor: text, displayColor: text);

    OutlineInputBorder fieldBorder(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: color, width: width),
        );

    return base.copyWith(
      textTheme: type,
      iconTheme: const IconThemeData(color: muted),
      appBarTheme: const AppBarTheme(
        backgroundColor: bg, foregroundColor: text, elevation: 0,
        scrolledUnderElevation: 0, surfaceTintColor: Colors.transparent,
      ),
      dividerTheme: const DividerThemeData(color: border, thickness: 1),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 19),
        labelStyle: const TextStyle(color: muted, fontSize: 14),
        hintStyle: const TextStyle(color: muted, fontSize: 14),
        floatingLabelStyle: const TextStyle(color: gold, fontWeight: FontWeight.w600),
        errorStyle: const TextStyle(color: red, fontSize: 12),
        prefixIconColor: muted,
        suffixIconColor: muted,
        border: fieldBorder(border),
        enabledBorder: fieldBorder(const Color(0xFFCCBDAF)),
        focusedBorder: fieldBorder(gold, 2),
        errorBorder: fieldBorder(red),
        focusedErrorBorder: fieldBorder(red, 2),
      ),
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: gold, selectionColor: peach, selectionHandleColor: gold,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: gold,
          disabledForegroundColor: muted,
          disabledBackgroundColor: border,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 19),
          minimumSize: const Size(48, 52),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: gold,
          backgroundColor: surface,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 19),
          minimumSize: const Size(48, 52),
          side: const BorderSide(color: border),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: gold,
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surface,
        selectedColor: peach,
        labelStyle: const TextStyle(color: text, fontWeight: FontWeight.w600),
        secondaryLabelStyle: const TextStyle(color: gold, fontWeight: FontWeight.w700),
        checkmarkColor: gold,
        side: const BorderSide(color: border),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: ink,
        contentTextStyle: TextStyle(color: onDark),
        actionTextColor: ember,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: peach,
        iconTheme: WidgetStateProperty.resolveWith((states) => IconThemeData(
          color: states.contains(WidgetState.selected) ? gold : muted,
        )),
        labelTextStyle: WidgetStateProperty.resolveWith((states) => TextStyle(
          fontSize: 12,
          fontWeight: states.contains(WidgetState.selected)
              ? FontWeight.w700 : FontWeight.w500,
          color: states.contains(WidgetState.selected) ? gold : muted,
        )),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(color: gold),
    );
  }
}
