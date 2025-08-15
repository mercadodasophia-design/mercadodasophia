import 'package:flutter/material.dart';

class AppTheme {
  // Cores principais baseadas na logo
  static const Color primaryColor = Color(0xFFE91E63); // Rosa vibrante da logo
  static const Color secondaryColor = Color(0xFFF48FB1); // Rosa claro
  static const Color accentColor = Color(0xFFC2185B); // Rosa escuro
  static const Color backgroundColor = Color(0xFFFFFFFF); // Branco
  static const Color surfaceColor = Color(0xFFF8F9FA); // Cinza muito claro
  static const Color textPrimaryColor = Color(0xFF212121); // Preto suave
  static const Color textSecondaryColor = Color(0xFF757575); // Cinza médio
  static const Color textLightColor = Color(0xFFBDBDBD); // Cinza claro
  static const Color successColor = Color(0xFF4CAF50); // Verde
  static const Color warningColor = Color(0xFFFF9800); // Laranja
  static const Color errorColor = Color(0xFFF44336); // Vermelho

  // Gradientes
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryColor, secondaryColor],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient secondaryGradient = LinearGradient(
    colors: [secondaryColor, Color(0xFFFCE4EC)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Tema claro
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    
    // ColorScheme
    colorScheme: const ColorScheme.light(
      primary: primaryColor,
      secondary: secondaryColor,
      surface: surfaceColor,
      background: backgroundColor,
      error: errorColor,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: textPrimaryColor,
      onError: Colors.white,
    ),

    // AppBar Theme
    appBarTheme: const AppBarTheme(
      surfaceTintColor: primaryColor,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.bold,
        fontFamily: 'Roboto',
      ),
      iconTheme: IconThemeData(color: Colors.white),
    ),

    // Card Theme
    cardTheme: CardThemeData(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: backgroundColor,
      shadowColor: primaryColor.withValues(alpha: 0.1),
    ),

    // Elevated Button Theme
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 2,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          fontFamily: 'Roboto',
        ),
      ),
    ),

    // Text Button Theme
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primaryColor,
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          fontFamily: 'Roboto',
        ),
      ),
    ),

    // Outlined Button Theme
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryColor,
        side: const BorderSide(color: primaryColor, width: 2),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          fontFamily: 'Roboto',
        ),
      ),
    ),

    // Floating Action Button Theme
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
      elevation: 4,
    ),

    // Chip Theme
    chipTheme: ChipThemeData(
      backgroundColor: surfaceColor,
      selectedColor: primaryColor,
      labelStyle: const TextStyle(
        color: textPrimaryColor,
        fontFamily: 'Roboto',
      ),
      secondaryLabelStyle: const TextStyle(
        color: Colors.white,
        fontFamily: 'Roboto',
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
    ),

    // Input Decoration Theme
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surfaceColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: textLightColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: primaryColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: errorColor),
      ),
      labelStyle: const TextStyle(
        color: textSecondaryColor,
        fontFamily: 'Roboto',
      ),
      hintStyle: const TextStyle(
        color: textLightColor,
        fontFamily: 'Roboto',
      ),
      prefixIconColor: textSecondaryColor,
      suffixIconColor: textSecondaryColor,
    ),

    // Text Theme
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: textPrimaryColor,
        fontFamily: 'Roboto',
      ),
      displayMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: textPrimaryColor,
        fontFamily: 'Roboto',
      ),
      displaySmall: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: textPrimaryColor,
        fontFamily: 'Roboto',
      ),
      headlineLarge: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: textPrimaryColor,
        fontFamily: 'Roboto',
      ),
      headlineMedium: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: textPrimaryColor,
        fontFamily: 'Roboto',
      ),
      headlineSmall: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: textPrimaryColor,
        fontFamily: 'Roboto',
      ),
      titleLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: textPrimaryColor,
        fontFamily: 'Roboto',
      ),
      titleMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: textPrimaryColor,
        fontFamily: 'Roboto',
      ),
      titleSmall: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: textSecondaryColor,
        fontFamily: 'Roboto',
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.normal,
        color: textPrimaryColor,
        fontFamily: 'Roboto',
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.normal,
        color: textPrimaryColor,
        fontFamily: 'Roboto',
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.normal,
        color: textSecondaryColor,
        fontFamily: 'Roboto',
      ),
      labelLarge: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: textPrimaryColor,
        fontFamily: 'Roboto',
      ),
      labelMedium: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: textSecondaryColor,
        fontFamily: 'Roboto',
      ),
      labelSmall: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w500,
        color: textLightColor,
        fontFamily: 'Roboto',
      ),
    ),

    // Icon Theme
    iconTheme: const IconThemeData(
      color: textSecondaryColor,
      size: 24,
    ),

    // Divider Theme
    dividerTheme: const DividerThemeData(
      color: textLightColor,
      thickness: 1,
      space: 1,
    ),

    // Bottom Navigation Bar Theme
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: backgroundColor,
      selectedItemColor: primaryColor,
      unselectedItemColor: textSecondaryColor,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
    ),

    // SnackBar Theme
    snackBarTheme: SnackBarThemeData(
      backgroundColor: primaryColor,
      contentTextStyle: const TextStyle(
        color: Colors.white,
        fontFamily: 'Roboto',
        fontSize: 14,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    ),

    // Progress Indicator Theme
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: primaryColor,
      linearTrackColor: textLightColor,
    ),
  );

  // Tema escuro (opcional para futuro)
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    
    colorScheme: const ColorScheme.dark(
      primary: primaryColor,
      secondary: secondaryColor,
      surface: Color(0xFF424242),
      background: Color(0xFF121212),
      error: errorColor,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: Colors.white,
      onError: Colors.white,
    ),
  );
} 