import '../models/api_site.dart';

class ImageProvider {
  final List<ApiSite> _imageSites = [];
  int _currentIndex = 0;

  List<ApiSite> get imageSites => _imageSites;
  int get currentIndex => _currentIndex;

  ApiSite? get currentSite {
    if (_imageSites.isEmpty) return null;
    if (_currentIndex >= 0 && _currentIndex < _imageSites.length) {
      return _imageSites[_currentIndex];
    }
    return null;
  }

  void loadImageSites(List<ApiSite> sites) {
    _imageSites.clear();
    _imageSites.addAll(sites.where((site) => site.type == 'image'));
  }

  String? getNextImageUrl() {
    if (_imageSites.isEmpty) return null;
    final site = _imageSites[_currentIndex];
    final separator = site.baseUrl.contains('?') ? '&' : '?';
    return '${site.baseUrl}${separator}t=${DateTime.now().millisecondsSinceEpoch}';
  }

  void nextSite() {
    if (_imageSites.isEmpty) return;
    _currentIndex = (_currentIndex + 1) % _imageSites.length;
  }

  void previousSite() {
    if (_imageSites.isEmpty) return;
    _currentIndex = (_currentIndex - 1 + _imageSites.length) % _imageSites.length;
  }

  void setSiteIndex(int index) {
    if (index >= 0 && index < _imageSites.length) {
      _currentIndex = index;
    }
  }
}

class ShortVideoProvider {
  final List<ApiSite> _shortVideoSites = [];
  int _currentIndex = 0;

  List<ApiSite> get shortVideoSites => _shortVideoSites;
  int get currentIndex => _currentIndex;

  ApiSite? get currentSite {
    if (_shortVideoSites.isEmpty) return null;
    if (_currentIndex >= 0 && _currentIndex < _shortVideoSites.length) {
      return _shortVideoSites[_currentIndex];
    }
    return null;
  }

  void loadShortVideoSites(List<ApiSite> sites) {
    _shortVideoSites.clear();
    _shortVideoSites.addAll(sites.where((site) => site.type == 'shortvideo'));
  }

  String? getNextVideoUrl() {
    if (_shortVideoSites.isEmpty) return null;
    final site = _shortVideoSites[_currentIndex];
    final separator = site.baseUrl.contains('?') ? '&' : '?';
    return '${site.baseUrl}${separator}t=${DateTime.now().millisecondsSinceEpoch}';
  }

  void nextSite() {
    if (_shortVideoSites.isEmpty) return;
    _currentIndex = (_currentIndex + 1) % _shortVideoSites.length;
  }

  void previousSite() {
    if (_shortVideoSites.isEmpty) return;
    _currentIndex = (_currentIndex - 1 + _shortVideoSites.length) % _shortVideoSites.length;
  }

  void setSiteIndex(int index) {
    if (index >= 0 && index < _shortVideoSites.length) {
      _currentIndex = index;
    }
  }
}
