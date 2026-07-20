import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/site_provider.dart';
import '../providers/video_provider.dart';
import '../providers/search_history_provider.dart';
import '../widgets/video_grid.dart';
import '../widgets/site_drawer.dart';
import '../widgets/category_filter.dart';
import '../widgets/media_bottom_bar.dart';
import 'favorites_screen.dart';
import 'download_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initialize();
    });
  }

  Future<void> _initialize() async {
    if (_initialized) {
      return;
    }

    final siteProvider = context.read<SiteProvider>();
    final searchHistoryProvider = context.read<SearchHistoryProvider>();

    await siteProvider.loadSites();
    await searchHistoryProvider.loadHistory();
    _initialized = true;

    if (siteProvider.currentSite != null) {
      final videoProvider = context.read<VideoProvider>();
      await videoProvider.loadVideoList(siteProvider.currentSite!.baseUrl);
    }
  }

  void _performSearch() {
    final keyword = _searchController.text.trim();
    final siteProvider = context.read<SiteProvider>();
    final videoProvider = context.read<VideoProvider>();
    final searchHistoryProvider = context.read<SearchHistoryProvider>();

    if (siteProvider.currentSite == null) {
      return;
    }

    if (keyword.isEmpty) {
      videoProvider.loadVideoList(siteProvider.currentSite!.baseUrl);
      return;
    }

    searchHistoryProvider.addSearch(keyword);
    videoProvider.searchVideos(siteProvider.currentSite!.baseUrl, keyword);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 2,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [colorScheme.primary, colorScheme.secondary],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.video_library,
                color: colorScheme.onPrimary,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'MeloBox',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh videos',
            onPressed: () {
              final siteProvider = context.read<SiteProvider>();
              final videoProvider = context.read<VideoProvider>();
              final site = siteProvider.currentSite;
              if (site != null) {
                videoProvider.loadVideoList(site.baseUrl);
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.favorite_border),
            tooltip: 'Favorites',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const FavoritesScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.download_outlined),
            tooltip: 'Downloads',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const DownloadScreen()),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      drawer: const SiteDrawer(),
      bottomNavigationBar: const MediaBottomBar(currentTab: MediaTab.video),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Container(
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: colorScheme.outline.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search videos...',
                  hintStyle: TextStyle(color: colorScheme.onSurfaceVariant),
                  prefixIcon: Icon(Icons.search, color: colorScheme.primary),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(
                            Icons.clear,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          onPressed: () {
                            setState(() {
                              _searchController.clear();
                            });
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
                onSubmitted: (_) => _performSearch(),
                onChanged: (value) => setState(() {}),
              ),
            ),
          ),
          const CategoryFilter(),
          const Expanded(child: VideoGrid()),
        ],
      ),
    );
  }
}
