import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:melobox_app/models/app_update.dart';
import 'package:melobox_app/services/update_service.dart';

class _RecordingDio extends DioForNative {
  _RecordingDio({this.assetStatus = 200});

  final int assetStatus;
  final List<String> headPaths = [];
  String? savedPath;

  @override
  Future<Response<T>> head<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    headPaths.add(path);
    if (path == UpdateService.latestReleaseUrl) {
      return Response<T>(
        requestOptions: RequestOptions(path: path),
        statusCode: 302,
        headers: Headers.fromMap({
          'location': [
            'https://github.com/mateo-ki/MeloBoxApp/releases/tag/v1.3.1',
          ],
        }),
      );
    }
    return Response<T>(
      requestOptions: RequestOptions(path: path),
      statusCode: assetStatus,
    );
  }

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
  TestWidgetsFlutterBinding.ensureInitialized();

  const updateChannel = MethodChannel('melobox/update_installer');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(updateChannel, (call) async {
      if (call.method == 'getCurrentVersion') {
        return '1.2.0';
      }
      return null;
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(updateChannel, null);
  });

  test('ignores a release until its APK asset is available', () async {
    final dio = _RecordingDio(assetStatus: 404);
    final service = UpdateService(dio: dio);

    final update = await service.checkForUpdate();

    expect(update, isNull);
    expect(
      dio.headPaths,
      contains(
        'https://github.com/mateo-ki/MeloBoxApp/releases/download/'
        'v1.3.1/app-release.apk',
      ),
    );
  });

  test('returns an update after its APK asset becomes available', () async {
    final dio = _RecordingDio(assetStatus: 302);
    final service = UpdateService(dio: dio);

    final update = await service.checkForUpdate();

    expect(update?.version, '1.3.1');
    expect(
      update?.apkUrl,
      'https://github.com/mateo-ki/MeloBoxApp/releases/download/'
      'v1.3.1/app-release.apk',
    );
  });

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
