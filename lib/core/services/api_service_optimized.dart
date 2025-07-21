import 'package:dio/dio.dart';
import 'dart:async';
import '../constants/app_constants.dart';

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

  ApiServiceOptimized(Dio dio) : _dio = dio {
    _setupInterceptors();
    _initializeConnectionPool();
  }

  void _initializeConnectionPool() {
    for (int i = 0; i < _maxConcurrentRequests; i++) {
      final dio = Dio();
      // Copy configuration from the main Dio instance
      dio.options = _dio.options.copyWith();
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

  String _generateCacheKey(String path, Map<String, dynamic>? queryParameters) {
    final buffer = StringBuffer(path);
    if (queryParameters != null && queryParameters.isNotEmpty) {
      final sortedParams = Map.fromEntries(
        queryParameters.entries.toList()
          ..sort((a, b) => a.key.compareTo(b.key)),
      );
      buffer.write('?');
      buffer.write(sortedParams.entries
          .map((entry) => '${entry.key}=${entry.value}')
          .join('&'));
    }
    final cacheKey = buffer.toString();
    print('🔑 Generated cache key: $cacheKey');
    return cacheKey;
  }

  bool _isCacheValid(String cacheKey, Duration? customExpiry) {
    final timestamp = _cacheTimestamps[cacheKey];
    if (timestamp == null) return false;

    final expiry = customExpiry ?? _cacheExpiry;
    return DateTime.now().difference(timestamp) < expiry;
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
      print(
          '🌐 Making network request to: $path with params: $queryParameters');
      print('🔗 Full URL would be: ${_nextConnection.options.baseUrl}$path');
      final response = await _nextConnection.get(
        path,
        queryParameters: queryParameters,
        options: Options(
          headers: {
            'Accept': AppConstants.acceptHeader,
            'User-Agent': AppConstants.userAgent,
            'Connection': AppConstants.connectionHeader,
          },
        ),
      );

      print('✅ Response received: ${response.statusCode}');
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
      print('❌ Dio error for $path: ${e.message}');
      print('❌ Dio error type: ${e.type}');
      print('❌ Dio response: ${e.response?.statusCode}');
      final apiException = _handleDioError(e);
      completer.completeError(apiException);
      _pendingRequests.remove(cacheKey);
      rethrow;
    } catch (e) {
      print('❌ Unexpected error for $path: $e');
      final apiException = ApiException('Unexpected error: $e');
      completer.completeError(apiException);
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
