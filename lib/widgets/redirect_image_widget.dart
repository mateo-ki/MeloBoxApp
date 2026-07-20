import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

enum RedirectMode {
  auto,
  always,
  never,
}

class RedirectImageWidget extends StatefulWidget {
  final String imageUrl;
  final BoxFit fit;
  final double? width;
  final double? height;
  final RedirectMode redirectMode;
  final Widget Function(BuildContext, String)? placeholder;
  final Widget Function(BuildContext, String, dynamic)? errorWidget;

  const RedirectImageWidget({
    super.key,
    required this.imageUrl,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.redirectMode = RedirectMode.auto,
    this.placeholder,
    this.errorWidget,
  });

  @override
  State<RedirectImageWidget> createState() => _RedirectImageWidgetState();
}

class _RedirectImageWidgetState extends State<RedirectImageWidget> {
  static const Map<String, String> _headers = {
    'User-Agent': 'Mozilla/5.0 (Linux; Android 10) AppleWebKit/537.36',
    'Accept': 'image/avif,image/webp,image/apng,image/*,*/*;q=0.8',
  };

  String? _resolvedUrl;
  bool _isResolving = false;
  bool _triedRedirectFallback = false;
  Object? _lastError;

  @override
  void initState() {
    super.initState();
    _prepareUrl();
  }

  @override
  void didUpdateWidget(covariant RedirectImageWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl ||
        oldWidget.redirectMode != widget.redirectMode) {
      _triedRedirectFallback = false;
      _lastError = null;
      _prepareUrl();
    }
  }

  Future<void> _prepareUrl() async {
    if (widget.redirectMode == RedirectMode.never) {
      if (!mounted) {
        return;
      }
      setState(() {
        _resolvedUrl = widget.imageUrl;
        _isResolving = false;
      });
      return;
    }

    if (widget.redirectMode == RedirectMode.auto) {
      if (!mounted) {
        return;
      }
      setState(() {
        _resolvedUrl = widget.imageUrl;
        _isResolving = false;
      });
      return;
    }

    await _resolveRedirectTarget();
  }

  Future<void> _resolveRedirectTarget() async {
    if (!mounted) {
      return;
    }

    setState(() {
      _isResolving = true;
      _lastError = null;
    });

    final resolved = await _followRedirects(widget.imageUrl);

    if (!mounted) {
      return;
    }

    setState(() {
      _resolvedUrl = resolved ?? widget.imageUrl;
      _isResolving = false;
    });
  }

  Future<String?> _followRedirects(String url) async {
    http.Client? client;
    try {
      client = http.Client();
      final request = http.Request('GET', Uri.parse(url));
      request.headers.addAll({
        ..._headers,
        'Connection': 'keep-alive',
      });

      final response = await client.send(request).timeout(
        const Duration(seconds: 8),
      );
      final finalUrl = response.request?.url.toString();
      await response.stream.drain();
      return finalUrl;
    } catch (e) {
      debugPrint('图片重定向解析失败: $e');
      return null;
    } finally {
      client?.close();
    }
  }

  Future<void> _handleImageError(dynamic error) async {
    if (widget.redirectMode != RedirectMode.auto || _triedRedirectFallback) {
      if (!mounted) {
        return;
      }
      setState(() {
        _lastError = error;
      });
      return;
    }

    _triedRedirectFallback = true;

    if (!mounted) {
      return;
    }

    setState(() {
      _isResolving = true;
      _lastError = null;
    });

    final redirectedUrl = await _followRedirects(widget.imageUrl);

    if (!mounted) {
      return;
    }

    setState(() {
      _resolvedUrl = redirectedUrl ?? widget.imageUrl;
      _isResolving = false;
      _lastError = redirectedUrl == null ? error : null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isResolving || _resolvedUrl == null) {
      return widget.placeholder?.call(context, widget.imageUrl) ??
          Container(
            width: widget.width,
            height: widget.height,
            color: Colors.grey[300],
            child: const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
    }

    if (_lastError != null) {
      return widget.errorWidget?.call(context, _resolvedUrl!, _lastError) ??
          Container(
            width: widget.width,
            height: widget.height,
            color: Colors.grey[300],
            child: const Icon(Icons.error),
          );
    }

    return CachedNetworkImage(
      imageUrl: _resolvedUrl!,
      fit: widget.fit,
      width: widget.width,
      height: widget.height,
      httpHeaders: _headers,
      placeholder: widget.placeholder,
      errorWidget: (context, url, error) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _handleImageError(error);
        });

        return widget.placeholder?.call(context, url) ??
            Container(
              width: widget.width,
              height: widget.height,
              color: Colors.grey[300],
              child: const Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            );
      },
      fadeInDuration: const Duration(milliseconds: 300),
      fadeOutDuration: const Duration(milliseconds: 100),
    );
  }
}
