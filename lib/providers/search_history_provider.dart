import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class SearchHistoryProvider extends ChangeNotifier {
  static const String _key = 'search_history';
  static const int _maxHistory = 10;

  List<String> _history = [];

  List<String> get history => _history;

  Future<void> loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final String? historyJson = prefs.getString(_key);

    if (historyJson != null) {
      try {
        final List<dynamic> decoded = json.decode(historyJson);
        _history = decoded.map((e) => e.toString()).toList();
        notifyListeners();
      } catch (e) {
        debugPrint('Error loading search history: $e');
      }
    }
  }

  Future<void> addSearch(String keyword) async {
    if (keyword.trim().isEmpty) return;

    // 移除重复项
    _history.remove(keyword);

    // 添加到开头
    _history.insert(0, keyword);

    // 限制数量
    if (_history.length > _maxHistory) {
      _history = _history.sublist(0, _maxHistory);
    }

    // 保存
    await _saveHistory();
    notifyListeners();
  }

  Future<void> removeSearch(String keyword) async {
    _history.remove(keyword);
    await _saveHistory();
    notifyListeners();
  }

  Future<void> clearHistory() async {
    _history.clear();
    await _saveHistory();
    notifyListeners();
  }

  Future<void> _saveHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, json.encode(_history));
  }
}
