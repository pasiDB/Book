import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import '../constants/app_constants.dart';

class CacheServiceOptimized {
  final SharedPreferences _prefs;

  // LRU Cache implementation
  final Map<String, _CacheEntry> _memoryCache = {};
  final List<String> _accessOrder = [];

  static const Duration _defaultExpiry = Duration(hours: 24);
  static const int _maxMemoryCacheSize = 200;
  static const int _maxPersistentCacheSize = 100;
  static const int _maxCompressedSize = 1024 * 1024; // 1MB

  CacheServiceOptimized(this._prefs);

  // Memory cache operations with LRU
  Future<T?> getFromMemory<T>(String key) async {
    if (!_memoryCache.containsKey(key)) return null;

    final entry = _memoryCache[key]!;
    if (_isExpired(entry.timestamp, _defaultExpiry)) {
      _removeFromMemory(key);
      return null;
    }

    // Update access order for LRU
    _updateAccessOrder(key);
    return entry.value as T;
  }

  Future<void> setInMemory<T>(String key, T value) async {
    // Remove if already exists
    if (_memoryCache.containsKey(key)) {
      _removeFromMemory(key);
    }

    // Add new entry
    _memoryCache[key] = _CacheEntry(value, DateTime.now());
    _accessOrder.add(key);

    // Clean up if cache is too large
    if (_memoryCache.length > _maxMemoryCacheSize) {
      _evictLRU();
    }
  }

  void _removeFromMemory(String key) {
    _memoryCache.remove(key);
    _accessOrder.remove(key);
  }

  void _updateAccessOrder(String key) {
    _accessOrder.remove(key);
    _accessOrder.add(key);
  }

  void _evictLRU() {
    if (_accessOrder.isEmpty) return;

    final oldestKey = _accessOrder.first;
    _removeFromMemory(oldestKey);
  }

  // Persistent cache operations with compression
  Future<T?> getFromPersistent<T>(String key) async {
    final jsonString = _prefs.getString(key);
    if (jsonString == null) return null;

    try {
      final data = json.decode(jsonString);
      final timestamp = data['timestamp'] as int?;
      final value = data['value'];
      final isCompressed = data['compressed'] as bool? ?? false;

      if (timestamp == null ||
          _isExpired(
              DateTime.fromMillisecondsSinceEpoch(timestamp), _defaultExpiry)) {
        await _prefs.remove(key);
        return null;
      }

      if (isCompressed && value is String) {
        final decompressed = _decompress(value);
        return decompressed as T;
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
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final jsonString = json.encode(value);

      // Compress if data is large
      final isCompressed = jsonString.length > _maxCompressedSize;
      final processedValue = isCompressed ? _compress(jsonString) : value;

      final data = {
        'value': processedValue,
        'timestamp': timestamp,
        'compressed': isCompressed,
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
    _removeFromMemory(key);
    await _prefs.remove(key);
  }

  Future<void> clear() async {
    _memoryCache.clear();
    _accessOrder.clear();

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
      _removeFromMemory(key);
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
    return await get<List<Map<String, dynamic>>>(
      '${AppConstants.downloadedBooksKey}_$category',
    );
  }

  Future<void> setBooksByCategory(String category, List<dynamic> books) async {
    await set('${AppConstants.downloadedBooksKey}_$category', books);
  }

  Future<String?> getBookContent(int bookId) async {
    return await get<String>(
        'content_$bookId'); // Consider making a constant if reused
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

  // Batch operations for better performance
  Future<Map<String, dynamic>> getBatch(List<String> keys) async {
    final results = <String, dynamic>{};

    for (final key in keys) {
      final value = await get(key);
      if (value != null) {
        results[key] = value;
      }
    }

    return results;
  }

  Future<void> setBatch(Map<String, dynamic> keyValuePairs) async {
    final futures = keyValuePairs.entries.map(
      (entry) => set(entry.key, entry.value),
    );

    await Future.wait(futures);
  }

  // Cache statistics
  int get memoryCacheSize => _memoryCache.length;
  int get persistentCacheSize {
    final keys = _prefs.getKeys();
    return keys.where((key) => key.startsWith('cache_')).length;
  }

  Map<String, dynamic> get cacheStats => {
        'memorySize': memoryCacheSize,
        'persistentSize': persistentCacheSize,
        'memoryUsage': _calculateMemoryUsage(),
      };

  // Private methods
  bool _isExpired(DateTime timestamp, Duration expiry) {
    return DateTime.now().difference(timestamp) > expiry;
  }

  double _calculateMemoryUsage() {
    if (_memoryCache.isEmpty) return 0.0;

    int totalSize = 0;
    for (final entry in _memoryCache.values) {
      totalSize += _estimateSize(entry.value);
    }

    return totalSize / (1024 * 1024); // Return in MB
  }

  int _estimateSize(dynamic value) {
    if (value is String) return value.length;
    if (value is List) return value.length * 8; // Rough estimate
    if (value is Map) return value.length * 16; // Rough estimate
    return 8; // Default size
  }

  String _compress(String data) {
    // Simple compression - in production, use a proper compression library
    final bytes = utf8.encode(data);
    final compressed = gzip.encode(bytes);
    return base64.encode(compressed);
  }

  String _decompress(String compressedData) {
    final bytes = base64.decode(compressedData);
    final decompressed = gzip.decode(bytes);
    return utf8.decode(decompressed);
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

class _CacheEntry {
  final dynamic value;
  final DateTime timestamp;

  _CacheEntry(this.value, this.timestamp);
}
