import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/download_provider.dart';

class DownloadScreen extends StatelessWidget {
  const DownloadScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('下载管理'),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          bottom: const TabBar(
            tabs: [
              Tab(text: '下载中'),
              Tab(text: '已完成'),
            ],
          ),
          actions: [
            Consumer<DownloadProvider>(
              builder: (context, provider, child) {
                if (provider.completedTasks.isEmpty) return const SizedBox.shrink();
                return IconButton(
                  icon: const Icon(Icons.delete_sweep),
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('清空已完成'),
                        content: const Text('确定要清空所有已完成的下载吗？'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('取消'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('确定'),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true && context.mounted) {
                      await context.read<DownloadProvider>().clearCompleted();
                    }
                  },
                );
              },
            ),
          ],
        ),
        body: TabBarView(
          children: [
            _buildDownloadingList(),
            _buildCompletedList(),
          ],
        ),
      ),
    );
  }

  Widget _buildDownloadingList() {
    return Consumer<DownloadProvider>(
      builder: (context, provider, child) {
        final downloadingTasks = provider.tasks
            .where((t) =>
                t.status == DownloadStatus.downloading ||
                t.status == DownloadStatus.pending ||
                t.status == DownloadStatus.paused ||
                t.status == DownloadStatus.failed)
            .toList();

        if (downloadingTasks.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.download_outlined, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('暂无下载任务'),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: downloadingTasks.length,
          itemBuilder: (context, index) {
            final task = downloadingTasks[index];
            return _buildTaskCard(context, task, showProgress: true);
          },
        );
      },
    );
  }

  Widget _buildCompletedList() {
    return Consumer<DownloadProvider>(
      builder: (context, provider, child) {
        final completedTasks = provider.completedTasks;

        if (completedTasks.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.download_done, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('暂无已完成的下载'),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: completedTasks.length,
          itemBuilder: (context, index) {
            final task = completedTasks[index];
            return _buildTaskCard(context, task, showProgress: false);
          },
        );
      },
    );
  }

  Widget _buildTaskCard(BuildContext context, DownloadTask task, {required bool showProgress}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.videoName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        task.episodeName,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                _buildStatusChip(task.status),
              ],
            ),

            // 进度条
            if (showProgress) ...[
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: task.progress,
                backgroundColor: Colors.grey[200],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    task.progressText,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  Text(
                    '${(task.progress * 100).toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],

            // 错误信息
            if (task.errorMessage != null) ...[
              const SizedBox(height: 8),
              Text(
                task.errorMessage!,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.red,
                ),
              ),
            ],

            // 操作按钮
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (task.status == DownloadStatus.downloading)
                  TextButton.icon(
                    onPressed: () {
                      context.read<DownloadProvider>().pauseTask(task.id);
                    },
                    icon: const Icon(Icons.pause, size: 18),
                    label: const Text('暂停'),
                  ),
                if (task.status == DownloadStatus.paused)
                  TextButton.icon(
                    onPressed: () {
                      context.read<DownloadProvider>().resumeTask(task.id);
                    },
                    icon: const Icon(Icons.play_arrow, size: 18),
                    label: const Text('继续'),
                  ),
                if (task.status == DownloadStatus.failed)
                  TextButton.icon(
                    onPressed: () {
                      context.read<DownloadProvider>().retryTask(task.id);
                    },
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('重试'),
                  ),
                if (task.status == DownloadStatus.completed)
                  TextButton.icon(
                    onPressed: () {
                      // TODO: 打开文件
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('文件位置: ${task.savePath}')),
                      );
                    },
                    icon: const Icon(Icons.play_circle, size: 18),
                    label: const Text('播放'),
                  ),
                TextButton.icon(
                  onPressed: () {
                    context.read<DownloadProvider>().cancelTask(task.id);
                  },
                  icon: const Icon(Icons.delete, size: 18),
                  label: const Text('删除'),
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(DownloadStatus status) {
    Color color;
    IconData icon;

    switch (status) {
      case DownloadStatus.pending:
        color = Colors.orange;
        icon = Icons.schedule;
        break;
      case DownloadStatus.downloading:
        color = Colors.blue;
        icon = Icons.downloading;
        break;
      case DownloadStatus.completed:
        color = Colors.green;
        icon = Icons.check_circle;
        break;
      case DownloadStatus.failed:
        color = Colors.red;
        icon = Icons.error;
        break;
      case DownloadStatus.paused:
        color = Colors.grey;
        icon = Icons.pause_circle;
        break;
    }

    return Chip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            _getStatusText(status),
            style: const TextStyle(
              fontSize: 12,
              color: Colors.white,
            ),
          ),
        ],
      ),
      backgroundColor: color,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
    );
  }

  String _getStatusText(DownloadStatus status) {
    switch (status) {
      case DownloadStatus.pending:
        return '等待中';
      case DownloadStatus.downloading:
        return '下载中';
      case DownloadStatus.completed:
        return '已完成';
      case DownloadStatus.failed:
        return '失败';
      case DownloadStatus.paused:
        return '已暂停';
    }
  }
}
