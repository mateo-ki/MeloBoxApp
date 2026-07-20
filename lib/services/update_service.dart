import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';

import '../models/app_update.dart';

class UpdateService {
  UpdateService({Dio? dio}) : _dio = dio ?? Dio();

  static const latestReleaseUrl =
      'https://github.com/mateo-ki/MeloBoxApp/releases/latest';
  static const _apkName = 'app-release.apk';
  static const _platform = MethodChannel('melobox/update_installer');

  final Dio _dio;

  Future<String> currentVersion() async {
    return await _platform.invokeMethod<String>('getCurrentVersion') ?? '0.0.0';
  }

  Future<AppUpdate?> checkForUpdate() async {
    final response = await _dio.head<void>(
      latestReleaseUrl,
      options: Options(
        followRedirects: false,
        validateStatus: (status) =>
            status != null && status >= 300 && status < 400,
      ),
    );
    final location = response.headers.value('location');
    if (location == null || location.trim().isEmpty) {
      throw const FormatException('GitHub 没有返回最新 Release 地址');
    }

    final tag = githubReleaseTagFromLocation(location);
    final version = normalizeAppVersion(tag);
    final releaseUrl = Uri.parse(latestReleaseUrl).resolve(location).toString();
    final encodedTag = Uri.encodeComponent(tag);
    final update = AppUpdate(
      version: version,
      title: 'MeloBox $version',
      notes: '',
      releaseUrl: releaseUrl,
      apkName: _apkName,
      apkUrl:
          'https://github.com/mateo-ki/MeloBoxApp/releases/download/$encodedTag/$_apkName',
    );
    final installedVersion = await currentVersion();
    return compareAppVersions(update.version, installedVersion) > 0
        ? update
        : null;
  }

  Future<File> downloadApk(
    AppUpdate update, {
    ProgressCallback? onReceiveProgress,
  }) async {
    final directory = await Directory.systemTemp.createTemp('melobox_update_');
    final safeName = update.apkName.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
    final file = File('${directory.path}/$safeName');
    await _dio.download(
      update.apkUrl,
      file.path,
      onReceiveProgress: onReceiveProgress,
      options: Options(followRedirects: true),
    );
    return file;
  }

  Future<void> installApk(File apk) async {
    await _platform.invokeMethod<void>('installApk', {'path': apk.path});
  }
}
