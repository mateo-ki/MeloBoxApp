import 'package:flutter/material.dart';

class VideoCategory {
  final String id;
  final String name;

  VideoCategory({
    required this.id,
    required this.name,
  });
}

class VideoCategoryProvider extends ChangeNotifier {
  final List<VideoCategory> _categories = [
    VideoCategory(id: '', name: '全部'),
    VideoCategory(id: '1', name: '电影'),
    VideoCategory(id: '2', name: '电视剧'),
    VideoCategory(id: '3', name: '综艺'),
    VideoCategory(id: '4', name: '动漫'),
    VideoCategory(id: '5', name: '纪录片'),
    VideoCategory(id: '6', name: '短剧'),
  ];

  String _selectedCategoryId = '';

  List<VideoCategory> get categories => _categories;
  String get selectedCategoryId => _selectedCategoryId;

  VideoCategory get selectedCategory {
    return _categories.firstWhere(
      (c) => c.id == _selectedCategoryId,
      orElse: () => _categories.first,
    );
  }

  void selectCategory(String categoryId) {
    if (_selectedCategoryId != categoryId) {
      _selectedCategoryId = categoryId;
      notifyListeners();
    }
  }

  void reset() {
    _selectedCategoryId = '';
    notifyListeners();
  }
}
