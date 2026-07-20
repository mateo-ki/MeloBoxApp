import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class Favorite {
  final String videoId;
  final String videoName;
  final String videoPic;
  final String videoType;
  final String videoNote;
  final DateTime addTime;

  Favorite({
    required this.videoId,
    required this.videoName,
    required this.videoPic,
    required this.videoType,
    required this.videoNote,
    required this.addTime,
  });

  Map<String, dynamic> toJson() {
    return {
      'videoId': videoId,
      'videoName': videoName,
      'videoPic': videoPic,
      'videoType': videoType,
      'videoNote': videoNote,
      'addTime': addTime.toIso8601String(),
    };
  }

  factory Favorite.fromJson(Map<String, dynamic> json) {
    return Favorite(
      videoId: json['videoId'] as String,
      videoName: json['videoName'] as String,
      videoPic: json['videoPic'] as String,
      videoType: json['videoType'] as String? ?? '',
      videoNote: json['videoNote'] as String? ?? '',
      addTime: DateTime.parse(json['addTime'] as String),
    );
  }
}

class FavoriteProvider extends ChangeNotifier {
  static const String _key = 'favorites';

  List<Favorite> _favorites = [];

  List<Favorite> get favorites => _favorites;

  Future<void> loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final String? favoritesJson = prefs.getString(_key);

    if (favoritesJson != null) {
      try {
        final List<dynamic> decoded = json.decode(favoritesJson);
        _favorites = decoded.map((e) => Favorite.fromJson(e)).toList();
        notifyListeners();
      } catch (e) {
        debugPrint('Error loading favorites: $e');
      }
    }
  }

  bool isFavorite(String videoId) {
    return _favorites.any((f) => f.videoId == videoId);
  }

  Future<void> toggleFavorite({
    required String videoId,
    required String videoName,
    required String videoPic,
    String videoType = '',
    String videoNote = '',
  }) async {
    if (isFavorite(videoId)) {
      await removeFavorite(videoId);
    } else {
      await addFavorite(
        videoId: videoId,
        videoName: videoName,
        videoPic: videoPic,
        videoType: videoType,
        videoNote: videoNote,
      );
    }
  }

  Future<void> addFavorite({
    required String videoId,
    required String videoName,
    required String videoPic,
    String videoType = '',
    String videoNote = '',
  }) async {
    if (isFavorite(videoId)) return;

    _favorites.insert(
      0,
      Favorite(
        videoId: videoId,
        videoName: videoName,
        videoPic: videoPic,
        videoType: videoType,
        videoNote: videoNote,
        addTime: DateTime.now(),
      ),
    );

    await _saveFavorites();
    notifyListeners();
  }

  Future<void> removeFavorite(String videoId) async {
    _favorites.removeWhere((f) => f.videoId == videoId);
    await _saveFavorites();
    notifyListeners();
  }

  Future<void> clearFavorites() async {
    _favorites.clear();
    await _saveFavorites();
    notifyListeners();
  }

  Future<void> _saveFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final String favoritesJson = json.encode(_favorites.map((f) => f.toJson()).toList());
    await prefs.setString(_key, favoritesJson);
  }
}
