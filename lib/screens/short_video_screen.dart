import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:media_kit/media_kit.dart' as mk;
import 'package:media_kit_video/media_kit_video.dart';
import 'package:provider/provider.dart';

import '../models/api_site.dart';
import '../providers/site_provider.dart';
import '../widgets/media_bottom_bar.dart';
import '../widgets/site_drawer.dart';

class ShortVideoScreen extends StatefulWidget {
  const ShortVideoScreen({super.key});

  @override
  State<ShortVideoScreen> createState() => _ShortVideoScreenState();
}

class _ShortVideoScreenState extends State<ShortVideoScreen> {
  final PageController _pageController = PageController();
  _ShortVideoItem? _currentVideoItem;
  List<ApiSite> _shortVideoSites = [];
  int _currentPage = 0;
  int _siteOffset = 0;
  int _loadGeneration = 0;
  int? _queuedVideoIndex;
  double _volume = 1.0;
  bool _isSwitchingVideo = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadShortVideoSites();
    });
  }

  @override
  void dispose() {
    _disposeAllVideos();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadShortVideoSites() async {
    final siteProvider = context.read<SiteProvider>();
    if (siteProvider.sites.isEmpty) {
      await siteProvider.loadSites();
    }
    _shortVideoSites = siteProvider.shortVideoSites;
    if (_shortVideoSites.isNotEmpty) {
      _siteOffset =
          DateTime.now().millisecondsSinceEpoch % _shortVideoSites.length;
      _createCurrentVideo(0);
    }
    if (mounted) {
      setState(() {});
    }
  }

  void _disposeAllVideos() {
    _currentVideoItem?.dispose();
    _currentVideoItem = null;
  }

  void _reloadVideo(int index) {
    _queueCurrentVideoReplacement(index);
  }

  void _setVolume(double volume) {
    setState(() {
      _volume = volume;
    });
    _currentVideoItem?.setVolume(volume);
  }

  @override
  Widget build(BuildContext context) {
    if (_shortVideoSites.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.black,
        drawer: const SiteDrawer(siteType: 'shortvideo'),
        bottomNavigationBar:
            const MediaBottomBar(currentTab: MediaTab.shortVideo),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: const Center(
          child: Text(
            '暂无短视频源',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      drawer: const SiteDrawer(siteType: 'shortvideo'),
      bottomNavigationBar:
          const MediaBottomBar(currentTab: MediaTab.shortVideo),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('短视频'),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          _buildVideoLayer(),
          NotificationListener<ScrollStartNotification>(
            onNotification: (notification) {
              if (notification.metrics.axis == Axis.vertical) {
                _currentVideoItem?.pause();
              }
              return false;
            },
            child: PageView.builder(
              controller: _pageController,
              scrollDirection: Axis.vertical,
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
                _queueCurrentVideoReplacement(index);
              },
              itemBuilder: (context, index) => _buildOverlayPage(index),
            ),
          ),
          _buildErrorOverlay(),
        ],
      ),
    );
  }

  Widget _buildVideoLayer() {
    final videoItem = _currentVideoItem;

    if (videoItem == null) {
      return const ColoredBox(
        color: Colors.black,
        child: Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    return _ShortVideoPlayer(
      key: ValueKey(videoItem),
      videoItem: videoItem,
    );
  }

  Widget _buildErrorOverlay() {
    final videoItem = _currentVideoItem;
    if (videoItem == null || videoItem.error == null) {
      return const SizedBox.shrink();
    }

    return ColoredBox(
      color: Colors.black.withValues(alpha: 0.72),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                videoItem.error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: () => _reloadVideo(_currentPage),
                icon: const Icon(Icons.refresh),
                label: const Text('重新加载'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOverlayPage(int index) {
    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _toggleCurrentVideoPlayback,
          ),
        ),
        Positioned(
          right: 12,
          bottom: 100,
          child: Column(
            children: [
              _VolumeButton(
                volume: _volume,
                onChanged: _setVolume,
              ),
              const SizedBox(height: 20),
              _ActionButton(
                icon: Icons.refresh_rounded,
                label: '重载',
                onTap: () => _reloadVideo(index),
              ),
              const SizedBox(height: 20),
              _ActionButton(
                icon: Icons.skip_next_rounded,
                label: '下一个',
                onTap: () => _goToPage(index + 1),
              ),
            ],
          ),
        ),
        Positioned(
          bottom: 20,
          left: 12,
          right: 80,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _shortVideoSites[_siteIndexForPage(index)].name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.swipe_vertical, color: Colors.white70, size: 16),
                    SizedBox(width: 8),
                    Text(
                      '上滑切换下一个视频',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _toggleCurrentVideoPlayback() {
    final videoItem = _currentVideoItem;
    if (videoItem == null || videoItem.error != null) {
      return;
    }

    if (videoItem.isPlaying) {
      videoItem.pause();
    } else {
      videoItem.play();
    }
  }

  void _createCurrentVideo(int index) {
    final oldItem = _currentVideoItem;
    _currentVideoItem = _ShortVideoItem(
      siteIndex: _siteIndexForPage(index),
      sites: _shortVideoSites,
      volume: _volume,
    );
    oldItem?.release();
    if (mounted) {
      setState(() {});
    }
  }

  void _queueCurrentVideoReplacement(int index) {
    _queuedVideoIndex = index;
    if (_isSwitchingVideo) {
      return;
    }

    unawaited(_drainVideoReplacementQueue());
  }

  Future<void> _drainVideoReplacementQueue() async {
    if (_isSwitchingVideo) {
      return;
    }

    _isSwitchingVideo = true;

    try {
      while (mounted && _queuedVideoIndex != null) {
        final index = _queuedVideoIndex!;
        _queuedVideoIndex = null;
        final generation = ++_loadGeneration;
        final oldItem = _currentVideoItem;
        _currentVideoItem = null;

        if (mounted) {
          setState(() {});
        }

        await _waitForVideoSurfaceTeardown();
        await oldItem?.release();
        await _waitForVideoSurfaceTeardown();

        if (!mounted ||
            generation != _loadGeneration ||
            index != _currentPage) {
          continue;
        }

        _currentVideoItem = _ShortVideoItem(
          siteIndex: _siteIndexForPage(index),
          sites: _shortVideoSites,
          volume: _volume,
        );

        if (mounted) {
          setState(() {});
        }
      }
    } finally {
      _isSwitchingVideo = false;
      if (mounted && _queuedVideoIndex != null) {
        unawaited(_drainVideoReplacementQueue());
      }
    }
  }

  Future<void> _waitForVideoSurfaceTeardown() async {
    await WidgetsBinding.instance.endOfFrame;
    await Future<void>.delayed(const Duration(milliseconds: 260));
  }

  int _siteIndexForPage(int index) {
    return (_siteOffset + index) % _shortVideoSites.length;
  }

  void _goToPage(int index) {
    if (index < 0 || index == _currentPage) {
      _currentVideoItem?.play();
      return;
    }

    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOut,
    );
  }
}

class _ShortVideoItem extends ChangeNotifier {
  static const int _initialMaxAttempts = 6;

  static const Map<String, String> _headers = {
    'User-Agent': 'Mozilla/5.0 (Linux; Android 10) AppleWebKit/537.36',
    'Accept': '*/*',
  };

  final int siteIndex;
  final List<ApiSite> sites;
  final mk.Player player = mk.Player();
  late final VideoController videoController = VideoController(
    player,
    configuration: _videoControllerConfiguration,
  );
  final List<StreamSubscription<dynamic>> _subscriptions = [];
  bool isLoading = true;
  bool isPlaying = false;
  String? error;
  double volume;
  bool _disposed = false;
  bool _handlingFailure = false;
  int _attemptOffset = 0;
  int _attemptToken = 0;

  _ShortVideoItem({
    required this.siteIndex,
    required this.sites,
    required this.volume,
  }) {
    _subscriptions.addAll([
      player.stream.playing.listen((playing) {
        if (_disposed) {
          return;
        }
        isPlaying = playing;
        notifyListeners();
      }),
      player.stream.buffering.listen((buffering) {
        if (_disposed) {
          return;
        }
        isLoading = buffering;
        notifyListeners();
      }),
      player.stream.error.listen((message) {
        if (message.isNotEmpty) {
          _handlePlaybackFailure(message, _attemptToken);
        }
      }),
    ]);
    _initialize();
  }

  Future<void> _initialize() async {
    isLoading = true;
    error = null;
    notifyListeners();

    _attemptOffset = 0;
    await _tryCurrentAttempt();
  }

  int get _maxAttempts =>
      sites.length < _initialMaxAttempts ? sites.length : _initialMaxAttempts;

  Future<void> _tryCurrentAttempt() async {
    if (_disposed) {
      return;
    }

    final candidateIndex = (siteIndex + _attemptOffset) % sites.length;
    final token = ++_attemptToken;

    try {
      await _openSite(candidateIndex, token);
    } catch (e) {
      await _handlePlaybackFailure(e.toString(), token);
    }
  }

  Future<void> _openSite(int index, int token) async {
    await player.stop();

    isLoading = true;
    error = null;
    notifyListeners();

    final site = sites[index];
    final sourceUri = _withCacheBuster(site.baseUrl);
    final mediaUri = await _resolveRedirectUri(sourceUri);
    if (_disposed || token != _attemptToken) {
      return;
    }

    await player.setVolume(volume * 100);
    await player
        .open(
          mk.Media(
            mediaUri.toString(),
            httpHeaders: {
              ..._headers,
              'Referer': sourceUri.origin,
            },
          ),
          play: true,
        )
        .timeout(const Duration(seconds: 12));

    if (_disposed || token != _attemptToken) {
      return;
    }

    await videoController.waitUntilFirstFrameRendered.timeout(
      const Duration(seconds: 8),
      onTimeout: () {},
    );

    if (_disposed || token != _attemptToken) {
      return;
    }

    isLoading = false;
    error = null;
    notifyListeners();
  }

  Uri _withCacheBuster(String url) {
    final separator = url.contains('?')
        ? (url.endsWith('?') || url.endsWith('&') ? '' : '&')
        : '?';
    return Uri.parse(
      '$url${separator}t=${DateTime.now().millisecondsSinceEpoch}',
    );
  }

  Future<Uri> _resolveRedirectUri(Uri uri) async {
    var current = uri;

    for (var redirectCount = 0; redirectCount < 4; redirectCount++) {
      final next = await _readRedirectLocation(current);
      if (next == null) {
        return current;
      }
      current = next;
    }

    return current;
  }

  Future<Uri?> _readRedirectLocation(Uri uri) async {
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 5)
      ..userAgent = _headers['User-Agent'];

    try {
      final request = await client.getUrl(uri).timeout(
            const Duration(seconds: 5),
          );
      request.followRedirects = false;
      _headers.forEach(request.headers.set);
      request.headers.set(HttpHeaders.refererHeader, uri.origin);

      final response = await request.close().timeout(
            const Duration(seconds: 5),
          );
      final location = response.headers.value(HttpHeaders.locationHeader);
      await response.drain<void>();

      if (response.isRedirect && location != null && location.isNotEmpty) {
        return uri.resolve(location);
      }

      return null;
    } finally {
      client.close(force: true);
    }
  }

  Future<void> _handlePlaybackFailure(String reason, int token) async {
    if (_disposed || token != _attemptToken || _handlingFailure) {
      return;
    }

    _handlingFailure = true;
    debugPrint('Short video attempt failed: $reason');
    await player.stop();

    if (_attemptOffset + 1 < _maxAttempts) {
      _attemptOffset++;
      _handlingFailure = false;
      await _tryCurrentAttempt();
      return;
    }

    error = '视频加载失败，请重试或切换来源。';
    isLoading = false;
    _handlingFailure = false;
    notifyListeners();
  }

  void play() {
    unawaited(player.play());
    notifyListeners();
  }

  void pause() {
    unawaited(player.pause());
    notifyListeners();
  }

  void setVolume(double value) {
    volume = value;
    unawaited(player.setVolume(value * 100));
    notifyListeners();
  }

  @override
  void dispose() {
    unawaited(release());
    super.dispose();
  }

  Future<void> release() async {
    if (_disposed) {
      return;
    }
    _disposed = true;

    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    await player.stop();
    await player.dispose();
  }
}

VideoControllerConfiguration get _videoControllerConfiguration {
  if (!Platform.isAndroid) {
    return const VideoControllerConfiguration();
  }

  return const VideoControllerConfiguration(
    enableHardwareAcceleration: false,
    hwdec: 'no',
    androidAttachSurfaceAfterVideoParameters: true,
  );
}

class _ShortVideoPlayer extends StatelessWidget {
  final _ShortVideoItem videoItem;

  const _ShortVideoPlayer({
    super.key,
    required this.videoItem,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: videoItem,
      builder: (context, child) {
        if (videoItem.error != null) {
          return const ColoredBox(color: Colors.black);
        }

        return Stack(
          fit: StackFit.expand,
          children: [
            Video(
              controller: videoItem.videoController,
              fit: BoxFit.cover,
              fill: Colors.black,
              controls: null,
            ),
            if (videoItem.isLoading)
              const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            if (!videoItem.isPlaying)
              const Center(
                child: Icon(
                  Icons.play_circle_outline,
                  size: 80,
                  color: Colors.white,
                ),
              ),
          ],
        );
      },
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.5),
          shape: BoxShape.circle,
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 32),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VolumeButton extends StatelessWidget {
  final double volume;
  final ValueChanged<double> onChanged;

  const _VolumeButton({
    required this.volume,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showVolumeSheet(context),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.5),
          shape: BoxShape.circle,
        ),
        child: Column(
          children: [
            Icon(
              volume == 0 ? Icons.volume_off : Icons.volume_up,
              color: Colors.white,
              size: 32,
            ),
            const SizedBox(height: 4),
            Text(
              '${(volume * 100).round()}%',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showVolumeSheet(BuildContext context) {
    var currentVolume = volume;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.grey.shade900,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                child: Row(
                  children: [
                    Icon(
                      currentVolume == 0 ? Icons.volume_off : Icons.volume_up,
                      color: Colors.white,
                    ),
                    Expanded(
                      child: Slider(
                        value: currentVolume,
                        min: 0,
                        max: 1,
                        divisions: 20,
                        label: '${(currentVolume * 100).round()}%',
                        onChanged: (value) {
                          setSheetState(() {
                            currentVolume = value;
                          });
                          onChanged(value);
                        },
                      ),
                    ),
                    SizedBox(
                      width: 48,
                      child: Text(
                        '${(currentVolume * 100).round()}%',
                        textAlign: TextAlign.right,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
