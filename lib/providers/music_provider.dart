import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:media_kit/media_kit.dart' as mk;

import '../models/music.dart';

class MusicProvider extends ChangeNotifier {
  final mk.Player _player = mk.Player();
  final List<StreamSubscription<dynamic>> _subscriptions = [];

  List<MusicTrack> _results = [];
  MusicTrack? _currentTrack;
  List<MusicLyricLine> _lyricLines = [];
  int _currentLyricIndex = -1;
  bool _isLoading = false;
  bool _isPlaying = false;
  String _message = '';
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  double _volume = 1.0;

  MusicProvider() {
    _subscriptions.add(
      _player.stream.playing.listen((playing) {
        _isPlaying = playing;
        notifyListeners();
      }),
    );
    _subscriptions.add(
      _player.stream.position.listen((position) {
        _position = position;
        _updateLyricIndex();
        notifyListeners();
      }),
    );
    _subscriptions.add(
      _player.stream.duration.listen((duration) {
        _duration = duration;
        notifyListeners();
      }),
    );
    _subscriptions.add(
      _player.stream.error.listen((error) {
        if (error.isNotEmpty) {
          _message = '音乐播放失败: $error';
          notifyListeners();
        }
      }),
    );
  }

  List<MusicTrack> get results => _results;
  MusicTrack? get currentTrack => _currentTrack;
  List<MusicLyricLine> get lyricLines => _lyricLines;
  int get currentLyricIndex => _currentLyricIndex;
  bool get isLoading => _isLoading;
  bool get isPlaying => _isPlaying;
  String get message => _message;
  Duration get position => _position;
  Duration get duration => _duration;
  double get volume => _volume;

  Future<void> searchMusic(
    String keyword, {
    String server = 'netease',
  }) async {
    final trimmedKeyword = keyword.trim();
    if (trimmedKeyword.isEmpty) {
      _message = '请输入歌曲名、作者或关键字';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _message = '正在搜索音乐: $trimmedKeyword';
    notifyListeners();

    try {
      final uri = Uri.https('music.api.songziheng.com', '/api', {
        'server': server.trim().isEmpty ? 'netease' : server.trim(),
        'type': 'search',
        'id': trimmedKeyword,
        'r': DateTime.now().millisecondsSinceEpoch.toString(),
      });

      final response = await http.get(uri).timeout(const Duration(seconds: 12));
      if (response.statusCode != 200) {
        _message = '音乐搜索失败: ${response.statusCode}';
        return;
      }

      final rows = _extractRows(json.decode(response.body));
      _results = rows
          .whereType<Map>()
          .map((item) => MusicTrack.fromApiJson(Map<String, dynamic>.from(item)))
          .where((track) => track.title.isNotEmpty && track.url.isNotEmpty)
          .toList(growable: false);
      _message = _results.isEmpty
          ? '没有搜索到“$trimmedKeyword”的音乐'
          : '已找到 ${_results.length} 首“$trimmedKeyword”相关音乐';
    } catch (e) {
      _message = '音乐搜索失败: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> playTrack(MusicTrack track) async {
    if (track.url.isEmpty) {
      _message = '歌曲播放地址为空';
      notifyListeners();
      return;
    }

    _currentTrack = track;
    _position = Duration.zero;
    _duration = Duration.zero;
    _lyricLines = [];
    _currentLyricIndex = -1;
    _message = '正在播放: ${track.title} - ${track.artist}';
    notifyListeners();

    try {
      await _player.stop();
      await _player.open(
        mk.Media(track.url),
        play: true,
      );
      await _player.setVolume(_volume * 100);
      await _loadLyrics(track.lrcUrl);
    } catch (e) {
      _message = '音乐播放失败: $e';
      notifyListeners();
    }
  }

  Future<void> togglePlayPause() async {
    if (_currentTrack == null) {
      return;
    }

    if (_isPlaying) {
      await _player.pause();
    } else {
      await _player.play();
    }
  }

  Future<void> stop() async {
    await _player.stop();
    _isPlaying = false;
    _position = Duration.zero;
    _currentLyricIndex = -1;
    notifyListeners();
  }

  Future<void> seek(Duration position) async {
    await _player.seek(position);
    _position = position;
    _updateLyricIndex();
    notifyListeners();
  }

  Future<void> setVolume(double volume) async {
    _volume = volume.clamp(0.0, 1.0);
    await _player.setVolume(_volume * 100);
    notifyListeners();
  }

  List<dynamic> _extractRows(dynamic jsonData) {
    if (jsonData is List) {
      return jsonData;
    }
    if (jsonData is Map) {
      for (final key in const ['data', 'result', 'songs']) {
        final value = jsonData[key];
        if (value is List) {
          return value;
        }
      }
    }
    return const [];
  }

  Future<void> _loadLyrics(String lrcUrl) async {
    if (lrcUrl.trim().isEmpty) {
      _lyricLines = const [];
      notifyListeners();
      return;
    }

    try {
      final response = await http
          .get(Uri.parse(lrcUrl))
          .timeout(const Duration(seconds: 8));
      if (response.statusCode == 200) {
        _lyricLines = parseLrcLines(utf8.decode(response.bodyBytes));
      }
    } catch (e) {
      _message = '歌词加载失败: $e';
    } finally {
      _updateLyricIndex();
      notifyListeners();
    }
  }

  void _updateLyricIndex() {
    _currentLyricIndex = activeLyricIndex(_lyricLines, _position);
  }

  @override
  void dispose() {
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    _player.dispose();
    super.dispose();
  }
}
