import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/book_model.dart';

abstract class BookLocalDataSource {
  Future<void> cacheBooks(String key, List<BookModel> books);
  Future<List<BookModel>> getCachedBooks(String key);
  Future<void> clearCache();
}

class BookLocalDataSourceImpl implements BookLocalDataSource {
  final SharedPreferences sharedPreferences;

  BookLocalDataSourceImpl(this.sharedPreferences);

  @override
  Future<void> cacheBooks(String key, List<BookModel> books) async {
    final booksJson = books.map((book) => book.toJson()).toList();
    await sharedPreferences.setString(key, jsonEncode(booksJson));
  }

  @override
  Future<List<BookModel>> getCachedBooks(String key) async {
    final booksString = sharedPreferences.getString(key);
    if (booksString != null) {
      final booksJson = jsonDecode(booksString) as List<dynamic>;
      return booksJson
          .map((bookJson) =>
              BookModel.fromJson(bookJson as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  @override
  Future<void> clearCache() async {
    final keys = sharedPreferences.getKeys();
    for (final key in keys) {
      if (key.startsWith('cached_books_')) {
        await sharedPreferences.remove(key);
      }
    }
  }
}
