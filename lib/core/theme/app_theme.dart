import 'package:flutter/material.dart';
import '../constants/app_constants.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      primaryColor: Color(0xFF6750A4),
      colorScheme: ColorScheme.light(
        primary: Color(0xFF6750A4),
        secondary: Color(0xFF00BFAE),
        background: Color(0xFFF8F9FA),
        surface: Colors.white,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onBackground: Color(0xFF1A1C1E),
        onSurface: Color(0xFF1A1C1E),
      ),
      fontFamily: 'Inter',
      scaffoldBackgroundColor: Color(0xFFF8F9FA),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.white,
        elevation: 1,
        titleTextStyle: TextStyle(
          color: Color(0xFF1A1C1E),
          fontWeight: FontWeight.bold,
          fontSize: 22,
        ),
        iconTheme: IconThemeData(color: Color(0xFF6750A4)),
      ),
      cardTheme: CardTheme(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 3,
        margin: EdgeInsets.symmetric(vertical: 8, horizontal: 0),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
          textStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: Color(0xFFE0E0E0),
        labelStyle:
            TextStyle(color: Color(0xFF1A1C1E), fontWeight: FontWeight.w500),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        selectedColor: Color(0xFF6750A4),
        secondarySelectedColor: Color(0xFF00BFAE),
        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
      dividerTheme: DividerThemeData(
        color: Color(0xFFE0E0E0),
        thickness: 1,
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: Color(0xFF6750A4),
      colorScheme: ColorScheme.dark(
        primary: Color(0xFF6750A4),
        secondary: Color(0xFF00BFAE),
        background: Color(0xFF181A20),
        surface: Color(0xFF23262F),
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onBackground: Colors.white,
        onSurface: Colors.white,
      ),
      fontFamily: 'Inter',
      scaffoldBackgroundColor: Color(0xFF181A20),
      appBarTheme: AppBarTheme(
        backgroundColor: Color(0xFF23262F),
        elevation: 1,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 22,
        ),
        iconTheme: IconThemeData(color: Color(0xFF00BFAE)),
      ),
      cardTheme: CardTheme(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 3,
        margin: EdgeInsets.symmetric(vertical: 8, horizontal: 0),
        color: Color(0xFF23262F),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
          textStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: Color(0xFF23262F),
        labelStyle: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        selectedColor: Color(0xFF6750A4),
        secondarySelectedColor: Color(0xFF00BFAE),
        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: Color(0xFF23262F),
      ),
      dividerTheme: DividerThemeData(
        color: Color(0xFF23262F),
        thickness: 1,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Color(0xCC23262F), // slightly translucent
        selectedItemColor: Color(0xFF6750A4), // purple
        unselectedItemColor: Colors.white70,
        elevation: 12,
        type: BottomNavigationBarType.fixed,
        selectedIconTheme: IconThemeData(size: 28, color: Color(0xFF6750A4)),
        unselectedIconTheme: IconThemeData(size: 24, color: Colors.white70),
        showUnselectedLabels: true,
      ),
    );
  }
}
