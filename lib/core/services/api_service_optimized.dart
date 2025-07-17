import 'package:dio/dio.dart';
import 'dart:convert';
import 'dart:async';

class ApiServiceOptimized {
  final Dio _dio;
  final Map<String, dynamic> _cache = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  final Map<String, Completer<dynamic>> _pendingRequests = {};

  static const Duration _cacheExpiry = Duration(minutes: 30);
  static const int _maxConcurrentRequests = 5;
  static const Duration _requestTimeout = Duration(seconds: 15);

  // Connection pool
  final List<Dio> _connectionPool = [];
  int _currentConnectionIndex = 0;

  ApiServiceOptimized() : _dio = Dio() {
    _setupInterceptors();
    _initializeConnectionPool();
  }

  void _initializeConnectionPool() {
    for (int i = 0; i < _maxConcurrentRequests; i++) {
      final dio = Dio();
      dio.options.connectTimeout = _requestTimeout;
      dio.options.receiveTimeout = _requestTimeout;
      dio.options.sendTimeout = _requestTimeout;
      _connectionPool.add(dio);
    }
  }

  Dio get _nextConnection {
    _currentConnectionIndex =
        (_currentConnectionIndex + 1) % _connectionPool.length;
    return _connectionPool[_currentConnectionIndex];
  }

  void _setupInterceptors() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          print('🌐 API Request: ${options.method} ${options.path}');
          handler.next(options);
        },
        onResponse: (response, handler) {
          print(
              '✅ API Response: ${response.statusCode} ${response.requestOptions.path}');
          handler.next(response);
        },
        onError: (error, handler) {
          print(
              '❌ API Error: ${error.response?.statusCode} ${error.requestOptions.path}');
          handler.next(error);
        },
      ),
    );
  }

  Future<T> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    bool useCache = true,
    Duration? cacheExpiry,
  }) async {
    final cacheKey = _generateCacheKey(path, queryParameters);

    // Check cache first
    if (useCache && _isCacheValid(cacheKey, cacheExpiry)) {
      print('📦 Using cached data for: $path');
      return _cache[cacheKey] as T;
    }

    // Check if there's already a pending request for this key
    if (_pendingRequests.containsKey(cacheKey)) {
      print('⏳ Waiting for pending request: $path');
      final result = await _pendingRequests[cacheKey]!.future;
      return result as T;
    }

    // Create a new completer for this request
    final completer = Completer<dynamic>();
    _pendingRequests[cacheKey] = completer;

    try {
      final response = await _nextConnection.get(
        path,
        queryParameters: queryParameters,
        options: Options(
          headers: {
            'Accept': 'application/json',
            'User-Agent': 'BookReader/2.0.0',
            'Connection': 'keep-alive',
          },
        ),
      );

      final data = response.data as T;

      // Cache the response
      if (useCache) {
        _cache[cacheKey] = data;
        _cacheTimestamps[cacheKey] = DateTime.now();
      }

      completer.complete(data);
      _pendingRequests.remove(cacheKey);
      return data;
    } on DioException catch (e) {
      completer.completeError(_handleDioError(e));
      _pendingRequests.remove(cacheKey);
      rethrow;
    } catch (e) {
      completer.completeError(ApiException('Unexpected error: $e'));
      _pendingRequests.remove(cacheKey);
      rethrow;
    }
  }

  Future<List<T>> getBatch<T>(
    List<String> paths, {
    Map<String, Map<String, dynamic>>? queryParameters,
    bool useCache = true,
  }) async {
    final futures = paths.map((path) {
      final params = queryParameters?[path];
      return get<T>(path, queryParameters: params, useCache: useCache);
    }).toList();

    return await Future.wait(futures);
  }

  Future<T> getWithRetry<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    int maxRetries = 3,
    Duration delay = const Duration(seconds: 1),
    bool useCache = true,
  }) async {
    int attempts = 0;

    while (attempts < maxRetries) {
      try {
        return await get<T>(path,
            queryParameters: queryParameters, useCache: useCache);
      } on ApiException catch (e) {
        attempts++;
        if (attempts >= maxRetries) {
          rethrow;
        }

        print('🔄 Retry attempt $attempts for: $path');
        await Future.delayed(delay * attempts); // Exponential backoff
      }
    }

    throw ApiException('Max retries exceeded for: $path');
  }

  String _generateCacheKey(String path, Map<String, dynamic>? queryParameters) {
    final queryString =
        queryParameters != null ? json.encode(queryParameters) : '';
    return '$path$queryString';
  }

  bool _isCacheValid(String cacheKey, Duration? cacheExpiry) {
    if (!_cache.containsKey(cacheKey)) return false;

    final timestamp = _cacheTimestamps[cacheKey];
    if (timestamp == null) return false;

    final expiry = cacheExpiry ?? _cacheExpiry;
    return DateTime.now().difference(timestamp) < expiry;
  }

  void clearCache([String? path]) {
    if (path == null) {
      _cache.clear();
      _cacheTimestamps.clear();
      print('🗑️ Cache cleared');
    } else {
      final keysToRemove =
          _cache.keys.where((key) => key.startsWith(path)).toList();
      for (final key in keysToRemove) {
        _cache.remove(key);
        _cacheTimestamps.remove(key);
      }
      print('🗑️ Cache cleared for: $path');
    }
  }

  ApiException _handleDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return ApiException(
            'Request timeout. Please check your internet connection.');

      case DioExceptionType.connectionError:
        return ApiException(
            'No internet connection. Please check your network.');

      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        final message = error.response?.data?['message'] ?? 'Server error';
        return ApiException('HTTP $statusCode: $message');

      case DioExceptionType.cancel:
        return ApiException('Request was cancelled.');

      default:
        return ApiException('Network error: ${error.message}');
    }
  }

  void dispose() {
    for (final dio in _connectionPool) {
      dio.close();
    }
    _connectionPool.clear();
  }
}

class ApiException implements Exception {
  final String message;

  ApiException(this.message);

  @override
  String toString() => 'ApiException: $message';
}
