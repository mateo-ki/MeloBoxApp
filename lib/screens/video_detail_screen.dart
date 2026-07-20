import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/site_provider.dart';
import '../providers/video_provider.dart';
import '../providers/favorite_provider.dart';
import '../providers/play_history_provider.dart';
import '../models/video.dart';
import '../widgets/episode_selector.dart';
import '../utils/helpers.dart';
import 'video_player_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';

class VideoDetailScreen extends StatefulWidget {
  final String videoId;

  const VideoDetailScreen({
    super.key,
    required this.videoId,
  });

  @override
  State<VideoDetailScreen> createState() => _VideoDetailScreenState();
}

class _VideoDetailScreenState extends State<VideoDetailScreen> {
  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    final siteProvider = context.read<SiteProvider>();
    final videoProvider = context.read<VideoProvider>();

    if (siteProvider.currentSite != null) {
      await videoProvider.loadVideoDetail(
        siteProvider.currentSite!.baseUrl,
        widget.videoId,
      );
    }
  }

  void _playEpisode(Episode episode) {
    final videoProvider = context.read<VideoProvider>();
    final detail = videoProvider.currentVideoDetail;

    if (detail != null) {
      // 添加到播放历史
      context.read<PlayHistoryProvider>().addHistory(
        videoId: detail.id,
        videoName: detail.name,
        videoPic: detail.pic,
        episodeName: episode.name,
        episodeUrl: episode.url,
      );
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VideoPlayerScreen(
          videoUrl: episode.url,
          title: episode.name,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('视频详情'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          Consumer<VideoProvider>(
            builder: (context, videoProvider, child) {
              final detail = videoProvider.currentVideoDetail;
              if (detail == null) return const SizedBox.shrink();

              return Consumer<FavoriteProvider>(
                builder: (context, favoriteProvider, child) {
                  final isFavorite = favoriteProvider.isFavorite(detail.id);
                  return IconButton(
                    icon: Icon(
                      isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: isFavorite ? Colors.red : null,
                    ),
                    onPressed: () {
                      favoriteProvider.toggleFavorite(
                        videoId: detail.id,
                        videoName: detail.name,
                        videoPic: detail.pic,
                        videoType: detail.type,
                        videoNote: detail.note,
                      );

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(isFavorite ? '已取消收藏' : '已添加收藏'),
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
        ],
      ),
      body: Consumer<VideoProvider>(
        builder: (context, videoProvider, child) {
          if (videoProvider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (videoProvider.error.isNotEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(videoProvider.error),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadDetail,
                    child: const Text('重试'),
                  ),
                ],
              ),
            );
          }

          final detail = videoProvider.currentVideoDetail;
          if (detail == null) {
            return const Center(
              child: Text('暂无视频详情'),
            );
          }

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 视频封面
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: CachedNetworkImage(
                    imageUrl: detail.pic,
                    fit: BoxFit.cover,
                    httpHeaders: MediaUrlHelper.imageHeaders(detail.pic),
                    placeholder: (context, url) => Container(
                      color: Colors.grey[300],
                      child: const Center(
                        child: CircularProgressIndicator(),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: Colors.grey[300],
                      child: const Icon(Icons.error, size: 64),
                    ),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 标题
                      Text(
                        detail.name,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 8),

                      // 更新状态
                      if (detail.note.isNotEmpty)
                        Chip(
                          label: Text(detail.note),
                          backgroundColor: Colors.blue[100],
                        ),
                      const SizedBox(height: 16),

                      // 视频信息
                      _buildInfoRow('类型', detail.type),
                      if (detail.year != null) _buildInfoRow('年份', detail.year!),
                      if (detail.area != null) _buildInfoRow('地区', detail.area!),
                      if (detail.lang != null) _buildInfoRow('语言', detail.lang!),
                      if (detail.director != null)
                        _buildInfoRow('导演', detail.director!),
                      if (detail.actor != null) _buildInfoRow('演员', detail.actor!),

                      const SizedBox(height: 16),

                      // 简介
                      if (detail.des != null && detail.des!.isNotEmpty) ...[
                        Text(
                          '简介',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          detail.des!,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 24),
                      ],

                      // 播放列表
                      if (detail.playUrls.isNotEmpty) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '选集播放',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            TextButton.icon(
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('下载功能开发中...'),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.download, size: 18),
                              label: const Text('下载'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        ...detail.playUrls.map((playUrl) => EpisodeSelector(
                              playUrl: playUrl,
                              onEpisodeSelected: _playEpisode,
                            )),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 60,
            child: Text(
              '$label:',
              style: TextStyle(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
