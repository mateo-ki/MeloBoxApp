import 'package:flutter_test/flutter_test.dart';
import 'package:melobox_app/models/app_update.dart';

void main() {
  group('compareAppVersions', () {
    test('treats equivalent versions as equal', () {
      expect(compareAppVersions('1.0', '1.0.0'), 0);
      expect(compareAppVersions('v1.0.0', '1.0.0+1'), 0);
    });

    test('orders semantic version components numerically', () {
      expect(compareAppVersions('1.0.1', '1.0.0'), greaterThan(0));
      expect(compareAppVersions('1.10.0', '1.9.9'), greaterThan(0));
      expect(compareAppVersions('2.0.0', '10.0.0'), lessThan(0));
    });
  });

  test('parses the APK asset from a GitHub release', () {
    final update = AppUpdate.fromGitHubRelease({
      'tag_name': 'v1.2.0',
      'name': 'MeloBox 1.2.0',
      'body': 'Fixes and improvements',
      'html_url': 'https://github.com/mateo-ki/MeloBoxApp/releases/tag/v1.2.0',
      'assets': [
        {
          'name': 'checksums.txt',
          'browser_download_url': 'https://example.com/checksums.txt',
        },
        {
          'name': 'MeloBox-v1.2.0.apk',
          'browser_download_url': 'https://example.com/MeloBox-v1.2.0.apk',
        },
      ],
    });

    expect(update.version, '1.2.0');
    expect(update.title, 'MeloBox 1.2.0');
    expect(update.notes, 'Fixes and improvements');
    expect(update.apkName, 'MeloBox-v1.2.0.apk');
    expect(update.apkUrl, 'https://example.com/MeloBox-v1.2.0.apk');
  });

  test('rejects a GitHub release without an APK asset', () {
    expect(
      () => AppUpdate.fromGitHubRelease({
        'tag_name': 'v1.2.0',
        'assets': const [],
      }),
      throwsFormatException,
    );
  });

  test('extracts the tag from a GitHub latest release redirect', () {
    expect(
      githubReleaseTagFromLocation(
        'https://github.com/mateo-ki/MeloBoxApp/releases/tag/v1.2.0',
      ),
      'v1.2.0',
    );
    expect(
      () => githubReleaseTagFromLocation('/mateo-ki/MeloBoxApp/releases'),
      throwsFormatException,
    );
  });
}
