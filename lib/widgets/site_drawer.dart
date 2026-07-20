import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/api_site.dart';
import '../providers/site_provider.dart';
import '../providers/video_provider.dart';
import '../screens/settings_screen.dart';

class SiteDrawer extends StatelessWidget {
  final String siteType;

  const SiteDrawer({
    super.key,
    this.siteType = 'video',
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Drawer(
      child: Consumer<SiteProvider>(
        builder: (context, siteProvider, child) {
          final visibleSites = siteProvider.sites
              .where((site) => site.type == siteType)
              .toList(growable: false);
          final isVideoTab = siteType == 'video';

          return Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 56, 20, 18),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      colorScheme.primaryContainer,
                      colorScheme.secondaryContainer,
                    ],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: colorScheme.surface,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color:
                                    colorScheme.shadow.withValues(alpha: 0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.video_library_rounded,
                            size: 36,
                            color: colorScheme.primary,
                          ),
                        ),
                        const Spacer(),
                        _HeaderActionButton(
                          tooltip: '加密导出',
                          icon: Icons.ios_share_rounded,
                          onPressed: () => _exportSites(context),
                        ),
                        _HeaderActionButton(
                          tooltip: '剪贴板导入',
                          icon: Icons.content_paste_go_rounded,
                          onPressed: () => _importSites(context),
                        ),
                        _HeaderActionButton(
                          tooltip: '订阅导入',
                          icon: Icons.link_rounded,
                          onPressed: () => _importSubscription(context),
                        ),
                        _HeaderActionButton(
                          tooltip: '清空当前类型',
                          icon: Icons.delete_sweep_rounded,
                          onPressed: visibleSites.isEmpty
                              ? null
                              : () => _clearSites(context, siteType),
                        ),
                        IconButton.filledTonal(
                          onPressed: () => _showSiteEditor(
                            context,
                            defaultType: siteType,
                          ),
                          tooltip: '新增站点',
                          icon: const Icon(Icons.add),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '${_siteTypeLabel(siteType)}站点',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '支持本地保存、加密导入导出和订阅导入',
                      style: TextStyle(
                        fontSize: 14,
                        color: colorScheme.onPrimaryContainer
                            .withValues(alpha: 0.75),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: visibleSites.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.language_rounded,
                              size: 56,
                              color: colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              '暂无${_siteTypeLabel(siteType)}站点',
                              style: TextStyle(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: visibleSites.length,
                        itemBuilder: (context, index) {
                          final site = visibleSites[index];
                          final isSelected =
                              isVideoTab && index == siteProvider.currentIndex;

                          return Container(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? colorScheme.primaryContainer
                                      .withValues(alpha: 0.5)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? colorScheme.primary.withValues(alpha: 0.3)
                                    : Colors.transparent,
                                width: 1.5,
                              ),
                            ),
                            child: ListTile(
                              leading: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? colorScheme.primary
                                      : colorScheme.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  isSelected
                                      ? Icons.check_circle_rounded
                                      : Icons.language_rounded,
                                  color: isSelected
                                      ? colorScheme.onPrimary
                                      : colorScheme.onSurfaceVariant,
                                  size: 20,
                                ),
                              ),
                              title: Text(
                                site.name,
                                style: TextStyle(
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.w500,
                                  fontSize: 15,
                                  color: isSelected
                                      ? colorScheme.primary
                                      : colorScheme.onSurface,
                                ),
                              ),
                              subtitle: Text(
                                site.baseUrl,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                              trailing: PopupMenuButton<_SiteAction>(
                                icon: const Icon(Icons.more_vert),
                                onSelected: (action) async {
                                  switch (action) {
                                    case _SiteAction.edit:
                                      await _showSiteEditor(
                                        context,
                                        site: site,
                                        visibleIndex: index,
                                        defaultType: siteType,
                                      );
                                      break;
                                    case _SiteAction.delete:
                                      await _deleteSite(
                                        context,
                                        siteType,
                                        index,
                                        site.name,
                                      );
                                      break;
                                  }
                                },
                                itemBuilder: (context) => const [
                                  PopupMenuItem(
                                    value: _SiteAction.edit,
                                    child: Text('编辑'),
                                  ),
                                  PopupMenuItem(
                                    value: _SiteAction.delete,
                                    child: Text('删除'),
                                  ),
                                ],
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              onTap: () async {
                                if (isVideoTab) {
                                  await siteProvider.setCurrentIndex(index);
                                  await _loadSelectedSite(
                                    context,
                                    site.baseUrl,
                                  );
                                }
                                if (context.mounted) {
                                  Navigator.pop(context);
                                }
                              },
                            ),
                          );
                        },
                      ),
              ),
              _SiteDrawerActions(
                visibleCount: visibleSites.length,
                totalCount: siteProvider.sites.length,
                siteType: siteType,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _HeaderActionButton extends StatelessWidget {
  final String tooltip;
  final IconData icon;
  final VoidCallback? onPressed;

  const _HeaderActionButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      visualDensity: VisualDensity.compact,
      tooltip: tooltip,
      onPressed: onPressed,
      icon: Icon(icon),
    );
  }
}

class _SiteDrawerActions extends StatelessWidget {
  final int visibleCount;
  final int totalCount;
  final String siteType;

