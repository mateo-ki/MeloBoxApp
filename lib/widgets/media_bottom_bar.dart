import 'package:flutter/material.dart';

import '../screens/home_screen.dart';
import '../screens/image_viewer_screen.dart';
import '../screens/music_screen.dart';
import '../screens/short_video_screen.dart';

enum MediaTab {
  video,
  shortVideo,
  image,
  music,
}

class MediaBottomBar extends StatelessWidget {
  final MediaTab currentTab;

  const MediaBottomBar({
    super.key,
    required this.currentTab,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: NavigationBar(
        selectedIndex: currentTab.index,
        onDestinationSelected: (index) => _openTab(context, MediaTab.values[index]),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.video_library_outlined),
            selectedIcon: Icon(Icons.video_library),
            label: '视频',
          ),
          NavigationDestination(
            icon: Icon(Icons.smart_display_outlined),
            selectedIcon: Icon(Icons.smart_display),
            label: '短视频',
          ),
          NavigationDestination(
            icon: Icon(Icons.photo_library_outlined),
            selectedIcon: Icon(Icons.photo_library),
            label: '图片',
          ),
          NavigationDestination(
            icon: Icon(Icons.library_music_outlined),
            selectedIcon: Icon(Icons.library_music),
            label: '音乐',
          ),
        ],
      ),
    );
  }

  void _openTab(BuildContext context, MediaTab tab) {
    if (tab == currentTab) {
      return;
    }

    final Widget page = switch (tab) {
      MediaTab.video => const HomeScreen(),
      MediaTab.shortVideo => const ShortVideoScreen(),
      MediaTab.image => const ImageViewerScreen(),
      MediaTab.music => const MusicScreen(),
    };

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => page),
      (route) => false,
    );
  }
}
