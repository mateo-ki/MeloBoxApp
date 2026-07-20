import 'package:flutter/material.dart';
import '../models/video.dart';

class EpisodeSelector extends StatelessWidget {
  final PlayUrl playUrl;
  final Function(Episode) onEpisodeSelected;

  const EpisodeSelector({
    super.key,
    required this.playUrl,
    required this.onEpisodeSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 播放源标题
            Row(
              children: [
                const Icon(Icons.play_circle_outline, size: 20),
                const SizedBox(width: 8),
                Text(
                  playUrl.flag,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // 集数按钮
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: playUrl.episodes.map((episode) {
                return ElevatedButton(
                  onPressed: () => onEpisodeSelected(episode),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(80, 40),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  child: Text(
                    episode.name,
                    style: const TextStyle(fontSize: 13),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
