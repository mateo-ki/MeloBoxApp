import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/music.dart';
import '../providers/music_provider.dart';
import '../widgets/media_bottom_bar.dart';
import '../widgets/site_drawer.dart';

class MusicScreen extends StatefulWidget {
  const MusicScreen({super.key});

  @override
  State<MusicScreen> createState() => _MusicScreenState();
}

class _MusicScreenState extends State<MusicScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('音乐')),
      drawer: const SiteDrawer(siteType: 'music'),
      bottomNavigationBar: const MediaBottomBar(currentTab: MediaTab.music),
      body: Consumer<MusicProvider>(
        builder: (context, musicProvider, _) {
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        textInputAction: TextInputAction.search,
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.search),
                          hintText: '搜索歌曲、歌手或关键字',
                        ),
                        onSubmitted: (_) => _search(musicProvider),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      onPressed: musicProvider.isLoading
                          ? null
                          : () => _search(musicProvider),
                      icon: const Icon(Icons.search),
                    ),
                  ],
                ),
              ),
              if (musicProvider.message.isNotEmpty || musicProvider.isLoading)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Row(
                    children: [
                      if (musicProvider.isLoading)
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      else
                        Icon(
                          Icons.info_outline,
                          size: 16,
                          color: colorScheme.primary,
                        ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          musicProvider.isLoading
                              ? '正在处理音乐请求...'
                              : musicProvider.message,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: musicProvider.results.isEmpty
                    ? _EmptyMusicState(onSearchPreset: (keyword) {
                        _searchController.text = keyword;
                        _search(musicProvider);
                      })
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                        itemCount: musicProvider.results.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final track = musicProvider.results[index];
                          final isCurrent =
                              musicProvider.currentTrack?.url == track.url;
                          return _MusicResultTile(
                            track: track,
                            isCurrent: isCurrent,
                            onPlay: () => musicProvider.playTrack(track),
                          );
                        },
                      ),
              ),
              _NowPlayingPanel(musicProvider: musicProvider),
            ],
          );
        },
      ),
    );
  }

  void _search(MusicProvider musicProvider) {
    FocusScope.of(context).unfocus();
    musicProvider.searchMusic(_searchController.text);
  }
}

class _MusicResultTile extends StatelessWidget {
  final MusicTrack track;
  final bool isCurrent;
  final VoidCallback onPlay;

  const _MusicResultTile({
    required this.track,
    required this.isCurrent,
    required this.onPlay,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: isCurrent
          ? colorScheme.primaryContainer
          : colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
      borderRadius: BorderRadius.circular(12),
      child: ListTile(
        leading: _CoverImage(url: track.picUrl, size: 48),
        title: Text(
          track.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          track.artist,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: IconButton.filledTonal(
          onPressed: onPlay,
          icon: const Icon(Icons.play_arrow),
        ),
        onTap: onPlay,
      ),
    );
  }
}

class _NowPlayingPanel extends StatelessWidget {
  final MusicProvider musicProvider;

  const _NowPlayingPanel({required this.musicProvider});

  @override
  Widget build(BuildContext context) {
    final track = musicProvider.currentTrack;
    final colorScheme = Theme.of(context).colorScheme;
    final maxDurationMs = musicProvider.duration.inMilliseconds <= 0
        ? 1.0
        : musicProvider.duration.inMilliseconds.toDouble();
    final positionMs = musicProvider.position.inMilliseconds
        .clamp(0, maxDurationMs.toInt())
        .toDouble();

    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          border: Border(top: BorderSide(color: colorScheme.outlineVariant)),
        ),
        padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                _CoverImage(url: track?.picUrl ?? '', size: 44),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        track?.title ?? '未播放音乐',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        track?.artist ?? '选择一首歌开始播放',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                IconButton.filled(
                  visualDensity: VisualDensity.compact,
                  onPressed: track == null
                      ? null
                      : () => musicProvider.togglePlayPause(),
                  icon: Icon(
                    musicProvider.isPlaying ? Icons.pause : Icons.play_arrow,
                  ),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  onPressed: track == null ? null : () => musicProvider.stop(),
                  icon: const Icon(Icons.stop),
                ),
              ],
            ),
            Row(
              children: [
                SizedBox(
                  width: 42,
                  child: Text(
                    _formatDuration(musicProvider.position),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                Expanded(
                  child: Slider(
                    value: positionMs,
                    min: 0,
                    max: maxDurationMs,
                    onChanged: track == null
                        ? null
                        : (value) => musicProvider.seek(
                              Duration(milliseconds: value.round()),
                            ),
                  ),
                ),
                SizedBox(
                  width: 42,
                  child: Text(
                    _formatDuration(musicProvider.duration),
                    textAlign: TextAlign.right,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  onPressed: () => _showVolumeSheet(context),
                  icon: Icon(
                    musicProvider.volume == 0
                        ? Icons.volume_off
                        : Icons.volume_up,
                    size: 20,
                  ),
                ),
              ],
            ),
            _LyricPreview(provider: musicProvider),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  void _showVolumeSheet(BuildContext context) {
    var currentVolume = musicProvider.volume;

    showModalBottomSheet<void>(
      context: context,
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
                          musicProvider.setVolume(value);
                        },
                      ),
                    ),
                    SizedBox(
                      width: 48,
                      child: Text(
                        '${(currentVolume * 100).round()}%',
                        textAlign: TextAlign.right,
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

class _LyricPreview extends StatelessWidget {
  final MusicProvider provider;

  const _LyricPreview({required this.provider});

  @override
  Widget build(BuildContext context) {
    if (provider.currentTrack == null) {
      return const SizedBox.shrink();
    }

    final index = provider.currentLyricIndex;
    final text = index >= 0 && index < provider.lyricLines.length
        ? provider.lyricLines[index].text
        : provider.lyricLines.isEmpty
            ? '暂无歌词'
            : provider.lyricLines.first.text;

    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.w700,
          ),
    );
  }
}

class _CoverImage extends StatelessWidget {
  final String url;
  final double size;

  const _CoverImage({
    required this.url,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: size,
        height: size,
        color: colorScheme.surfaceContainerHighest,
        child: url.isEmpty
            ? Icon(Icons.music_note, color: colorScheme.primary)
            : CachedNetworkImage(
                imageUrl: url,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => Icon(
                  Icons.music_note,
                  color: colorScheme.primary,
                ),
                placeholder: (_, __) => const Center(
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ),
      ),
    );
  }
}

class _EmptyMusicState extends StatelessWidget {
  final ValueChanged<String> onSearchPreset;

  const _EmptyMusicState({required this.onSearchPreset});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.library_music_outlined,
              size: 72,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              '搜索音乐开始播放',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              '支持歌曲名、歌手和关键字。',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: [
                ActionChip(
                  label: const Text('周杰伦'),
                  onPressed: () => onSearchPreset('周杰伦'),
                ),
                ActionChip(
                  label: const Text('林俊杰'),
                  onPressed: () => onSearchPreset('林俊杰'),
                ),
                ActionChip(
                  label: const Text('邓紫棋'),
                  onPressed: () => onSearchPreset('邓紫棋'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
