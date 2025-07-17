import 'package:dio/dio.dart';
import 'dart:convert';

class ApiService {
  final Dio _dio;
  final Map<String, dynamic> _cache = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  static const Duration _cacheExpiry = Duration(minutes: 30);

  ApiService(this._dio) {
    _setupInterceptors();
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

    try {
      final response = await _dio.get(
        path,
        queryParameters: queryParameters,
        options: Options(
          headers: {
            'Accept': 'application/json',
            'User-Agent': 'BookReader/1.0.0',
          },
        ),
      );

      final data = response.data as T;

      // Cache the response
      if (useCache) {
        _cache[cacheKey] = data;
        _cacheTimestamps[cacheKey] = DateTime.now();
      }

      return data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw ApiException('Unexpected error: $e');
    }
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
}

class ApiException implements Exception {
  final String message;

  ApiException(this.message);

  @override
  String toString() => 'ApiException: $message';
}