  const _SiteDrawerActions({
    required this.visibleCount,
    required this.totalCount,
    required this.siteType,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        border: Border(
          top: BorderSide(
            color: colorScheme.outline.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                size: 16,
                color: colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '$visibleCount 个${_siteTypeLabel(siteType)}站点 / $totalCount 个总站点',
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: colorScheme.outline.withValues(alpha: 0.3),
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              leading: Icon(
                Icons.settings_rounded,
                color: colorScheme.primary,
              ),
              title: Text(
                '设置',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
              trailing: Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: colorScheme.onSurfaceVariant,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SettingsScreen(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

enum _SiteAction { edit, delete }

Future<void> _exportSites(BuildContext context) async {
  try {
    final provider = context.read<SiteProvider>();
    await provider.copyExportToClipboard();
    if (context.mounted) {
      _showMessage(context, '已加密复制 ${provider.sites.length} 个站点到剪贴板');
    }
  } catch (e) {
    if (context.mounted) {
      _showMessage(context, _formatError(e));
    }
  }
}

Future<void> _importSites(BuildContext context) async {
  final controller = TextEditingController();
  try {
    final clipboard = await Clipboard.getData(Clipboard.kTextPlain);
    controller.text = clipboard?.text?.trim() ?? '';
  } catch (_) {
    controller.text = '';
  }

  if (!context.mounted) {
    return;
  }

  final shareText = await showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('剪贴板导入'),
      content: TextField(
        controller: controller,
        minLines: 3,
        maxLines: 7,
        decoration: const InputDecoration(
          labelText: '加密站点文本',
          hintText: 'MINIPLAYER_SITE_SHARE_V1:...',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, controller.text.trim()),
          child: const Text('导入'),
        ),
      ],
    ),
  );

  if (shareText == null || shareText.isEmpty || !context.mounted) {
    return;
  }

  try {
    final provider = context.read<SiteProvider>();
    final message = await provider.importEncryptedShareText(shareText);
    final site = provider.currentSite;
    if (site != null && context.mounted) {
      await _loadSelectedSite(context, site.baseUrl);
    }
    if (context.mounted) {
      _showMessage(context, message);
    }
  } catch (e) {
    if (context.mounted) {
      _showMessage(context, _formatError(e));
    }
  }
}

Future<void> _importSubscription(BuildContext context) async {
  final controller = TextEditingController();
  final url = await showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('订阅导入'),
      content: TextField(
        controller: controller,
        decoration: const InputDecoration(
          labelText: '订阅链接',
          hintText: 'https://example.com/sites.txt',
        ),
        keyboardType: TextInputType.url,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, controller.text.trim()),
          child: const Text('导入'),
        ),
      ],
    ),
  );

  if (url == null || url.isEmpty || !context.mounted) {
    return;
  }

