import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';

import '../models/video.dart';
import '../utils/helpers.dart';

class VideoProvider extends ChangeNotifier {
  List<Video> _videos = [];
  VideoDetail? _currentVideoDetail;
  bool _isLoading = false;
  String _error = '';

  List<Video> get videos => _videos;
  VideoDetail? get currentVideoDetail => _currentVideoDetail;
  bool get isLoading => _isLoading;
  String get error => _error;

  List<Video> _parseResponse(String body, String baseUrl) {
    final trimmedBody = body.trim();

    if (trimmedBody.startsWith('{') || trimmedBody.startsWith('[')) {
      try {
        final jsonData = json.decode(trimmedBody);

        if (jsonData is Map && jsonData.containsKey('list')) {
          final list = jsonData['list'] as List;
          return list
              .map((item) => _withResolvedPic(Video.fromJson(item), baseUrl))
              .toList();
        }
        return [];
      } catch (e) {
        debugPrint('JSON parse error: $e');
        throw Exception('JSON解析失败');
      }
    }

    try {
      var xmlBody = trimmedBody;
      if (xmlBody.startsWith('锘')) {
        xmlBody = xmlBody.substring(1);
      }
      if (!xmlBody.startsWith('<?xml')) {
        xmlBody = '<?xml version="1.0" encoding="UTF-8"?>\n$xmlBody';
      }

      final document = XmlDocument.parse(xmlBody);
      return document
          .findAllElements('video')
          .map((e) => _withResolvedPic(Video.fromXml(e), baseUrl))
          .toList();
    } catch (e) {
      debugPrint('XML parse error: $e');
      throw Exception('XML解析失败');
    }
  }

  Video _withResolvedPic(Video video, String baseUrl) {
    final resolvedPic = MediaUrlHelper.resolveMediaUrl(video.pic, baseUrl);

    return Video(
      id: video.id,
      name: video.name,
      pic: resolvedPic,
      note: video.note,
      type: video.type,
      actor: video.actor,
      director: video.director,
      des: video.des,
      year: video.year,
      area: video.area,
      lang: video.lang,
    );
  }

  VideoDetail _withResolvedDetailPic(VideoDetail detail, String baseUrl) {
    final resolvedPic = MediaUrlHelper.resolveMediaUrl(detail.pic, baseUrl);

    return VideoDetail(
      id: detail.id,
      name: detail.name,
      pic: resolvedPic,
      note: detail.note,
      type: detail.type,
      actor: detail.actor,
      director: detail.director,
      des: detail.des,
      year: detail.year,
      area: detail.area,
      lang: detail.lang,
      playUrls: detail.playUrls,
    );
  }

  Uri _buildApiUri(String baseUrl, Map<String, String> queryParameters) {
    final uri = Uri.parse(baseUrl);
    final mergedQuery = Map<String, String>.from(uri.queryParameters)
      ..addAll(queryParameters);
    return uri.replace(queryParameters: mergedQuery);
  }

  Uri _buildCategoryUri(String baseUrl, String categoryId) {
    final uri = Uri.parse(baseUrl);
    final mergedQuery = Map<String, String>.from(uri.queryParameters)
      ..remove('ac')
      ..remove('pg')
      ..addAll({'t': categoryId});
    return uri.replace(queryParameters: mergedQuery);
  }

  List<VideoDetail> _parseDetailResponse(String body, String baseUrl) {
    final trimmedBody = body.trim();

    if (trimmedBody.startsWith('{') || trimmedBody.startsWith('[')) {
      final jsonData = json.decode(trimmedBody);
      if (jsonData is Map && jsonData.containsKey('list')) {
        final list = jsonData['list'] as List;
        return list
            .map((item) =>
                _withResolvedDetailPic(VideoDetail.fromJson(item), baseUrl))
            .toList();
      }
      return [];
    }

    var xmlBody = trimmedBody;
    if (xmlBody.startsWith('锘')) {
      xmlBody = xmlBody.substring(1);
    }
    if (!xmlBody.startsWith('<?xml')) {
      xmlBody = '<?xml version="1.0" encoding="UTF-8"?>\n$xmlBody';
    }

    final document = XmlDocument.parse(xmlBody);
    return document
        .findAllElements('video')
        .map((element) =>
            _withResolvedDetailPic(VideoDetail.fromXml(element), baseUrl))
        .toList();
  }

