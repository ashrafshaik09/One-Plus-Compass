import 'package:flutter/material.dart';

class AppTheme {
  // Primary colors
  static const Color primaryColor = Color(0xFF6750A4);
  static const Color secondaryColor = Color(0xFFD0BCFF);
  static const Color backgroundColor = Colors.white;
  static const Color accentColor = Color(0xFF7E57C2);
  
  // Text colors
  static const Color textPrimary = Color(0xFF1D1B20);
  static const Color textSecondary = Color(0xFF49454F);
  static const Color textLight = Color(0xFF79747E);
  
  // Additional colors
  static const Color qiblaColor = Color(0xFF4CAF50);
  static const Color cardBackground = Color(0xFFF7F2FA);
  static const Color elevationBackgroundColor = Color(0xFFEADDFF);
  
  // Gradient colors
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF9C89B8), Color(0xFF6750A4)],
  );

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: backgroundColor,
      appBarTheme: const AppBarTheme(
        backgroundColor: backgroundColor,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: textPrimary),
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      tabBarTheme: const TabBarTheme(
        labelColor: primaryColor,
        unselectedLabelColor: textLight,
        indicatorColor: primaryColor,
      ),
      cardTheme: CardTheme(
        color: cardBackground,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
        ),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          color: textPrimary,
          fontSize: 32,
          fontWeight: FontWeight.bold,
        ),
        displayMedium: TextStyle(
          color: textPrimary,
          fontSize: 24,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: TextStyle(
          color: textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.normal,
        ),
        bodyMedium: TextStyle(
          color: textSecondary,
          fontSize: 14,
          fontWeight: FontWeight.normal,
        ),
        labelLarge: TextStyle(
          color: primaryColor,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
