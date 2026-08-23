import 'package:flutter/material.dart';

/// Namaz Vaktim tasarım sistemi: zümrüt yeşili + altın paleti,
/// gradient tanımları ve light/dark temalar.
abstract final class AppTheme {
  static const Color primary = Color(0xFF0D6B5D);
  static const Color primaryBright = Color(0xFF14947F);
  static const Color primaryDeep = Color(0xFF083F37);
  static const Color gold = Color(0xFFD9B36A);
  static const Color goldSoft = Color(0xFFF0E2C4);
  static const Color cream = Color(0xFFF7F3E8);

  static const Color lightBackground = Color(0xFFF4F1E8);
  static const Color lightCard = Colors.white;
  static const Color darkBackground = Color(0xFF0A1310);
  static const Color darkCard = Color(0xFF142822);
  static const Color darkCardAlt = Color(0xFF1B352D);

  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF17997F), primary, primaryDeep],
    stops: [0.0, 0.55, 1.0],
  );

  static const LinearGradient goldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFE8C989), Color(0xFFC89B4B)],
  );

  static const LinearGradient nextTileGradient = LinearGradient(
    colors: [Color(0xFF116E5F), Color(0xFF0B4A40)],
  );

  static ThemeData light() => _base(Brightness.light);

  static ThemeData dark() => _base(Brightness.dark);

  static ThemeData _base(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: brightness,
    ).copyWith(
      primary: primary,
      secondary: gold,
      surface: isDark ? darkBackground : lightBackground,
      surfaceContainerHighest: isDark ? darkCard : lightCard,
      surfaceContainerHigh: isDark ? darkCardAlt : lightCard,
    );

    final onSurface = isDark ? cream : primaryDeep;

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: onSurface,
          fontSize: 21,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.3,
        ),
        iconTheme: IconThemeData(color: onSurface),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: colorScheme.surfaceContainerHighest,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: .06)
                : primary.withValues(alpha: .08),
          ),
        ),
        margin: EdgeInsets.zero,
      ),
      dividerTheme: DividerThemeData(
        color: (isDark ? Colors.white : primary).withValues(alpha: .12),
        thickness: 1,
        space: 1,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: isDark ? goldSoft : primary,
          side: BorderSide(color: (isDark ? gold : primary).withValues(alpha: .45)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isDark ? darkCardAlt : primaryDeep,
        contentTextStyle: const TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? Colors.white
              : null,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? primary
              : (isDark ? Colors.white24 : Colors.black26),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primary, width: 1.6),
        ),
      ),
      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: (isDark ? gold : primary).withValues(alpha: .12),
        side: BorderSide.none,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        labelStyle: TextStyle(
          color: isDark ? goldSoft : primaryDeep,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
      textTheme: TextTheme(
        titleLarge: TextStyle(
          color: onSurface,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.4,
        ),
        titleMedium: TextStyle(color: onSurface, fontWeight: FontWeight.w700),
        bodyMedium: TextStyle(
          color: isDark ? cream.withValues(alpha: .82) : primaryDeep.withValues(alpha: .82),
        ),
        bodySmall: TextStyle(
          color: isDark ? cream.withValues(alpha: .55) : primaryDeep.withValues(alpha: .55),
        ),
      ),
    );
  }
}
