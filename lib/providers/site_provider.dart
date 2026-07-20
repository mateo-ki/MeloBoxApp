import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/api_site.dart';

class SiteProvider extends ChangeNotifier {
  static const String _sitesStorageKey = 'customApiSitesConfig';
  static const String _currentIndexStorageKey = 'currentSiteIndex';
  static const String _sharePrefix = 'MINIPLAYER_SITE_SHARE_V1:';
  static const String _shareType = 'api-sites';
  static const String _shareSecret =
      'miniPlayer.site-share.v1.fixed-client-key.2026';
  static const String _shareMacPrefix = 'miniPlayer-site-share-mac';

  final Random _random = Random.secure();

  List<ApiSite> _sites = [];
  int _currentIndex = 0;
  bool _isLoading = false;

  List<ApiSite> get sites => _sites;
  int get currentIndex => _currentIndex;
  bool get isLoading => _isLoading;

  List<ApiSite> get videoSites =>
      _sites.where((site) => site.type == 'video').toList(growable: false);

  List<ApiSite> get shortVideoSites =>
      _sites.where((site) => site.type == 'shortvideo').toList(growable: false);

  ApiSite? get currentSite {
    final videos = videoSites;
    if (videos.isEmpty) return null;
    if (_currentIndex >= 0 && _currentIndex < videos.length) {
      return videos[_currentIndex];
    }
    return videos.first;
  }

  static int normalizeVideoIndex(int index, int videoCount) {
    if (videoCount <= 0) {
      return 0;
    }
    if (index < 0 || index >= videoCount) {
      return 0;
    }
    return index;
  }

  static String normalizeBaseUrl(String baseUrl) {
    var normalized = baseUrl.trim();
    while (normalized.endsWith('/')) {
      normalized = normalized.substring(0, normalized.length - 1);
    }
    return normalized.toLowerCase();
  }

  Future<void> loadSites() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final storedConfig = await _loadStoredConfig(prefs);
      final config = storedConfig ?? ApiSitesConfig(currentIndex: 0, sites: []);

      _sites = config.sites.map(_repairKnownSiteName).toList(growable: false);
      _currentIndex = normalizeVideoIndex(
        prefs.getInt(_currentIndexStorageKey) ?? config.currentIndex,
        videoSites.length,
      );

