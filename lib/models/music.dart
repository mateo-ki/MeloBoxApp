class MusicTrack {
  final String title;
  final String artist;
  final String url;
  final String picUrl;
  final String lrcUrl;

  const MusicTrack({
    required this.title,
    required this.artist,
    required this.url,
    required this.picUrl,
    required this.lrcUrl,
  });

  factory MusicTrack.fromApiJson(Map<String, dynamic> json) {
    return MusicTrack(
      title: _readString(json, const ['title', 'name'], fallback: '未知歌曲'),
      artist: _readString(
        json,
        const ['author', 'artist', 'singer'],
        fallback: '未知歌手',
      ),
      url: _readString(json, const ['url']),
      picUrl: _readString(json, const ['pic', 'cover']),
      lrcUrl: _readString(json, const ['lrc', 'lyric']),
    );
  }

  static String _readString(
    Map<String, dynamic> json,
    List<String> keys, {
    String fallback = '',
  }) {
    for (final key in keys) {
      final value = json[key];
      if (value == null) {
        continue;
      }
      final text = value.toString().trim();
      if (text.isNotEmpty) {
        return text;
      }
    }
    return fallback;
  }
}

class MusicLyricLine {
  final int timeMs;
  final String text;

  const MusicLyricLine({
    required this.timeMs,
    required this.text,
  });
}

List<MusicLyricLine> parseLrcLines(String lrc) {
  final timeTag = RegExp(r'\[(\d{1,2}):(\d{2})(?:[.:](\d{1,3}))?\]');
  final lines = <MusicLyricLine>[];

  for (final rawLine in lrc.split(RegExp(r'\r?\n'))) {
    final matches = timeTag.allMatches(rawLine).toList(growable: false);
    if (matches.isEmpty) {
      continue;
    }

    final text = rawLine.replaceAll(timeTag, '').trim();
    if (text.isEmpty) {
      continue;
    }

    for (final match in matches) {
      final minutes = int.tryParse(match.group(1) ?? '') ?? 0;
      final seconds = int.tryParse(match.group(2) ?? '') ?? 0;
      final fraction = match.group(3) ?? '0';
      final normalizedFraction = fraction.length == 1
          ? int.parse(fraction) * 100
          : fraction.length == 2
              ? int.parse(fraction) * 10
              : int.parse(fraction.padRight(3, '0').substring(0, 3));

      lines.add(
        MusicLyricLine(
          timeMs: minutes * 60000 + seconds * 1000 + normalizedFraction,
          text: text,
        ),
      );
    }
  }

  lines.sort((a, b) => a.timeMs.compareTo(b.timeMs));
  return lines;
}

int activeLyricIndex(List<MusicLyricLine> lines, Duration position) {
  var activeIndex = -1;
  final positionMs = position.inMilliseconds;

  for (var index = 0; index < lines.length; index++) {
    if (lines[index].timeMs <= positionMs) {
      activeIndex = index;
    } else {
      break;
    }
  }

  return activeIndex;
}
