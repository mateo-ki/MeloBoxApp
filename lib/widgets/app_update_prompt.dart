import 'package:flutter/material.dart';

import '../models/app_update.dart';
import '../services/update_service.dart';

Future<void> showAppUpdatePrompt(
  BuildContext context,
  AppUpdate update, {
  UpdateService? service,
}) async {
  final updateService = service ?? UpdateService();
  final shouldUpdate = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(update.title),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('发现新版本 ${update.version}'),
            if (update.notes.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(update.notes),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('稍后'),
        ),
        FilledButton.icon(
          onPressed: () => Navigator.pop(context, true),
          icon: const Icon(Icons.system_update_alt),
          label: const Text('下载更新'),
        ),
      ],
    ),
  );
  if (shouldUpdate != true || !context.mounted) {
    return;
  }

  final progress = ValueNotifier<double?>(null);
  var progressDialogOpen = true;
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      title: const Text('正在下载更新'),
      content: ValueListenableBuilder<double?>(
        valueListenable: progress,
        builder: (context, value, child) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            LinearProgressIndicator(value: value),
            const SizedBox(height: 12),
            Text(value == null ? '准备下载...' : '${(value * 100).round()}%'),
          ],
        ),
      ),
    ),
  );

  try {
    final apk = await updateService.downloadApk(
      update,
      onReceiveProgress: (received, total) {
        progress.value = total > 0 ? received / total : null;
      },
    );
    if (context.mounted) {
      Navigator.of(context, rootNavigator: true).pop();
      progressDialogOpen = false;
    }
    await updateService.installApk(apk);
  } catch (error) {
    if (context.mounted) {
      if (progressDialogOpen) {
        Navigator.of(context, rootNavigator: true).pop();
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('更新失败：$error')),
      );
    }
  } finally {
    progress.dispose();
  }
}

class AppUpdateChecker extends StatefulWidget {
  const AppUpdateChecker({required this.child, super.key});

  final Widget child;

  @override
  State<AppUpdateChecker> createState() => _AppUpdateCheckerState();
}

class _AppUpdateCheckerState extends State<AppUpdateChecker> {
  final UpdateService _service = UpdateService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _check());
  }

  Future<void> _check() async {
    try {
      final update = await _service.checkForUpdate();
      if (update != null && mounted) {
        await showAppUpdatePrompt(context, update, service: _service);
      }
    } catch (_) {
      // 启动检查保持静默，避免网络波动影响应用进入首页。
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