      if (storedConfig == null) {
        await _saveConfig(
          prefs,
          ApiSitesConfig(currentIndex: _currentIndex, sites: _sites),
        );
      }
    } catch (e) {
      debugPrint('Error loading sites: $e');
      _sites = [];
      _currentIndex = 0;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> setCurrentIndex(int index) async {
    if (index < 0 || index >= videoSites.length) {
      return;
    }

    _currentIndex = index;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_currentIndexStorageKey, index);
  }

  Future<void> addSite(ApiSite site) async {
    _sites = [..._sites, _normalizedSite(site)];
    await _persistAndNotify();
  }

  Future<void> updateVideoSite(int videoIndex, ApiSite site) async {
    final siteIndex = _siteIndexForVideoIndex(videoIndex);
    if (siteIndex == -1) {
      return;
    }

    _sites = [
      for (var i = 0; i < _sites.length; i++)
        if (i == siteIndex) _normalizedSite(site) else _sites[i],
    ];
    await _persistAndNotify();
  }

  Future<void> updateSiteByType(
    String type,
    int typeIndex,
    ApiSite site,
  ) async {
    final siteIndex = _siteIndexForTypeIndex(type, typeIndex);
    if (siteIndex == -1) {
      return;
    }

    _sites = [
      for (var i = 0; i < _sites.length; i++)
        if (i == siteIndex) _normalizedSite(site) else _sites[i],
    ];
    await _persistAndNotify();
  }

  Future<void> deleteVideoSite(int videoIndex) async {
    final siteIndex = _siteIndexForVideoIndex(videoIndex);
    if (siteIndex == -1) {
      return;
    }

    _sites = [
      for (var i = 0; i < _sites.length; i++)
        if (i != siteIndex) _sites[i],
    ];
    if (_currentIndex >= videoIndex) {
      _currentIndex--;
    }
    await _persistAndNotify();
  }

  Future<void> deleteSiteByType(String type, int typeIndex) async {
    final siteIndex = _siteIndexForTypeIndex(type, typeIndex);
    if (siteIndex == -1) {
      return;
    }

    _sites = [
      for (var i = 0; i < _sites.length; i++)
        if (i != siteIndex) _sites[i],
    ];
    if (type == 'video' && _currentIndex >= typeIndex) {
      _currentIndex--;
    }
    await _persistAndNotify();
  }

  Future<void> resetSites() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sitesStorageKey);

    final config = await _loadBundledConfig();
    _sites = config.sites.map(_repairKnownSiteName).toList(growable: false);
    _currentIndex = normalizeVideoIndex(config.currentIndex, videoSites.length);
    await _saveConfig(prefs, config);
    await prefs.setInt(_currentIndexStorageKey, _currentIndex);
    notifyListeners();
  }

  Future<void> clearSites({String? type}) async {
    final prefs = await SharedPreferences.getInstance();
    _sites = type == null
        ? []
        : _sites.where((site) => site.type != type).toList(growable: false);
    _currentIndex = 0;
    await _saveConfig(
      prefs,
      ApiSitesConfig(currentIndex: _currentIndex, sites: _sites),
    );
    await prefs.setInt(_currentIndexStorageKey, _currentIndex);
    notifyListeners();
  }

  Future<String> exportEncryptedShareText({Iterable<int>? indexes}) async {
    final selectedSites = indexes == null
        ? _sites
        : [
            for (final index in indexes)
              if (index >= 0 && index < _sites.length) _sites[index],
          ];

    final payloadSites = selectedSites
        .where((site) =>
            site.name.trim().isNotEmpty && site.baseUrl.trim().isNotEmpty)
        .map(
          (site) => {
            'name': site.name.trim(),
            'baseUrl': site.baseUrl.trim(),
            'type': site.type.trim(),
            if (site.followRedirects != null)
              'followRedirects': site.followRedirects,
          },
        )
        .toList(growable: false);

    if (payloadSites.isEmpty) {
      throw StateError('没有可导出的站点');
    }

    final payload = <String, dynamic>{
      'type': _shareType,
      'version': 1,
      'createdAt': DateTime.now().toUtc().toIso8601String(),
      'sites': payloadSites,
    };

    return _encodeSharePayload(payload);
  }

  Future<String> importEncryptedShareText(String text) async {
    final payload = _decodeSharePayload(text);
    if (payload['type'] != _shareType) {
      throw StateError('分享内容类型不匹配');
    }

    final sites = payload['sites'];
    if (sites is! List || sites.isEmpty) {
      throw StateError('分享内容里没有站点');
    }

    var imported = 0;
    var updated = 0;
    var skipped = 0;

    for (final value in sites) {
      if (value is! Map) {
        skipped++;
        continue;
      }

      final name = (value['name']?.toString() ?? '').trim();
      final baseUrl = (value['baseUrl']?.toString() ?? '').trim();
      if (name.isEmpty || baseUrl.isEmpty) {
        skipped++;
        continue;
      }

      final type = _normalizeImportedSiteType(
        (value['siteType'] ?? value['type'])?.toString(),
      );
      final followRedirects = value['followRedirects'] == true ? true : null;
      final normalizedUrl = normalizeBaseUrl(baseUrl);
      final existingIndex = _sites.indexWhere(
        (site) => normalizeBaseUrl(site.baseUrl) == normalizedUrl,
      );

      final incoming = ApiSite(
        baseUrl: baseUrl,
        name: name,
        type: type,
        followRedirects: followRedirects,
      );

      if (existingIndex >= 0) {
        final current = _sites[existingIndex];
        if (current.name != incoming.name ||
            current.baseUrl != incoming.baseUrl ||
            current.type != incoming.type ||
            current.followRedirects != incoming.followRedirects) {
          _sites[existingIndex] = incoming;
          updated++;
        } else {
          skipped++;
        }
        continue;
      }

      _sites = [..._sites, incoming];
      imported++;
    }

    if (imported > 0 || updated > 0) {
      await _persistAndNotify();
    }

    return '导入完成：新增 $imported 个，更新 $updated 个，跳过 $skipped 个';
  }

  Future<String> importSitesFromClipboard() async {
    final clipboard = await Clipboard.getData(Clipboard.kTextPlain);
    final text = clipboard?.text?.trim() ?? '';
    if (text.isEmpty) {
      throw StateError('剪贴板为空');
    }
    return importEncryptedShareText(text);
  }

  Future<String> importSitesFromUrl(String url) async {
    final uri = Uri.tryParse(url.trim());
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
      throw StateError('链接格式不正确');
    }

    final response = await http.get(uri).timeout(
          const Duration(seconds: 15),
        );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError('订阅请求失败：${response.statusCode}');
    }

    return importEncryptedShareText(response.body.trim());
  }

  Future<void> copyExportToClipboard({Iterable<int>? indexes}) async {
    final text = await exportEncryptedShareText(indexes: indexes);
    await Clipboard.setData(ClipboardData(text: text));
  }

  Future<ApiSitesConfig?> _loadStoredConfig(SharedPreferences prefs) async {
    final stored = prefs.getString(_sitesStorageKey);
    if (stored == null || stored.trim().isEmpty) {
      return null;
    }

    try {
      return ApiSitesConfig.fromJson(
          json.decode(stored) as Map<String, dynamic>);
    } catch (e) {
      debugPrint('Stored site config parse error: $e');
      return null;
    }
  }

  Future<ApiSitesConfig> _loadBundledConfig() async {
    final response = await rootBundle.loadString('api_sites.json');
    return ApiSitesConfig.fromJson(
        json.decode(response) as Map<String, dynamic>);
  }

  Future<void> _persistAndNotify() async {
    final prefs = await SharedPreferences.getInstance();
    _currentIndex = normalizeVideoIndex(_currentIndex, videoSites.length);
    await _saveConfig(
      prefs,
      ApiSitesConfig(currentIndex: _currentIndex, sites: _sites),
    );
    await prefs.setInt(_currentIndexStorageKey, _currentIndex);
    notifyListeners();
  }

  Future<void> _saveConfig(SharedPreferences prefs, ApiSitesConfig config) {
    return prefs.setString(_sitesStorageKey, json.encode(config.toJson()));
  }

  int _siteIndexForVideoIndex(int videoIndex) {
    return _siteIndexForTypeIndex('video', videoIndex);
  }

  int _siteIndexForTypeIndex(String type, int typeIndex) {
    var currentVideoIndex = 0;
    for (var i = 0; i < _sites.length; i++) {
      if (_sites[i].type != type) {
        continue;
      }
      if (currentVideoIndex == typeIndex) {
        return i;
      }
      currentVideoIndex++;
    }
    return -1;
  }

  ApiSite _normalizedSite(ApiSite site) {
    return _repairKnownSiteName(
      site.copyWith(
        baseUrl: site.baseUrl.trim(),
        name: site.name.trim(),
        type: _normalizeImportedSiteType(site.type),
      ),
    );
  }

  ApiSite _repairKnownSiteName(ApiSite site) {
    final repairedName = _knownNameRepairs[site.name];
    if (repairedName == null) {
      return site;
    }
    return site.copyWith(name: repairedName);
  }

  String _normalizeImportedSiteType(String? type) {
    final normalized = (type ?? 'video').trim().toLowerCase();
    if (normalized == 'image') return 'image';
    if (normalized == 'shortvideo' ||
        normalized == 'short_video' ||
        normalized == 'short-video') {
      return 'shortvideo';
    }
    if (normalized == 'music') return 'music';
    return 'video';
  }

  String _encodeSharePayload(Map<String, dynamic> payload) {
    final plain = utf8.encode(json.encode(payload));
    final salt = _randomSalt();
    final cipher = _cryptBytes(plain, salt);

    final package = <String, dynamic>{
      'v': 1,
      'salt': _toBase64Text(salt),
      'data': _toBase64Text(cipher),
      'mac': _toBase64Text(_payloadMac(salt, cipher)),
    };

    final packageJson = utf8.encode(json.encode(package));
    return _sharePrefix + _toBase64Text(packageJson);
  }

  Map<String, dynamic> _decodeSharePayload(String text) {
    final trimmed = text.trim();
    if (!trimmed.startsWith(_sharePrefix)) {
      throw StateError('剪贴板里没有可识别的 MeloBox 加密站点分享');
    }

    final packageBytes =
        _fromBase64Text(trimmed.substring(_sharePrefix.length));
    final package = json.decode(utf8.decode(packageBytes));
    if (package is! Map<String, dynamic> || package['v'] != 1) {
      throw StateError('分享包版本不匹配');
    }

    final salt = _fromBase64Text(package['salt'] as String);
    final cipher = _fromBase64Text(package['data'] as String);
    final mac = _fromBase64Text(package['mac'] as String);
    if (!_constantTimeEquals(mac, _payloadMac(salt, cipher))) {
      throw StateError('分享内容校验失败');
    }

    final plain = _cryptBytes(cipher, salt);
    final payload = json.decode(utf8.decode(plain));
    if (payload is! Map<String, dynamic>) {
      throw StateError('分享内容解析失败');
    }
    return payload;
  }

  Uint8List _randomSalt() {
    return Uint8List.fromList(
        List<int>.generate(16, (_) => _random.nextInt(256)));
  }

  Uint8List _cryptBytes(List<int> input, List<int> salt) {
    final key = _sha256Bytes([...utf8.encode(_shareSecret), ...salt]);
    final output = Uint8List(input.length);
    final stream = <int>[];
    var counter = 0;

    while (stream.length < input.length) {
      stream.addAll(
        _sha256Bytes([
          ...key,
          ...salt,
          ...utf8.encode(counter.toString()),
        ]),
      );
      counter++;
    }

    for (var i = 0; i < input.length; i++) {
      output[i] = input[i] ^ stream[i];
    }

    return output;
  }

  Uint8List _payloadMac(List<int> salt, List<int> cipher) {
    return Uint8List.fromList(
      _sha256Bytes([
        ...utf8.encode(_shareMacPrefix),
        ...utf8.encode(_shareSecret),
        ...salt,
        ...cipher,
      ]).sublist(0, 16),
    );
  }

  Uint8List _sha256Bytes(List<int> data) {
    return Uint8List.fromList(sha256.convert(data).bytes);
  }

  String _toBase64Text(List<int> data) {
    return base64Url.encode(data).replaceAll('=', '');
  }

  Uint8List _fromBase64Text(String text) {
    final normalized =
        text.padRight(text.length + (4 - text.length % 4) % 4, '=');
    return Uint8List.fromList(base64Url.decode(normalized));
  }

  bool _constantTimeEquals(List<int> a, List<int> b) {
    if (a.length != b.length) {
      return false;
    }
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a[i] ^ b[i];
    }
    return diff == 0;
  }

  static const Map<String, String> _knownNameRepairs = {
    '榛樿': '默认',
    '濂冲ぇ': '女大',
    '濂抽珮': '女高',
    '鎬艰劯': '怼脸',
    '榛戜笣': '黑丝',
    '鐧戒笣': '白丝',
    '婕睍': '漫展',
    '瀹岀編韬潗': '完美身材',
    '鐗硅壊鏈嶈': '特色服装',
    '鍚婂甫': '吊带',
    '瓒虫帶': '足控',
    '娓呯函': '清纯',
    '蹇墜鍙樿': '快手变装',
    '钀濊帀': '萝莉',
    '鍙樿': '变装',
    '灏忓濮愯仛鍚?': '小姐姐聚合',
    '灏忓濮愮儹鑸?': '小姐姐热舞',
    '灏忓濮?': '小姐姐',
  };
}
