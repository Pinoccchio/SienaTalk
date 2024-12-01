import 'package:flutter/material.dart';

class AppTheme {
  // Brand Colors
  static const Color primaryRed = Color(0xFFAA0000);
  static const Color accentYellow = Color(0xFFFFD700);
  static const Color pureWhite = Colors.white;
  static const Color darkGrey = Color(0xFF333333);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryRed,
        brightness: Brightness.light,
        primary: primaryRed,
        secondary: accentYellow,
        onPrimary: pureWhite,
        background: pureWhite,
        surface: pureWhite,
      ),
      scaffoldBackgroundColor: pureWhite,
      appBarTheme: AppBarTheme(
        elevation: 0,
        backgroundColor: primaryRed,
        foregroundColor: pureWhite,
        iconTheme: IconThemeData(color: pureWhite),
        titleTextStyle: TextStyle(
          color: pureWhite,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
      cardTheme: CardTheme(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        color: pureWhite,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          foregroundColor: pureWhite,
          backgroundColor: primaryRed,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          textStyle: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
      textTheme: TextTheme(
        headline1: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: primaryRed,
          letterSpacing: 0.5,
        ),
        headline6: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: primaryRed,
          letterSpacing: 0.5,
        ),
        bodyText1: TextStyle(
          fontSize: 16,
          color: darkGrey,
          letterSpacing: 0.3,
        ),
        bodyText2: TextStyle(
          fontSize: 14,
          color: darkGrey,
          letterSpacing: 0.3,
        ),
        subtitle1: TextStyle(
          fontSize: 16,
          color: accentYellow,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.grey[100],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: primaryRed, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
      ),
      iconTheme: IconThemeData(
        color: primaryRed,
        size: 24,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: pureWhite,
        selectedItemColor: primaryRed,
        unselectedItemColor: darkGrey,
        elevation: 8,
        type: BottomNavigationBarType.fixed,
      ),
      dividerTheme: DividerThemeData(
        color: Colors.grey[300],
        thickness: 1,
      ),
    );
  }
}

