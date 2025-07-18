import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Design System Constants
  static const double _cardBorderRadius = 16.0;
  static const double _buttonBorderRadius = 12.0;
  static const double _inputBorderRadius = 12.0;

  // Spacing
  static const double spacing_2xs = 4.0;
  static const double spacing_xs = 8.0;
  static const double spacing_sm = 12.0;
  static const double spacing_md = 16.0;
  static const double spacing_lg = 24.0;
  static const double spacing_xl = 32.0;
  static const double spacing_2xl = 48.0;

  // Elevation
  static const double elevation_none = 0.0;
  static const double elevation_xs = 2.0;
  static const double elevation_sm = 4.0;
  static const double elevation_md = 8.0;
  static const double elevation_lg = 16.0;

  // Animation Durations
  static const Duration duration_short = Duration(milliseconds: 200);
  static const Duration duration_medium = Duration(milliseconds: 300);
  static const Duration duration_long = Duration(milliseconds: 400);

  // Animation Curves
  static const Curve curve_standard = Curves.easeOutCubic;
  static const Curve curve_emphasized = Curves.easeInOutCubic;

  // Light Theme Colors
  static const ColorScheme _lightColorScheme = ColorScheme.light(
    primary: Color(0xFF6750A4), // Deep Purple
    onPrimary: Colors.white,
    primaryContainer: Color(0xFFEADDFF),
    onPrimaryContainer: Color(0xFF21005E),
    secondary: Color(0xFF625B71), // Deep Purple variant
    onSecondary: Colors.white,
    secondaryContainer: Color(0xFFE8DEF8),
    onSecondaryContainer: Color(0xFF1E192B),
    tertiary: Color(0xFF7D5260), // Mauve
    onTertiary: Colors.white,
    tertiaryContainer: Color(0xFFFFD8E4),
    onTertiaryContainer: Color(0xFF31111D),
    error: Color(0xFFB3261E),
    onError: Colors.white,
    errorContainer: Color(0xFFF9DEDC),
    onErrorContainer: Color(0xFF410E0B),
    background: Color(0xFFFFFBFE),
    onBackground: Color(0xFF1C1B1F),
    surface: Color(0xFFFFFBFE),
    onSurface: Color(0xFF1C1B1F),
    surfaceVariant: Color(0xFFE7E0EC),
    onSurfaceVariant: Color(0xFF49454F),
    outline: Color(0xFF79747E),
  );

  // Dark Theme Colors
  static const ColorScheme _darkColorScheme = ColorScheme.dark(
    primary: Color(0xFFD0BCFF), // Light Purple
    onPrimary: Color(0xFF381E72),
    primaryContainer: Color(0xFF4F378B),
    onPrimaryContainer: Color(0xFFEADDFF),
    secondary: Color(0xFFCCC2DC), // Light Purple variant
    onSecondary: Color(0xFF332D41),
    secondaryContainer: Color(0xFF4A4458),
    onSecondaryContainer: Color(0xFFE8DEF8),
    tertiary: Color(0xFFEFB8C8), // Light Mauve
    onTertiary: Color(0xFF492532),
    tertiaryContainer: Color(0xFF633B48),
    onTertiaryContainer: Color(0xFFFFD8E4),
    error: Color(0xFFF2B8B5),
    onError: Color(0xFF601410),
    errorContainer: Color(0xFF8C1D18),
    onErrorContainer: Color(0xFFF9DEDC),
    background: Color(0xFF1C1B1F),
    onBackground: Color(0xFFE6E1E5),
    surface: Color(0xFF1C1B1F),
    onSurface: Color(0xFFE6E1E5),
    surfaceVariant: Color(0xFF49454F),
    onSurfaceVariant: Color(0xFFCAC4D0),
    outline: Color(0xFF938F99),
  );

  static ThemeData get lightTheme {
    return _buildTheme(_lightColorScheme);
  }

  static ThemeData get darkTheme {
    return _buildTheme(_darkColorScheme);
  }

  static ThemeData _buildTheme(ColorScheme colorScheme) {
    final textTheme = _buildTextTheme(colorScheme);

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      brightness: colorScheme.brightness,
      textTheme: textTheme,

      // AppBar Theme
      appBarTheme: AppBarTheme(
        elevation: elevation_none,
        centerTitle: false,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        systemOverlayStyle: colorScheme.brightness == Brightness.light
            ? SystemUiOverlayStyle.dark
            : SystemUiOverlayStyle.light,
        titleTextStyle: textTheme.titleLarge,
      ),

      // Card Theme
      cardTheme: CardTheme(
        elevation: elevation_sm,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_cardBorderRadius),
        ),
        clipBehavior: Clip.antiAlias,
        color: colorScheme.surface,
        margin: const EdgeInsets.all(spacing_xs),
      ),

      // ListTile Theme
      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_buttonBorderRadius),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: spacing_md,
          vertical: spacing_sm,
        ),
      ),

      // Button Themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: elevation_xs,
          padding: const EdgeInsets.symmetric(
            horizontal: spacing_lg,
            vertical: spacing_md,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_buttonBorderRadius),
          ),
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          textStyle: textTheme.labelLarge,
        ),
      ),

      // Input Decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceVariant.withOpacity(0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_inputBorderRadius),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_inputBorderRadius),
          borderSide: BorderSide(
            color: colorScheme.outline.withOpacity(0.3),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_inputBorderRadius),
          borderSide: BorderSide(
            color: colorScheme.primary,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_inputBorderRadius),
          borderSide: BorderSide(
            color: colorScheme.error,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_inputBorderRadius),
          borderSide: BorderSide(
            color: colorScheme.error,
            width: 2,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: spacing_md,
          vertical: spacing_md,
        ),
      ),

      // Chip Theme
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_buttonBorderRadius),
        ),
        side: BorderSide(
          color: colorScheme.outline.withOpacity(0.3),
        ),
        backgroundColor: colorScheme.surface,
        selectedColor: colorScheme.primaryContainer,
        checkmarkColor: colorScheme.onPrimaryContainer,
        labelStyle: textTheme.labelMedium,
        padding: const EdgeInsets.symmetric(
          horizontal: spacing_sm,
          vertical: spacing_2xs,
        ),
      ),

      // Bottom Navigation Bar Theme
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        elevation: elevation_md,
        backgroundColor: colorScheme.surface,
        selectedItemColor: colorScheme.primary,
        unselectedItemColor: colorScheme.onSurfaceVariant,
        type: BottomNavigationBarType.fixed,
        landscapeLayout: BottomNavigationBarLandscapeLayout.centered,
      ),

      // Dialog Theme
      dialogTheme: DialogTheme(
        backgroundColor: colorScheme.surface,
        elevation: elevation_lg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_cardBorderRadius),
        ),
      ),

      // Snackbar Theme
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: colorScheme.inverseSurface,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: colorScheme.onInverseSurface,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_buttonBorderRadius),
        ),
      ),

      // Progress Indicator Theme
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colorScheme.primary,
        linearTrackColor: colorScheme.primary.withOpacity(0.1),
      ),
    );
  }

  static TextTheme _buildTextTheme(ColorScheme colorScheme) {
    final baseTextTheme = GoogleFonts.interTextTheme();

    return baseTextTheme.copyWith(
      displayLarge: baseTextTheme.displayLarge?.copyWith(
        fontSize: 57,
        letterSpacing: -0.25,
        height: 1.12,
        color: colorScheme.onSurface,
      ),
      displayMedium: baseTextTheme.displayMedium?.copyWith(
        fontSize: 45,
        letterSpacing: 0,
        height: 1.16,
        color: colorScheme.onSurface,
      ),
      displaySmall: baseTextTheme.displaySmall?.copyWith(
        fontSize: 36,
        letterSpacing: 0,
        height: 1.22,
        color: colorScheme.onSurface,
      ),
      headlineLarge: baseTextTheme.headlineLarge?.copyWith(
        fontSize: 32,
        letterSpacing: 0,
        height: 1.25,
        color: colorScheme.onSurface,
      ),
      headlineMedium: baseTextTheme.headlineMedium?.copyWith(
        fontSize: 28,
        letterSpacing: 0,
        height: 1.29,
        color: colorScheme.onSurface,
      ),
      headlineSmall: baseTextTheme.headlineSmall?.copyWith(
        fontSize: 24,
        letterSpacing: 0,
        height: 1.33,
        color: colorScheme.onSurface,
      ),
      titleLarge: baseTextTheme.titleLarge?.copyWith(
        fontSize: 22,
        letterSpacing: 0,
        height: 1.27,
        color: colorScheme.onSurface,
      ),
      titleMedium: baseTextTheme.titleMedium?.copyWith(
        fontSize: 16,
        letterSpacing: 0.15,
        height: 1.5,
        fontWeight: FontWeight.w500,
        color: colorScheme.onSurface,
      ),
      titleSmall: baseTextTheme.titleSmall?.copyWith(
        fontSize: 14,
        letterSpacing: 0.1,
        height: 1.43,
        fontWeight: FontWeight.w500,
        color: colorScheme.onSurface,
      ),
      labelLarge: baseTextTheme.labelLarge?.copyWith(
        fontSize: 14,
        letterSpacing: 0.1,
        height: 1.43,
        fontWeight: FontWeight.w500,
        color: colorScheme.onSurface,
      ),
      labelMedium: baseTextTheme.labelMedium?.copyWith(
        fontSize: 12,
        letterSpacing: 0.5,
        height: 1.33,
        fontWeight: FontWeight.w500,
        color: colorScheme.onSurface,
      ),
      labelSmall: baseTextTheme.labelSmall?.copyWith(
        fontSize: 11,
        letterSpacing: 0.5,
        height: 1.45,
        fontWeight: FontWeight.w500,
        color: colorScheme.onSurface,
      ),
      bodyLarge: baseTextTheme.bodyLarge?.copyWith(
        fontSize: 16,
        letterSpacing: 0.5,
        height: 1.5,
        color: colorScheme.onSurface,
      ),
      bodyMedium: baseTextTheme.bodyMedium?.copyWith(
        fontSize: 14,
        letterSpacing: 0.25,
        height: 1.43,
        color: colorScheme.onSurface,
      ),
      bodySmall: baseTextTheme.bodySmall?.copyWith(
        fontSize: 12,
        letterSpacing: 0.4,
        height: 1.33,
        color: colorScheme.onSurface,
      ),
    );
  }

  // Animation Helpers
  static Animation<double> fadeAnimation(AnimationController controller) {
    return Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: controller,
        curve: curve_standard,
      ),
    );
  }

  static Animation<Offset> slideAnimation(
    AnimationController controller, {
    bool reverse = false,
  }) {
    return Tween<Offset>(
      begin: Offset(reverse ? -1.0 : 1.0, 0.0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: controller,
        curve: curve_standard,
      ),
    );
  }

  // Shared Decorations
  static BoxDecoration get cardDecoration {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(_cardBorderRadius),
      boxShadow: const [
        BoxShadow(
          color: Colors.black12,
          offset: Offset(0, 2),
          blurRadius: 4,
          spreadRadius: 0,
        ),
      ],
    );
  }
}
