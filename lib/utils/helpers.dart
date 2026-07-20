class DateTimeHelper {
  /// 格式化时间为相对时间（如：刚刚、5分钟前、2小时前）
  static String formatRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return '刚刚';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}分钟前';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}小时前';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}天前';
    } else if (difference.inDays < 30) {
      return '${(difference.inDays / 7).floor()}周前';
    } else if (difference.inDays < 365) {
      return '${(difference.inDays / 30).floor()}个月前';
    } else {
      return '${(difference.inDays / 365).floor()}年前';
    }
  }

  /// 格式化日期（如：2024-01-01）
  static String formatDate(DateTime dateTime) {
    return '${dateTime.year}-${_padZero(dateTime.month)}-${_padZero(dateTime.day)}';
  }

  /// 格式化时间（如：14:30:00）
  static String formatTime(DateTime dateTime) {
    return '${_padZero(dateTime.hour)}:${_padZero(dateTime.minute)}:${_padZero(dateTime.second)}';
  }

  /// 格式化日期时间（如：2024-01-01 14:30）
  static String formatDateTime(DateTime dateTime) {
    return '${formatDate(dateTime)} ${_padZero(dateTime.hour)}:${_padZero(dateTime.minute)}';
  }

  static String _padZero(int value) {
    return value.toString().padLeft(2, '0');
  }
}

class StringHelper {
  /// 截断字符串并添加省略号
  static String truncate(String text, int maxLength) {
    if (text.length <= maxLength) {
      return text;
    }
    return '${text.substring(0, maxLength)}...';
  }

  /// 判断字符串是否为空或null
  static bool isEmpty(String? text) {
    return text == null || text.trim().isEmpty;
  }

  /// 判断字符串是否不为空
  static bool isNotEmpty(String? text) {
    return !isEmpty(text);
  }

  /// 移除HTML标签
  static String removeHtmlTags(String text) {
    return text.replaceAll(RegExp(r'<[^>]*>'), '');
  }

  /// 格式化文件大小
  static String formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }
}

class ValidationHelper {
  /// 验证URL格式
  static bool isValidUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https');
    } catch (e) {
      return false;
    }
  }

  /// 验证是否为数字
  static bool isNumeric(String str) {
    return double.tryParse(str) != null;
  }
}

class MediaUrlHelper {
  static String resolveMediaUrl(String url, String baseUrl) {
    final trimmedUrl = _extractMediaUrl(url);
    if (trimmedUrl.isEmpty) {
      return '';
    }

    final parsedUrl = Uri.tryParse(trimmedUrl);
    if (parsedUrl != null && parsedUrl.hasScheme) {
      return trimmedUrl;
    }

    final parsedBase = Uri.tryParse(baseUrl);
    if (parsedBase == null || !parsedBase.hasScheme) {
      return trimmedUrl;
    }

    return parsedBase.resolve(trimmedUrl).toString();
  }

  static Map<String, String> imageHeaders(String imageUrl) {
    final headers = <String, String>{
      'User-Agent': 'Mozilla/5.0 (Linux; Android 10) AppleWebKit/537.36',
      'Accept': 'image/avif,image/webp,image/apng,image/*,*/*;q=0.8',
      'Accept-Language': 'zh-CN,zh;q=0.9,en;q=0.8',
    };

    final uri = Uri.tryParse(imageUrl);
    if (uri != null && uri.hasScheme && uri.host.isNotEmpty) {
      headers['Referer'] = '${uri.scheme}://${uri.host}/';
    }

    return headers;
  }

  static List<String> imageCandidates(String imageUrl) {
    final normalized = _extractMediaUrl(imageUrl);
    if (normalized.isEmpty) {
      return const [];
    }

    final candidates = <String>[normalized];

    if (normalized.startsWith('https://')) {
      candidates.add('http://${normalized.substring('https://'.length)}');
    } else if (normalized.startsWith('http://')) {
      candidates.add('https://${normalized.substring('http://'.length)}');
    } else if (normalized.startsWith('//')) {
      candidates
        ..add('https:$normalized')
        ..add('http:$normalized');
    }

    return candidates.toSet().toList(growable: false);
  }

  static String _extractMediaUrl(String rawUrl) {
    var value = rawUrl
        .trim()
        .replaceAll('&amp;', '&')
        .replaceAll('\\/', '/')
        .replaceAll(RegExp(r'''^["']|["']$'''), '');

    if (value.isEmpty) {
      return '';
    }

    final srcMatch = RegExp(
      r'''src\s*=\s*["']([^"']+)["']''',
      caseSensitive: false,
    ).firstMatch(value);
    if (srcMatch != null) {
      value = srcMatch.group(1) ?? value;
    }

    final absoluteMatch = RegExp(
      r'''https?:\/\/[^\s,，|]+''',
      caseSensitive: false,
    ).firstMatch(value);
    if (absoluteMatch != null) {
      return absoluteMatch.group(0) ?? value;
    }

    final protocolRelativeMatch = RegExp(r'''\/\/[^\s,，|]+''').firstMatch(value);
    if (protocolRelativeMatch != null) {
      return protocolRelativeMatch.group(0) ?? value;
    }

    return value.split(RegExp(r'[\s,，|]+')).first.trim();
  }
}
