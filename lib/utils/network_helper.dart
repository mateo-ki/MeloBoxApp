import 'package:http/http.dart' as http;
import 'dart:async';
import 'package:flutter/foundation.dart';

class NetworkHelper {
  static const int defaultTimeout = 10;
  static const int maxRetries = 3;

  static Future<http.Response> getWithRetry(
    String url, {
    int timeout = defaultTimeout,
    int retries = maxRetries,
  }) async {
    int attempt = 0;
    while (attempt < retries) {
      try {
        final response = await http.get(Uri.parse(url)).timeout(
          Duration(seconds: timeout),
        );
        return response;
      } catch (e) {
        attempt++;
        if (attempt >= retries) {
          rethrow;
        }
        debugPrint('Request failed (attempt $attempt/$retries): $e');
        await Future.delayed(Duration(seconds: attempt));
      }
    }
    throw Exception('Max retries reached');
  }

  static bool isValidUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https');
    } catch (e) {
      return false;
    }
  }

  static String? validateVideoUrl(String? url) {
    if (url == null || url.isEmpty) {
      return '视频地址不能为空';
    }
    if (!isValidUrl(url)) {
      return '视频地址格式不正确';
    }
    return null;
  }
}

class NetworkException implements Exception {
  final String message;
  final int? statusCode;

  NetworkException(this.message, {this.statusCode});

  @override
  String toString() {
    if (statusCode != null) {
      return 'NetworkException: $message (Status: $statusCode)';
    }
    return 'NetworkException: $message';
  }
}

class TimeoutException implements Exception {
  final String message;

  TimeoutException([this.message = '请求超时']);

  @override
  String toString() => 'TimeoutException: $message';
}

class ParseException implements Exception {
  final String message;

  ParseException([this.message = '数据解析失败']);

  @override
  String toString() => 'ParseException: $message';
}
