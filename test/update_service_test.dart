import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:melobox_app/models/app_update.dart';
import 'package:melobox_app/services/update_service.dart';

class _RecordingDio extends DioForNative {
  String? savedPath;

  @override
  Future<Response<dynamic>> download(
    String urlPath,
    dynamic savePath, {
    ProgressCallback? onReceiveProgress,
    Map<String, dynamic>? queryParameters,
    CancelToken? cancelToken,
    bool deleteOnError = true,
    FileAccessMode fileAccessMode = FileAccessMode.write,
    String lengthHeader = Headers.contentLengthHeader,
    Object? data,
    Options? options,
  }) async {
    savedPath = savePath as String;
    final file = File(savedPath!);
    await file.parent.create(recursive: true);
    await file.writeAsBytes(const [1, 2, 3]);
    return Response<dynamic>(
      requestOptions: RequestOptions(path: urlPath),
      statusCode: 200,
    );
  }
}

void main() {
  test('downloads the APK inside the app cache directory', () async {
    final cacheRoot = await Directory.systemTemp.createTemp(
      'melobox_update_test_',
    );
    addTearDown(() => cacheRoot.delete(recursive: true));
    final dio = _RecordingDio();
    final service = UpdateService(
      dio: dio,
      cacheDirectory: () async => cacheRoot,
    );
    const update = AppUpdate(
      version: '1.0.2',
      title: 'MeloBox 1.0.2',
      notes: '',
      releaseUrl: 'https://example.com/release',
      apkName: 'app-release.apk',
      apkUrl: 'https://example.com/app-release.apk',
    );

    final apk = await service.downloadApk(update);
    final expectedPath = [
      cacheRoot.path,
      'melobox_update',
      'app-release.apk',
    ].join(Platform.pathSeparator);

    expect(apk.path, expectedPath);
    expect(dio.savedPath, expectedPath);
    expect(await apk.readAsBytes(), const [1, 2, 3]);
  });
}
