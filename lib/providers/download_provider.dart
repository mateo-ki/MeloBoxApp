import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

enum DownloadStatus {
  pending,
  downloading,
  completed,
  failed,
  paused,
}

class DownloadTask {
  final String id;
  final String videoId;
  final String videoName;
  final String episodeName;
  final String url;
  final String savePath;
  DownloadStatus status;
  double progress; // 0.0 - 1.0
  int downloadedBytes;
  int totalBytes;
  DateTime createTime;
  DateTime? completeTime;
  String? errorMessage;

  DownloadTask({
    required this.id,
    required this.videoId,
    required this.videoName,
    required this.episodeName,
    required this.url,
    required this.savePath,
    this.status = DownloadStatus.pending,
    this.progress = 0.0,
    this.downloadedBytes = 0,
    this.totalBytes = 0,
    required this.createTime,
    this.completeTime,
    this.errorMessage,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'videoId': videoId,
      'videoName': videoName,
      'episodeName': episodeName,
      'url': url,
      'savePath': savePath,
      'status': status.index,
      'progress': progress,
      'downloadedBytes': downloadedBytes,
      'totalBytes': totalBytes,
      'createTime': createTime.toIso8601String(),
      'completeTime': completeTime?.toIso8601String(),
      'errorMessage': errorMessage,
    };
  }

  factory DownloadTask.fromJson(Map<String, dynamic> json) {
    return DownloadTask(
      id: json['id'] as String,
      videoId: json['videoId'] as String,
      videoName: json['videoName'] as String,
      episodeName: json['episodeName'] as String,
      url: json['url'] as String,
      savePath: json['savePath'] as String,
      status: DownloadStatus.values[json['status'] as int],
      progress: (json['progress'] as num).toDouble(),
      downloadedBytes: json['downloadedBytes'] as int,
      totalBytes: json['totalBytes'] as int,
      createTime: DateTime.parse(json['createTime'] as String),
      completeTime: json['completeTime'] != null
          ? DateTime.parse(json['completeTime'] as String)
          : null,
      errorMessage: json['errorMessage'] as String?,
    );
  }

  String get statusText {
    switch (status) {
      case DownloadStatus.pending:
        return '等待中';
      case DownloadStatus.downloading:
        return '下载中';
      case DownloadStatus.completed:
        return '已完成';
      case DownloadStatus.failed:
        return '失败';
      case DownloadStatus.paused:
        return '已暂停';
    }
  }

  String get progressText {
    if (totalBytes > 0) {
      final mb = (downloadedBytes / 1024 / 1024).toStringAsFixed(2);
      final totalMb = (totalBytes / 1024 / 1024).toStringAsFixed(2);
      return '$mb MB / $totalMb MB';
    }
    return '${(progress * 100).toStringAsFixed(1)}%';
  }
}

class DownloadProvider extends ChangeNotifier {
  static const String _key = 'download_tasks';

  final List<DownloadTask> _tasks = [];

  List<DownloadTask> get tasks => _tasks;
  List<DownloadTask> get downloadingTasks =>
      _tasks.where((t) => t.status == DownloadStatus.downloading).toList();
  List<DownloadTask> get completedTasks =>
      _tasks.where((t) => t.status == DownloadStatus.completed).toList();

  Future<void> loadTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final String? tasksJson = prefs.getString(_key);

    if (tasksJson != null) {
      try {
        final List<dynamic> decoded = json.decode(tasksJson);
        _tasks.clear();
        _tasks.addAll(decoded.map((e) => DownloadTask.fromJson(e)));
        notifyListeners();
      } catch (e) {
        debugPrint('Error loading download tasks: $e');
      }
    }
  }

  Future<void> addTask({
    required String videoId,
    required String videoName,
    required String episodeName,
    required String url,
  }) async {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final savePath = '/storage/emulated/0/Download/MeloBox/$videoName/$episodeName.mp4';

    final task = DownloadTask(
      id: id,
      videoId: videoId,
      videoName: videoName,
      episodeName: episodeName,
      url: url,
      savePath: savePath,
      createTime: DateTime.now(),
    );

    _tasks.insert(0, task);
    await _saveTasks();
    notifyListeners();

    // TODO: 实际下载逻辑
    // 这里需要集成下载库如 dio 或 flutter_downloader
  }

  Future<void> pauseTask(String taskId) async {
    final task = _tasks.firstWhere((t) => t.id == taskId);
    task.status = DownloadStatus.paused;
    await _saveTasks();
    notifyListeners();
  }

  Future<void> resumeTask(String taskId) async {
    final task = _tasks.firstWhere((t) => t.id == taskId);
    task.status = DownloadStatus.downloading;
    await _saveTasks();
    notifyListeners();
  }

  Future<void> cancelTask(String taskId) async {
    _tasks.removeWhere((t) => t.id == taskId);
    await _saveTasks();
    notifyListeners();
  }

  Future<void> retryTask(String taskId) async {
    final task = _tasks.firstWhere((t) => t.id == taskId);
    task.status = DownloadStatus.pending;
    task.progress = 0.0;
    task.downloadedBytes = 0;
    task.errorMessage = null;
    await _saveTasks();
    notifyListeners();
  }

  Future<void> clearCompleted() async {
    _tasks.removeWhere((t) => t.status == DownloadStatus.completed);
    await _saveTasks();
    notifyListeners();
  }

  Future<void> _saveTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final String tasksJson = json.encode(_tasks.map((t) => t.toJson()).toList());
    await prefs.setString(_key, tasksJson);
  }
}
