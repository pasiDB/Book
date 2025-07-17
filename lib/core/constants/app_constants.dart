import 'package:flutter/material.dart';

class AppConstants {
  // API Endpoints
  static const String baseUrl = 'https://openlibrary.org';
  static const String booksEndpoint =
      '/search.json'; // Open Library search endpoint
  static const String searchEndpoint =
      '/search.json?q='; // Open Library search endpoint with query
  static const String topicEndpoint =
      '/subjects/'; // Open Library subject endpoint, e.g., /subjects/fiction.json

  // Book Categories/Topics
  static const List<String> bookCategories = [
    'fiction',
    'science',
    'history',
    'philosophy',
    'poetry',
    'drama',
    'biography',
    'adventure',
    'romance',
    'mystery',
  ];

  // Storage Keys
  static const String themeKey = 'theme_mode';
  static const String fontSizeKey = 'font_size';
  static const String downloadedBooksKey = 'downloaded_books';
  static const String currentlyReadingKey = 'currently_reading';
  static const String bookmarksKey = 'bookmarks';

  // Default Values
  static const double defaultFontSize = 16.0;
  static const double minFontSize = 12.0;
  static const double maxFontSize = 24.0;

  // UI Constants
  static const double cardRadius = 12.0;
  static const double buttonRadius = 8.0;
  static const Duration animationDuration = Duration(milliseconds: 300);

  // Colors
  static const Color primaryColor = Color(0xFF2196F3);
  static const Color secondaryColor = Color(0xFF1976D2);
  static const Color accentColor = Color(0xFF64B5F6);
  static const Color errorColor = Color(0xFFD32F2F);
  static const Color successColor = Color(0xFF388E3C);
  static const Color warningColor = Color(0xFFFFA000);

  // Light Theme Colors
  static const Color lightBackground = Color(0xFFFAFAFA);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightOnSurface = Color(0xFF212121);
  static const Color lightOnBackground = Color(0xFF424242);

  // Dark Theme Colors
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF1E1E1E);
  static const Color darkOnSurface = Color(0xFFFFFFFF);
  static const Color darkOnBackground = Color(0xFFE0E0E0);
}
