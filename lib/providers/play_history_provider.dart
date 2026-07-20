import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class PlayHistory {
  final String videoId;
  final String videoName;
  final String videoPic;
  final String episodeName;
  final String episodeUrl;
  final DateTime watchTime;
  final int progress; // 播放进度（秒）

  PlayHistory({
    required this.videoId,
    required this.videoName,
    required this.videoPic,
    required this.episodeName,
    required this.episodeUrl,
    required this.watchTime,
    this.progress = 0,
  });

  Map<String, dynamic> toJson() {
    return {
      'videoId': videoId,
      'videoName': videoName,
      'videoPic': videoPic,
      'episodeName': episodeName,
      'episodeUrl': episodeUrl,
      'watchTime': watchTime.toIso8601String(),
      'progress': progress,
    };
  }

  factory PlayHistory.fromJson(Map<String, dynamic> json) {
    return PlayHistory(
      videoId: json['videoId'] as String,
      videoName: json['videoName'] as String,
      videoPic: json['videoPic'] as String,
      episodeName: json['episodeName'] as String,
      episodeUrl: json['episodeUrl'] as String,
      watchTime: DateTime.parse(json['watchTime'] as String),
      progress: json['progress'] as int? ?? 0,
    );
  }
}

class PlayHistoryProvider extends ChangeNotifier {
  static const String _key = 'play_history';
  static const int _maxHistory = 50;

  List<PlayHistory> _history = [];

  List<PlayHistory> get history => _history;

  Future<void> loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final String? historyJson = prefs.getString(_key);

    if (historyJson != null) {
      try {
        final List<dynamic> decoded = json.decode(historyJson);
        _history = decoded.map((e) => PlayHistory.fromJson(e)).toList();
        notifyListeners();
      } catch (e) {
        debugPrint('Error loading play history: $e');
      }
    }
  }

  Future<void> addHistory({
    required String videoId,
    required String videoName,
    required String videoPic,
    required String episodeName,
    required String episodeUrl,
    int progress = 0,
  }) async {
    // 移除同一视频的旧记录
    _history.removeWhere((h) => h.videoId == videoId && h.episodeName == episodeName);

    // 添加新记录到开头
    _history.insert(
      0,
      PlayHistory(
        videoId: videoId,
        videoName: videoName,
        videoPic: videoPic,
        episodeName: episodeName,
        episodeUrl: episodeUrl,
        watchTime: DateTime.now(),
        progress: progress,
      ),
    );

    // 限制数量
    if (_history.length > _maxHistory) {
      _history = _history.sublist(0, _maxHistory);
    }

    await _saveHistory();
    notifyListeners();
  }

  Future<void> removeHistory(String videoId) async {
    _history.removeWhere((h) => h.videoId == videoId);
    await _saveHistory();
    notifyListeners();
  }

  Future<void> clearHistory() async {
    _history.clear();
    await _saveHistory();
    notifyListeners();
  }

  PlayHistory? getLastPlayHistory(String videoId) {
    try {
      return _history.firstWhere((h) => h.videoId == videoId);
    } catch (e) {
      return null;
    }
  }

  Future<void> _saveHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final String historyJson = json.encode(_history.map((h) => h.toJson()).toList());
    await prefs.setString(_key, historyJson);
  }
}