  Future<List<Video>> _hydrateListWithDetails(
    String baseUrl,
    List<Video> videos,
  ) async {
    final ids = videos
        .map((video) => video.id.trim())
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList(growable: false);

    if (ids.isEmpty) {
      return videos;
    }

    try {
      final detailById = <String, VideoDetail>{};
      final bulkUri = _buildApiUri(baseUrl, {
        'ac': 'detail',
        'ids': ids.join(','),
      });

      final response = await http.get(bulkUri).timeout(
            const Duration(seconds: 12),
          );

      if (response.statusCode == 200) {
        for (final detail in _parseDetailResponse(response.body, baseUrl)) {
          if (detail.id.isNotEmpty) {
            detailById[detail.id] = detail;
          }
        }
      }

      var missingIds = ids
          .where((id) => !detailById.containsKey(id) || detailById[id]!.pic.isEmpty)
          .toList(growable: false);

      if (missingIds.isNotEmpty) {
        for (var start = 0; start < missingIds.length; start += 10) {
          final end = (start + 10).clamp(0, missingIds.length);
          final chunk = missingIds.sublist(start, end);
          try {
            final chunkUri = _buildApiUri(baseUrl, {
              'ac': 'detail',
              'ids': chunk.join(','),
            });
            final chunkResponse = await http.get(chunkUri).timeout(
                  const Duration(seconds: 8),
                );

            if (chunkResponse.statusCode != 200) {
              continue;
            }

            final details = _parseDetailResponse(chunkResponse.body, baseUrl);
            for (final detail in details) {
              if (detail.id.isNotEmpty) {
                detailById[detail.id] = detail;
              }
            }
          } catch (e) {
            debugPrint('Chunk detail hydrate error for ${chunk.join(',')}: $e');
          }
        }
      }

      missingIds = ids
          .where((id) => !detailById.containsKey(id) || detailById[id]!.pic.isEmpty)
          .toList(growable: false);

      if (missingIds.isNotEmpty) {
        for (final id in missingIds) {
          try {
            final singleUri = _buildApiUri(baseUrl, {
              'ac': 'detail',
              'ids': id,
            });
            final singleResponse = await http.get(singleUri).timeout(
                  const Duration(seconds: 6),
                );

            if (singleResponse.statusCode != 200) {
              continue;
            }

            final details = _parseDetailResponse(singleResponse.body, baseUrl);
            for (final detail in details) {
              if (detail.id.isNotEmpty) {
                detailById[detail.id] = detail;
              }
            }
          } catch (e) {
            debugPrint('Single detail hydrate error for $id: $e');
          }
        }
      }

      return videos.map((video) {
        final detail = detailById[video.id];
        if (detail == null) {
          return video;
        }

        return video.copyWith(
          pic: detail.pic.isNotEmpty ? detail.pic : video.pic,
          note: detail.note.isNotEmpty ? detail.note : video.note,
          type: detail.type.isNotEmpty ? detail.type : video.type,
          actor: detail.actor ?? video.actor,
          director: detail.director ?? video.director,
          des: detail.des ?? video.des,
          year: detail.year ?? video.year,
          area: detail.area ?? video.area,
          lang: detail.lang ?? video.lang,
        );
      }).toList();
    } catch (e) {
      debugPrint('Detail hydrate error: $e');
      return videos;
    }
  }

