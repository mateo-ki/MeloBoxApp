import 'package:chewie/chewie.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:video_player/video_player.dart';

class VideoPlayerScreen extends StatefulWidget {
  final String videoUrl;
  final String title;

  const VideoPlayerScreen({
    super.key,
    required this.videoUrl,
    required this.title,
  });

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  static const Map<String, String> _headers = {
    'User-Agent': 'Mozilla/5.0 (Linux; Android 10) AppleWebKit/537.36',
    'Accept': '*/*',
  };

  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;
  bool _isLoading = true;
  String? _error;
  late String _currentUrl;
  double _volume = 1.0;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    _currentUrl = widget.videoUrl;
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    await _disposeControllers();

    if (mounted) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    try {
      if (_currentUrl.trim().isEmpty) {
        throw Exception('Video URL is empty');
      }

      final resolvedUrl = await _resolveFinalUrl(_currentUrl);
      final videoUri = Uri.parse(resolvedUrl);

      _videoPlayerController = VideoPlayerController.networkUrl(
        videoUri,
        httpHeaders: {
          ..._headers,
          'Referer': videoUri.origin,
        },
        viewType: _preferredViewType(),
      );

      _videoPlayerController!.addListener(_handleControllerUpdate);

      await _videoPlayerController!.initialize().timeout(
        const Duration(seconds: 20),
      );
      await _videoPlayerController!.setVolume(_volume);

      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController!,
        autoPlay: true,
        looping: false,
        allowFullScreen: true,
        allowMuting: true,
        showControls: true,
        playbackSpeeds: const [0.5, 0.75, 1.0, 1.25, 1.5, 2.0],
        materialProgressColors: ChewieProgressColors(
          playedColor: Theme.of(context).colorScheme.primary,
          handleColor: Theme.of(context).colorScheme.primary,
          backgroundColor: Colors.grey,
          bufferedColor: Colors.grey.shade300,
        ),
        placeholder: Container(
          color: Colors.black,
          child: const Center(
            child: CircularProgressIndicator(),
          ),
        ),
        errorBuilder: (context, errorMessage) {
          return _PlayerError(
            message: errorMessage,
            onRetry: _initializePlayer,
          );
        },
      );

      if (mounted) {
        setState(() {
          _currentUrl = resolvedUrl;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Player initialization failed: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = _parseError(e.toString());
        });
      }
    }
  }

  Future<String> _resolveFinalUrl(String url) async {
    http.Client? client;
    try {
      client = http.Client();
      final request = http.Request('HEAD', Uri.parse(url));
      request.followRedirects = true;
      request.headers.addAll({
        ..._headers,
        'Connection': 'keep-alive',
      });

      final streamedResponse = await client.send(request).timeout(
        const Duration(seconds: 6),
      );
      final finalUrl = streamedResponse.request?.url.toString() ?? url;
      await streamedResponse.stream.drain();
      return finalUrl;
    } catch (e) {
      debugPrint('Video redirect resolve failed: $e');
      return url;
    } finally {
      client?.close();
    }
  }

  VideoViewType _preferredViewType() {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return VideoViewType.textureView;
    }
    return VideoViewType.textureView;
  }

  void _handleControllerUpdate() {
    if (!mounted || _videoPlayerController == null) {
      return;
    }

    final value = _videoPlayerController!.value;
    if (value.hasError) {
      setState(() {
        _error = 'Playback error: ${value.errorDescription ?? 'unknown error'}';
        _isLoading = false;
      });
    }
  }

  String _parseError(String error) {
    if (error.contains('timeout')) {
      return 'Loading timed out. Please retry or switch source.';
    }
    if (error.contains('Source error')) {
      return 'The video source could not be played. Please retry or switch source.';
    }
    if (error.contains('empty')) {
      return 'The video link is empty.';
    }
    return 'Playback failed. Please retry or switch source.\n\n$error';
  }

  Future<void> _setVolume(double volume) async {
    setState(() {
      _volume = volume;
    });
    await _videoPlayerController?.setVolume(volume);
  }

  Future<void> _disposeControllers() async {
    _videoPlayerController?.removeListener(_handleControllerUpdate);
    _chewieController?.dispose();
    await _videoPlayerController?.dispose();
    _chewieController = null;
    _videoPlayerController = null;
  }

  @override
  void dispose() {
    _disposeControllers();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.title,
          style: const TextStyle(fontSize: 16),
        ),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (!_isLoading && _error == null)
            IconButton(
              tooltip: 'Volume',
              onPressed: _showVolumeSheet,
              icon: Icon(
                _volume == 0 ? Icons.volume_off : Icons.volume_up,
              ),
            ),
        ],
      ),
      backgroundColor: Colors.black,
      body: Center(
        child: _isLoading
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    color: colorScheme.primary,
                    strokeWidth: 3,
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Loading video...',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              )
            : _error != null
                ? _PlayerError(
                    message: _error!,
                    onRetry: _initializePlayer,
                  )
                : _chewieController != null &&
                        _videoPlayerController?.value.isInitialized == true
                    ? AspectRatio(
                        aspectRatio: _videoPlayerController!
                                    .value.aspectRatio >
                                0
                            ? _videoPlayerController!.value.aspectRatio
                            : 16 / 9,
                        child: Chewie(controller: _chewieController!),
                      )
                    : const Text(
                        'Player is unavailable',
                        style: TextStyle(color: Colors.white),
                      ),
      ),
    );
  }

  void _showVolumeSheet() {
    var currentVolume = _volume;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.grey.shade900,
      builder: (context) {
        final colorScheme = Theme.of(context).colorScheme;

        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                child: Row(
                  children: [
                    Icon(
                      currentVolume == 0
                          ? Icons.volume_off
                          : Icons.volume_up,
                      color: Colors.white,
                    ),
                    Expanded(
                      child: Slider(
                        value: currentVolume,
                        min: 0,
                        max: 1,
                        divisions: 20,
                        activeColor: colorScheme.primary,
                        inactiveColor: Colors.white24,
                        label: '${(currentVolume * 100).round()}%',
                        onChanged: (value) {
                          setSheetState(() {
                            currentVolume = value;
                          });
                          _setVolume(value);
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

class _PlayerError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _PlayerError({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.error,
          width: 2,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.play_circle_outline,
            size: 80,
            color: colorScheme.error,
          ),
          const SizedBox(height: 24),
          Text(
            message,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Back'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey.shade800,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