  try {
    final provider = context.read<SiteProvider>();
    final message = await provider.importSitesFromUrl(url);
    final site = provider.currentSite;
    if (site != null && context.mounted) {
      await _loadSelectedSite(context, site.baseUrl);
    }
    if (context.mounted) {
      _showMessage(context, message);
    }
  } catch (e) {
    if (context.mounted) {
      _showMessage(context, _formatError(e));
    }
  }
}

Future<void> _clearSites(BuildContext context, String siteType) async {
  final confirm = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('清空站点'),
      content: Text(
        '确定清空所有${_siteTypeLabel(siteType)}站点吗？清空后不会自动恢复默认站点。',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('清空'),
        ),
      ],
    ),
  );

  if (confirm != true || !context.mounted) {
    return;
  }

  await context.read<SiteProvider>().clearSites(type: siteType);
  if (context.mounted) {
    if (siteType == 'video') {
      context.read<VideoProvider>().clearVideos();
    }
    _showMessage(context, '已清空${_siteTypeLabel(siteType)}站点');
  }
}

Future<void> _loadSelectedSite(BuildContext context, String baseUrl) async {
  if (!context.mounted) {
    return;
  }

  final videoProvider = context.read<VideoProvider>();
  videoProvider.clearVideos();
  await videoProvider.loadVideoList(baseUrl);
}

Future<void> _deleteSite(
  BuildContext context,
  String siteType,
  int visibleIndex,
  String siteName,
) async {
  final confirm = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('删除站点'),
      content: Text('确定删除“$siteName”吗？'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('取消'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('删除'),
        ),
      ],
    ),
  );

  if (confirm != true || !context.mounted) {
    return;
  }

  await context.read<SiteProvider>().deleteSiteByType(siteType, visibleIndex);
  final site = context.read<SiteProvider>().currentSite;
  if (siteType == 'video' && site != null) {
    await _loadSelectedSite(context, site.baseUrl);
  } else if (siteType == 'video' && context.mounted) {
    context.read<VideoProvider>().clearVideos();
  }
}

Future<void> _showSiteEditor(
  BuildContext context, {
  ApiSite? site,
  int? visibleIndex,
  String defaultType = 'video',
}) async {
  final nameController = TextEditingController(text: site?.name ?? '');
  final baseUrlController = TextEditingController(text: site?.baseUrl ?? '');
  String selectedType = site?.type ?? defaultType;
  bool followRedirects = site?.followRedirects ?? false;

  final saved = await showDialog<ApiSite>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(site == null ? '新增站点' : '编辑站点'),
        content: StatefulBuilder(
          builder: (context, setState) {
            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: '名称'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: baseUrlController,
                    decoration: const InputDecoration(labelText: '地址'),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: selectedType,
                    decoration: const InputDecoration(labelText: '类型'),
                    items: const [
                      DropdownMenuItem(value: 'video', child: Text('视频')),
                      DropdownMenuItem(value: 'shortvideo', child: Text('短视频')),
                      DropdownMenuItem(value: 'image', child: Text('图片')),
                      DropdownMenuItem(value: 'music', child: Text('音乐')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => selectedType = value);
                      }
                    },
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('跟随重定向'),
                    value: followRedirects,
                    onChanged: (value) {
                      setState(() => followRedirects = value);
                    },
                  ),
                ],
              ),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              final name = nameController.text.trim();
              final baseUrl = baseUrlController.text.trim();
              if (name.isEmpty || baseUrl.isEmpty) {
                return;
              }

              Navigator.pop(
                context,
                ApiSite(
                  baseUrl: baseUrl,
                  name: name,
                  type: selectedType,
                  followRedirects: followRedirects ? true : null,
                ),
              );
            },
            child: const Text('保存'),
          ),
        ],
      );
    },
  );

  if (saved == null || !context.mounted) {
    return;
  }

  final provider = context.read<SiteProvider>();
  if (site == null) {
    await provider.addSite(saved);
  } else if (visibleIndex != null) {
    await provider.updateSiteByType(defaultType, visibleIndex, saved);
  }

  final currentSite = provider.currentSite;
  if (defaultType == 'video' && currentSite != null) {
    await _loadSelectedSite(context, currentSite.baseUrl);
  }
}

String _siteTypeLabel(String type) {
  return switch (type) {
    'shortvideo' => '短视频',
    'image' => '图片',
    'music' => '音乐',
    _ => '视频',
  };
}

void _showMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message)),
  );
}

String _formatError(Object error) {
  final text = error.toString();
  return text.startsWith('Bad state: ')
      ? text.substring('Bad state: '.length)
      : text;
}
