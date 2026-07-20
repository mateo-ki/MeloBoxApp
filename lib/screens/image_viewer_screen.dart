import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/api_site.dart';
import '../providers/site_provider.dart';
import '../widgets/media_bottom_bar.dart';
import '../widgets/redirect_image_widget.dart';
import '../widgets/site_drawer.dart';

class ImageViewerScreen extends StatefulWidget {
  const ImageViewerScreen({super.key});

  @override
  State<ImageViewerScreen> createState() => _ImageViewerScreenState();
}

class _ImageViewerScreenState extends State<ImageViewerScreen> {
  String? _currentImageUrl;
  bool _isLoading = false;
  bool _autoRefresh = false;
  Timer? _autoRefreshTimer;
  int _refreshInterval = 3;
  int _currentSiteIndex = 0;
  List<ApiSite> _imageSites = [];

  @override
  void initState() {
    super.initState();
    _loadImageSites();
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    super.dispose();
  }

  void _loadImageSites() {
    final siteProvider = context.read<SiteProvider>();
    _imageSites =
        siteProvider.sites.where((site) => site.type == 'image').toList();
    if (_imageSites.isNotEmpty) {
      _loadImage();
    }
  }

  Future<void> _loadImage() async {
    if (_imageSites.isEmpty) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final site = _imageSites[_currentSiteIndex];
      final separator = site.baseUrl.contains('?') ? '&' : '?';
      final url =
          '${site.baseUrl}${separator}t=${DateTime.now().millisecondsSinceEpoch}';

      setState(() {
        _currentImageUrl = url;
        _isLoading = false;
      });
    } catch (_) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _nextSite() {
    if (_imageSites.isEmpty) {
      return;
    }

    setState(() {
      _currentSiteIndex = (_currentSiteIndex + 1) % _imageSites.length;
    });
    _loadImage();
  }

  void _toggleAutoRefresh() {
    setState(() {
      _autoRefresh = !_autoRefresh;
    });

    if (_autoRefresh) {
      _startAutoRefresh();
    } else {
      _stopAutoRefresh();
    }
  }

  void _startAutoRefresh() {
    _autoRefreshTimer = Timer.periodic(
      Duration(seconds: _refreshInterval),
      (_) => _loadImage(),
    );
  }

  void _stopAutoRefresh() {
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = null;
  }

  RedirectMode _redirectModeForSite(ApiSite site) {
    final followRedirects = site.followRedirects;
    if (followRedirects == true) {
      return RedirectMode.always;
    }
    if (followRedirects == false) {
      return RedirectMode.never;
    }
    return RedirectMode.auto;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const SiteDrawer(siteType: 'image'),
      appBar: AppBar(
        title: const Text('随机图片'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          PopupMenuButton<int>(
            initialValue: _refreshInterval,
            onSelected: (value) {
              setState(() {
                _refreshInterval = value;
              });
              if (_autoRefresh) {
                _stopAutoRefresh();
                _startAutoRefresh();
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 1, child: Text('1秒刷新')),
              PopupMenuItem(value: 3, child: Text('3秒刷新')),
              PopupMenuItem(value: 5, child: Text('5秒刷新')),
            ],
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const Icon(Icons.timer),
                  const SizedBox(width: 4),
                  Text('${_refreshInterval}s'),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const MediaBottomBar(currentTab: MediaTab.image),
      body: Column(
        children: [
          if (_imageSites.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Text(
                '当前: ${_imageSites[_currentSiteIndex].name}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ),
          Expanded(
            child: _currentImageUrl == null
                ? const Center(child: Text('点击刷新加载图片'))
                : _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : InteractiveViewer(
                        child: Center(
                          child: RedirectImageWidget(
                            imageUrl: _currentImageUrl!,
                            fit: BoxFit.contain,
                            redirectMode: _redirectModeForSite(
                              _imageSites[_currentSiteIndex],
                            ),
                            placeholder: (context, url) => const Center(
                              child: CircularProgressIndicator(),
                            ),
                            errorWidget: (context, url, error) => const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.error,
                                      size: 64, color: Colors.red),
                                  SizedBox(height: 16),
                                  Text('图片加载失败'),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: FilledButton.tonalIcon(
                      onPressed: _loadImage,
                      icon: const Icon(Icons.refresh),
                      label: const Text('同源'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton.tonalIcon(
                      onPressed: _nextSite,
                      icon: const Icon(Icons.skip_next),
                      label: const Text('换源'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _toggleAutoRefresh,
                      icon: Icon(_autoRefresh ? Icons.pause : Icons.play_arrow),
                      label: Text(_autoRefresh ? '停止' : '自动'),
                      style: FilledButton.styleFrom(
                        backgroundColor: _autoRefresh ? Colors.orange : null,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
