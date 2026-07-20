class AppUpdate {
  const AppUpdate({
    required this.version,
    required this.title,
    required this.notes,
    required this.releaseUrl,
    required this.apkName,
    required this.apkUrl,
  });

  final String version;
  final String title;
  final String notes;
  final String releaseUrl;
  final String apkName;
  final String apkUrl;

  factory AppUpdate.fromGitHubRelease(Map<String, dynamic> json) {
    final tagName = (json['tag_name']?.toString() ?? '').trim();
    if (tagName.isEmpty) {
      throw const FormatException('GitHub Release 缺少版本标签');
    }

    final assets = json['assets'];
    Map<dynamic, dynamic>? apkAsset;
    if (assets is List) {
      for (final asset in assets) {
        if (asset is Map &&
            (asset['name']?.toString() ?? '').toLowerCase().endsWith('.apk')) {
          apkAsset = asset;
          break;
        }
      }
    }
    if (apkAsset == null) {
      throw const FormatException('GitHub Release 中没有 APK 文件');
    }

    final apkName = (apkAsset['name']?.toString() ?? '').trim();
    final apkUrl = (apkAsset['browser_download_url']?.toString() ?? '').trim();
    if (apkUrl.isEmpty) {
      throw const FormatException('GitHub Release 的 APK 下载地址为空');
    }

    final version = normalizeAppVersion(tagName);
    final releaseName = (json['name']?.toString() ?? '').trim();
    return AppUpdate(
      version: version,
      title: releaseName.isEmpty ? 'MeloBox $version' : releaseName,
      notes: (json['body']?.toString() ?? '').trim(),
      releaseUrl: (json['html_url']?.toString() ?? '').trim(),
      apkName: apkName,
      apkUrl: apkUrl,
    );
  }
}

String normalizeAppVersion(String version) {
  var normalized = version.trim();
  if (normalized.startsWith('v') || normalized.startsWith('V')) {
    normalized = normalized.substring(1);
  }
  return normalized.split('+').first;
}

int compareAppVersions(String left, String right) {
  List<int> parts(String value) {
    return normalizeAppVersion(value)
        .split('.')
        .map((part) =>
            int.tryParse(RegExp(r'^\d+').stringMatch(part) ?? '') ?? 0)
        .toList(growable: false);
  }

  final leftParts = parts(left);
  final rightParts = parts(right);
  final length = leftParts.length > rightParts.length
      ? leftParts.length
      : rightParts.length;
  for (var index = 0; index < length; index++) {
    final leftPart = index < leftParts.length ? leftParts[index] : 0;
    final rightPart = index < rightParts.length ? rightParts[index] : 0;
    if (leftPart != rightPart) {
      return leftPart.compareTo(rightPart);
    }
  }
  return 0;
}

String githubReleaseTagFromLocation(String location) {
  final uri = Uri.tryParse(location);
  if (uri == null) {
    throw const FormatException('GitHub Release 重定向地址无效');
  }
  final tagIndex = uri.pathSegments.lastIndexOf('tag');
  if (tagIndex == -1 || tagIndex + 1 >= uri.pathSegments.length) {
    throw const FormatException('GitHub Release 重定向地址中没有版本标签');
  }
  final tag = uri.pathSegments[tagIndex + 1].trim();
  if (tag.isEmpty) {
    throw const FormatException('GitHub Release 版本标签为空');
  }
  return tag;
}
