import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class CacheService {
  final SharedPreferences _prefs;
  final Map<String, dynamic> _memoryCache = {};
  final Map<String, DateTime> _memoryCacheTimestamps = {};

  static const Duration _defaultExpiry = Duration(hours: 24);
  static const int _maxMemoryCacheSize = 100;
  static const int _maxPersistentCacheSize = 50;

  CacheService(this._prefs);

  // Memory cache operations
  Future<T?> getFromMemory<T>(String key) async {
    if (!_memoryCache.containsKey(key)) return null;

    final timestamp = _memoryCacheTimestamps[key];
    if (timestamp == null || _isExpired(timestamp, _defaultExpiry)) {
      _memoryCache.remove(key);
      _memoryCacheTimestamps.remove(key);
      return null;
    }

    return _memoryCache[key] as T;
  }

  Future<void> setInMemory<T>(String key, T value) async {
    _memoryCache[key] = value;
    _memoryCacheTimestamps[key] = DateTime.now();

    // Clean up if cache is too large
    if (_memoryCache.length > _maxMemoryCacheSize) {
      _cleanupMemoryCache();
    }
  }

  // Persistent cache operations
  Future<T?> getFromPersistent<T>(String key) async {
    final jsonString = _prefs.getString(key);
    if (jsonString == null) return null;

    try {
      final data = json.decode(jsonString);
      final timestamp = data['timestamp'] as int?;
      final value = data['value'];

      if (timestamp == null ||
          _isExpired(
              DateTime.fromMillisecondsSinceEpoch(timestamp), _defaultExpiry)) {
        await _prefs.remove(key);
        return null;
      }

      return value as T;
    } catch (e) {
      print('Error reading from persistent cache: $e');
      await _prefs.remove(key);
      return null;
    }
  }

  Future<void> setInPersistent<T>(String key, T value) async {
    try {
      final data = {
        'value': value,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };

      await _prefs.setString(key, json.encode(data));

      // Clean up if cache is too large
      await _cleanupPersistentCache();
    } catch (e) {
      print('Error writing to persistent cache: $e');
    }
  }

  // Combined cache operations
  Future<T?> get<T>(String key) async {
    // Try memory cache first
    final memoryValue = await getFromMemory<T>(key);
    if (memoryValue != null) {
      print('📦 Memory cache hit: $key');
      return memoryValue;
    }

    // Try persistent cache
    final persistentValue = await getFromPersistent<T>(key);
    if (persistentValue != null) {
      print('💾 Persistent cache hit: $key');
      // Store in memory cache for faster access
      await setInMemory(key, persistentValue);
      return persistentValue;
    }

    return null;
  }

  Future<void> set<T>(String key, T value) async {
    // Store in both caches
    await setInMemory(key, value);
    await setInPersistent(key, value);
  }

  Future<void> remove(String key) async {
    _memoryCache.remove(key);
    _memoryCacheTimestamps.remove(key);
    await _prefs.remove(key);
  }

  Future<void> clear() async {
    _memoryCache.clear();
    _memoryCacheTimestamps.clear();

    final keys = _prefs.getKeys();
    for (final key in keys) {
      if (key.startsWith('cache_')) {
        await _prefs.remove(key);
      }
    }
  }

  Future<void> clearByPrefix(String prefix) async {
    // Clear memory cache
    final memoryKeysToRemove =
        _memoryCache.keys.where((key) => key.startsWith(prefix)).toList();
    for (final key in memoryKeysToRemove) {
      _memoryCache.remove(key);
      _memoryCacheTimestamps.remove(key);
    }

    // Clear persistent cache
    final keys = _prefs.getKeys();
    for (final key in keys) {
      if (key.startsWith(prefix)) {
        await _prefs.remove(key);
      }
    }
  }

  // Book-specific cache operations
  Future<List<Map<String, dynamic>>?> getBooksByCategory(
      String category) async {
    return await get<List<Map<String, dynamic>>>('books_$category');
  }

  Future<void> setBooksByCategory(
      String category, List<dynamic> books) async {
    await set('books_$category', books);
  }

  Future<String?> getBookContent(int bookId) async {
    return await get<String>('content_$bookId');
  }

  Future<void> setBookContent(int bookId, String content) async {
    await set('content_$bookId', content);
  }

  Future<Map<String, dynamic>?> getBookDetails(int bookId) async {
    return await get<Map<String, dynamic>>('book_$bookId');
  }

  Future<void> setBookDetails(int bookId, Map<String, dynamic> book) async {
    await set('book_$bookId', book);
  }

  // Cache statistics
  int get memoryCacheSize => _memoryCache.length;
  int get persistentCacheSize {
    final keys = _prefs.getKeys();
    return keys.where((key) => key.startsWith('cache_')).length;
  }

  // Private methods
  bool _isExpired(DateTime timestamp, Duration expiry) {
    return DateTime.now().difference(timestamp) > expiry;
  }

  void _cleanupMemoryCache() {
    if (_memoryCache.isEmpty) return;

    // Remove oldest entries
    final sortedEntries = _memoryCacheTimestamps.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));

    final entriesToRemove = sortedEntries.take(_memoryCache.length ~/ 2);
    for (final entry in entriesToRemove) {
      _memoryCache.remove(entry.key);
      _memoryCacheTimestamps.remove(entry.key);
    }
  }

  Future<void> _cleanupPersistentCache() async {
    final keys = _prefs.getKeys();
    final cacheKeys = keys.where((key) => key.startsWith('cache_')).toList();

    if (cacheKeys.length <= _maxPersistentCacheSize) return;

    // Get timestamps for all cache entries
    final entries = <String, int>{};
    for (final key in cacheKeys) {
      try {
        final jsonString = _prefs.getString(key);
        if (jsonString != null) {
          final data = json.decode(jsonString);
          final timestamp = data['timestamp'] as int?;
          if (timestamp != null) {
            entries[key] = timestamp;
          }
        }
      } catch (e) {
        // Remove corrupted entries
        await _prefs.remove(key);
      }
    }

    // Sort by timestamp and remove oldest
    final sortedEntries = entries.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));

    final entriesToRemove =
        sortedEntries.take(entries.length - _maxPersistentCacheSize);
    for (final entry in entriesToRemove) {
      await _prefs.remove(entry.key);
    }
  }
}
