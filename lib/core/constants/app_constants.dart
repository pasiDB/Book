import 'package:flutter/material.dart';

class AppConstants {
  // API Endpoints
  static const String baseUrl = 'https://gutendex.com';
  static const String booksEndpoint = '/books/';
  static const String searchEndpoint = '/books/?search=';
  static const String topicEndpoint = '/books/?topic=';

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

  // Additional Storage Keys
  static const String searchHistoryKey = 'search_history';
  static const String categoryCacheKey = 'category_cache';
  static const String appDataKey = 'app_data';
  static const String firstLaunchKey = 'first_launch_completed';

  // Search/History
  static const int maxSearchHistory = 10;
  static const Duration defaultDebounce = Duration(milliseconds: 400);

  // Book Content
  static const int defaultChunkSize = 3000;

  // UI Padding
  static const double defaultPadding = 16.0;
  static const double defaultSpacing = 24.0;
  static const double defaultIconSize = 24.0;

  // Network Headers
  static const String userAgent = 'BookReader/3.0.0 (Hive-Optimized)';
  static const String acceptHeader = 'application/json';
  static const String connectionHeader = 'keep-alive';

  // Error Messages (for consistency)
  static const String errorTimeout = 'timeout';
  static const String errorConnection = 'connection';
  static const String errorDio = 'DioException';
  static const String errorFailedToFetch = 'Failed to fetch';
  static const String errorBookNotFound = 'Book not found';
  static const String errorNoBooksFound = 'No books found';
  static const String errorUnexpected =
      'An unexpected error occurred. Please try again.';

  // Default Values
  static const double defaultFontSize = 16.0;
  static const double minFontSize = 12.0;
  static const double maxFontSize = 24.0;
  static const double defaultRadius = 8.0;
  static const double minLineHeight = 1.2;
  static const double maxLineHeight = 2.0;
  static const double charWidthEstimate = 0.6;

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
