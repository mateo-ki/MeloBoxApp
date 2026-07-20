import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:melobox_app/models/api_site.dart';
import 'package:melobox_app/providers/site_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('exports and imports encrypted miniplayer-compatible site share text',
      () async {
    SharedPreferences.setMockInitialValues({});
    final sourceProvider = SiteProvider();
    await sourceProvider.addSite(
      ApiSite(
        name: 'Test Site',
        baseUrl: 'https://example.com/api.php/provide/vod',
        type: 'video',
      ),
    );

    final shareText = await sourceProvider.exportEncryptedShareText();

    expect(shareText, startsWith('MINIPLAYER_SITE_SHARE_V1:'));

    SharedPreferences.setMockInitialValues({});
    final targetProvider = SiteProvider();
    final message = await targetProvider.importEncryptedShareText(shareText);

    expect(message, contains('新增 1 个'));
    expect(targetProvider.sites, hasLength(1));
    expect(targetProvider.sites.single.name, 'Test Site');
    expect(
      targetProvider.sites.single.baseUrl,
      'https://example.com/api.php/provide/vod',
    );
  });

  test('imports miniplayer siteType classifications', () async {
    SharedPreferences.setMockInitialValues({});
    final provider = SiteProvider();
    final shareText = _encodeMiniPlayerShare({
      'type': 'api-sites',
      'version': 1,
      'sites': [
        {
          'name': 'Image Site',
          'baseUrl': 'https://example.com/image',
          'siteType': 'image',
        },
        {
          'name': 'Short Video Site',
          'baseUrl': 'https://example.com/short-video',
          'siteType': 'shortvideo',
        },
      ],
    });

    await provider.importEncryptedShareText(shareText);

    expect(provider.sites.map((site) => site.type), ['image', 'shortvideo']);
  });

  test('clearSites removes all persisted sites and resets current index',
      () async {
    SharedPreferences.setMockInitialValues({});
    final provider = SiteProvider();
    await provider.addSite(
      ApiSite(
        name: 'Test Site',
        baseUrl: 'https://example.com/api.php/provide/vod',
        type: 'video',
      ),
    );
    await provider.setCurrentIndex(0);

    await provider.clearSites();

    expect(provider.sites, isEmpty);
    expect(provider.currentIndex, 0);

    final reloadedProvider = SiteProvider();
    await reloadedProvider.loadSites();

    expect(reloadedProvider.sites, isEmpty);
    expect(reloadedProvider.currentIndex, 0);
  });

  test('loadSites keeps explicitly persisted empty site config empty',
      () async {
    SharedPreferences.setMockInitialValues({
      'customApiSitesConfig': '{"currentIndex":0,"sites":[]}',
      'currentSiteIndex': 0,
    });

    final provider = SiteProvider();
    await provider.loadSites();

    expect(provider.sites, isEmpty);
    expect(provider.currentIndex, 0);
  });

  test('loadSites starts empty when no persisted site config exists', () async {
    SharedPreferences.setMockInitialValues({});

    final provider = SiteProvider();
    await provider.loadSites();

    expect(provider.sites, isEmpty);
    expect(provider.currentIndex, 0);
  });
}

String _encodeMiniPlayerShare(Map<String, dynamic> payload) {
  const secret = 'miniPlayer.site-share.v1.fixed-client-key.2026';
  const macPrefix = 'miniPlayer-site-share-mac';
  const sharePrefix = 'MINIPLAYER_SITE_SHARE_V1:';
  final salt = List<int>.generate(16, (index) => index);
  final plain = utf8.encode(json.encode(payload));
  final key = sha256.convert([...utf8.encode(secret), ...salt]).bytes;
  final stream = <int>[];
  var counter = 0;
  while (stream.length < plain.length) {
    stream.addAll(
      sha256
          .convert([...key, ...salt, ...utf8.encode(counter.toString())]).bytes,
    );
    counter++;
  }
  final cipher = [
    for (var i = 0; i < plain.length; i++) plain[i] ^ stream[i],
  ];
  final mac = sha256
      .convert([
        ...utf8.encode(macPrefix),
        ...utf8.encode(secret),
        ...salt,
        ...cipher,
      ])
      .bytes
      .sublist(0, 16);
  String encode(List<int> bytes) =>
      base64Url.encode(bytes).replaceAll('=', '');
  final package = {
    'v': 1,
    'salt': encode(salt),
    'data': encode(cipher),
    'mac': encode(mac),
  };
  return sharePrefix + encode(utf8.encode(json.encode(package)));
}