  Future<void> searchVideos(String baseUrl, String keyword) async {
    _isLoading = true;
    _error = '';
    _videos = [];
    notifyListeners();

    try {
      final response = await http.get(_buildApiUri(baseUrl, {
        'ac': 'list',
        'wd': keyword,
      })).timeout(
            const Duration(seconds: 10),
          );

      if (response.statusCode == 200) {
        try {
          final listVideos = _parseResponse(response.body, baseUrl);
          _videos = await _hydrateListWithDetails(baseUrl, listVideos);
          if (_videos.isEmpty) {
            _error = '未找到相关视频';
          }
        } catch (e) {
          _error = '数据解析失败，该站点可能暂时不可用';
        }
      } else {
        _error = '请求失败: ${response.statusCode}';
      }
    } catch (e) {
      _error = '搜索失败: ${e.toString().contains('SocketException') ? '网络连接失败' : e.toString()}';
      debugPrint('Search error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadVideoList(String baseUrl, {int page = 1}) async {
    _isLoading = true;
    _error = '';
    _videos = [];
    notifyListeners();

    try {
      final response = await http.get(_buildApiUri(baseUrl, {
        'ac': 'list',
        'pg': page.toString(),
      })).timeout(
            const Duration(seconds: 10),
          );

      if (response.statusCode == 200) {
        try {
          final listVideos = _parseResponse(response.body, baseUrl);
          _videos = await _hydrateListWithDetails(baseUrl, listVideos);
          if (_videos.isEmpty) {
            _error = '暂无视频数据';
          }
        } catch (e) {
          _error = '数据解析失败，该站点可能暂时不可用';
        }
      } else {
        _error = '请求失败: ${response.statusCode}';
      }
    } catch (e) {
      _error = '加载失败: ${e.toString().contains('SocketException') ? '网络连接失败' : e.toString()}';
      debugPrint('Load list error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadVideoListByCategory(
    String baseUrl,
    String categoryId, {
    int page = 1,
  }) async {
    _isLoading = true;
    _error = '';
    _videos = [];
    notifyListeners();

    try {
      final categoryUri = _buildCategoryUri(baseUrl, categoryId);
      final queryParameters = Map<String, String>.from(
        categoryUri.queryParameters,
      );
      if (page > 1) {
        queryParameters['pg'] = page.toString();
      }

      final response = await http.get(
        categoryUri.replace(queryParameters: queryParameters),
      ).timeout(
            const Duration(seconds: 10),
          );

      if (response.statusCode == 200) {
        try {
          final listVideos = _parseResponse(response.body, baseUrl);
          _videos = await _hydrateListWithDetails(baseUrl, listVideos);
          if (_videos.isEmpty) {
            _error = '该分类暂无视频';
          }
        } catch (e) {
          _error = '数据解析失败，该站点可能暂时不可用';
        }
      } else {
        _error = '请求失败: ${response.statusCode}';
      }
    } catch (e) {
      _error = '加载失败: ${e.toString().contains('SocketException') ? '网络连接失败' : e.toString()}';
      debugPrint('Load category error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadVideoDetail(String baseUrl, String videoId) async {
    _isLoading = true;
    _error = '';
    _currentVideoDetail = null;
    notifyListeners();

    try {
      final response = await http.get(_buildApiUri(baseUrl, {
        'ac': 'detail',
        'ids': videoId,
      })).timeout(
            const Duration(seconds: 10),
          );

      if (response.statusCode == 200) {
        try {
          final details = _parseDetailResponse(response.body, baseUrl);
          if (details.isNotEmpty) {
            _currentVideoDetail = details.first;
          } else {
            _error = '未找到视频详情';
          }
        } catch (e) {
          debugPrint('Parse detail error: $e');
          _error = '数据解析失败';
        }
      } else {
        _error = '请求失败: ${response.statusCode}';
      }
    } catch (e) {
      _error = '加载详情失败: ${e.toString().contains('SocketException') ? '网络连接失败' : e.toString()}';
      debugPrint('Load detail error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _error = '';
    notifyListeners();
  }

  void clearVideos() {
    _videos = [];
    _error = '';
    notifyListeners();
  }
}
