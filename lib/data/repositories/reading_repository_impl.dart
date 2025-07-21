import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/repositories/reading_repository.dart';
import '../../domain/entities/reading_progress.dart';
import 'dart:developer' as developer;

class ReadingRepositoryImpl implements ReadingRepository {
  final SharedPreferences _prefs;
  static const String _progressKey = 'reading_progress';
  static const String _currentlyReadingKey = 'currently_reading_books';

  ReadingRepositoryImpl(this._prefs);

  @override
  Future<ReadingProgress?> getReadingProgress(int bookId) async {
    try {
      final progressJson = _prefs.getString('${_progressKey}_$bookId');
      if (progressJson != null) {
        final progressMap = json.decode(progressJson) as Map<String, dynamic>;
        return ReadingProgress(
          bookId: progressMap['bookId'] as int,
          progress: progressMap['progress'] as double,
          currentPosition: progressMap['currentPosition'] as int,
          scrollOffset: progressMap['scrollOffset'] as double,
          lastReadAt: DateTime.parse(progressMap['lastReadAt'] as String),
        );
      }
      return null;
    } catch (e) {
      developer.log('Error getting reading progress: $e');
      return null;
    }
  }

  @override
  Future<void> saveReadingProgress(ReadingProgress progress) async {
    try {
      final progressMap = {
        'bookId': progress.bookId,
        'progress': progress.progress,
        'currentPosition': progress.currentPosition,
        'scrollOffset': progress.scrollOffset,
        'lastReadAt': progress.lastReadAt.toIso8601String(),
      };

      await _prefs.setString(
          '${_progressKey}_${progress.bookId}', json.encode(progressMap));

      // Also update the currently reading books list
      await _addToCurrentlyReading(progress.bookId);
    } catch (e) {
      developer.log('Error saving reading progress: $e');
    }
  }

  @override
  Future<void> updateCurrentPosition(
      int bookId, int position, double progress, double scrollOffset) async {
    try {
      final existingProgress = await getReadingProgress(bookId);
      final updatedProgress = ReadingProgress(
        bookId: bookId,
        progress: progress,
        currentPosition: position,
        scrollOffset: scrollOffset,
        lastReadAt: DateTime.now(),
      );

      await saveReadingProgress(updatedProgress);
    } catch (e) {
      developer.log('Error updating current position: $e');
    }
  }

  @override
  Future<void> addBookmark(int bookId, int position) async {
    try {
      final bookmarksKey = 'bookmarks_$bookId';
      final existingBookmarksJson = _prefs.getString(bookmarksKey);
      List<int> bookmarks = [];

      if (existingBookmarksJson != null) {
        bookmarks = List<int>.from(json.decode(existingBookmarksJson));
      }

      if (!bookmarks.contains(position)) {
        bookmarks.add(position);
        await _prefs.setString(bookmarksKey, json.encode(bookmarks));
      }
    } catch (e) {
      developer.log('Error adding bookmark: $e');
    }
  }

  @override
  Future<void> removeBookmark(int bookId, int position) async {
    try {
      final bookmarksKey = 'bookmarks_$bookId';
      final existingBookmarksJson = _prefs.getString(bookmarksKey);

      if (existingBookmarksJson != null) {
        List<int> bookmarks =
            List<int>.from(json.decode(existingBookmarksJson));
        bookmarks.remove(position);
        await _prefs.setString(bookmarksKey, json.encode(bookmarks));
      }
    } catch (e) {
      developer.log('Error removing bookmark: $e');
    }
  }

  @override
  Future<List<ReadingProgress>> getCurrentlyReadingBooks() async {
    try {
      final currentlyReadingJson = _prefs.getString(_currentlyReadingKey);
      if (currentlyReadingJson != null) {
        final bookIds = List<int>.from(json.decode(currentlyReadingJson));
        List<ReadingProgress> progressList = [];

        for (final bookId in bookIds) {
          final progress = await getReadingProgress(bookId);
          if (progress != null) {
            progressList.add(progress);
          }
        }

        // Sort by last read date (most recent first)
        progressList.sort((a, b) => b.lastReadAt.compareTo(a.lastReadAt));
        return progressList;
      }
      return [];
    } catch (e) {
      developer.log('Error getting currently reading books: $e');
      return [];
    }
  }

  Future<void> _addToCurrentlyReading(int bookId) async {
    try {
      final currentlyReadingJson = _prefs.getString(_currentlyReadingKey);
      List<int> currentlyReading = [];

      if (currentlyReadingJson != null) {
        currentlyReading = List<int>.from(json.decode(currentlyReadingJson));
      }

      if (!currentlyReading.contains(bookId)) {
        currentlyReading.add(bookId);
        await _prefs.setString(
            _currentlyReadingKey, json.encode(currentlyReading));
      }
    } catch (e) {
      developer.log('Error adding to currently reading: $e');
    }
  }

  Future<void> removeFromLibrary(int bookId) async {
    try {
      final currentlyReadingJson = _prefs.getString(_currentlyReadingKey);
      List<int> currentlyReading = [];
      if (currentlyReadingJson != null) {
        currentlyReading = List<int>.from(json.decode(currentlyReadingJson));
      }
      currentlyReading.remove(bookId);
      await _prefs.setString(
          _currentlyReadingKey, json.encode(currentlyReading));
      // Optionally, remove reading progress for this book
      await _prefs.remove('${_progressKey}_$bookId');
    } catch (e) {
      developer.log('Error removing book from library: $e');
    }
  }
}
