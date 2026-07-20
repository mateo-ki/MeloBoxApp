class Video {
  final String id;
  final String name;
  final String pic;
  final String note;
  final String type;
  final String? actor;
  final String? director;
  final String? des;
  final String? year;
  final String? area;
  final String? lang;

  Video({
    required this.id,
    required this.name,
    required this.pic,
    required this.note,
    required this.type,
    this.actor,
    this.director,
    this.des,
    this.year,
    this.area,
    this.lang,
  });

  factory Video.fromXml(dynamic videoElement) {
    return Video(
      id: _xmlText(videoElement, const ['id', 'vod_id']),
      name: _xmlText(videoElement, const ['name', 'vod_name']),
      pic: _xmlText(videoElement, const ['pic', 'vod_pic']),
      note: _xmlText(videoElement, const ['note', 'remarks', 'vod_remarks']),
      type: _xmlText(videoElement, const ['type', 'type_name']),
      actor: _xmlTextOrNull(videoElement, const ['actor', 'vod_actor']),
      director: _xmlTextOrNull(videoElement, const ['director', 'vod_director']),
      des: _xmlTextOrNull(videoElement, const ['des', 'content', 'vod_content', 'vod_blurb']),
      year: _xmlTextOrNull(videoElement, const ['year', 'vod_year']),
      area: _xmlTextOrNull(videoElement, const ['area', 'vod_area']),
      lang: _xmlTextOrNull(videoElement, const ['lang', 'vod_lang']),
    );
  }

  factory Video.fromJson(Map<String, dynamic> json) {
    return Video(
      id: _jsonText(json, const ['vod_id', 'id']),
      name: _jsonText(json, const ['vod_name', 'name']),
      pic: _jsonText(json, const ['vod_pic', 'pic']),
      note: _jsonText(json, const ['vod_remarks', 'remarks', 'note']),
      type: _jsonText(json, const ['type_name', 'type']),
      actor: _jsonTextOrNull(json, const ['vod_actor', 'actor']),
      director: _jsonTextOrNull(json, const ['vod_director', 'director']),
      des: _jsonTextOrNull(json, const ['vod_content', 'vod_blurb', 'content', 'des']),
      year: _jsonTextOrNull(json, const ['vod_year', 'year']),
      area: _jsonTextOrNull(json, const ['vod_area', 'area']),
      lang: _jsonTextOrNull(json, const ['vod_lang', 'lang']),
    );
  }

  Video copyWith({
    String? id,
    String? name,
    String? pic,
    String? note,
    String? type,
    String? actor,
    String? director,
    String? des,
    String? year,
    String? area,
    String? lang,
  }) {
    return Video(
      id: id ?? this.id,
      name: name ?? this.name,
      pic: pic ?? this.pic,
      note: note ?? this.note,
      type: type ?? this.type,
      actor: actor ?? this.actor,
      director: director ?? this.director,
      des: des ?? this.des,
      year: year ?? this.year,
      area: area ?? this.area,
      lang: lang ?? this.lang,
    );
  }

  static String _xmlText(dynamic element, List<String> names) {
    for (final name in names) {
      final values = element.findElements(name);
      if (values.isNotEmpty) {
        return values.first.text.trim();
      }
    }
    return '';
  }

  static String? _xmlTextOrNull(dynamic element, List<String> names) {
    final value = _xmlText(element, names);
    return value.isEmpty ? null : value;
  }

  static String _jsonText(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key]?.toString().trim();
      if (value != null && value.isNotEmpty) {
        return value;
      }
    }
    return '';
  }

  static String? _jsonTextOrNull(Map<String, dynamic> json, List<String> keys) {
    final value = _jsonText(json, keys);
    return value.isEmpty ? null : value;
  }
}

class VideoDetail extends Video {
  final List<PlayUrl> playUrls;

  VideoDetail({
    required super.id,
    required super.name,
    required super.pic,
    required super.note,
    required super.type,
    super.actor,
    super.director,
    super.des,
    super.year,
    super.area,
    super.lang,
    required this.playUrls,
  });

  factory VideoDetail.fromXml(dynamic videoElement) {
    final video = Video.fromXml(videoElement);
    final playUrls = <PlayUrl>[];
    final ddElements = videoElement.findElements('dd');

    for (final dd in ddElements) {
      final flag = dd.getAttribute('flag') ?? '默认';
      final urlText = dd.text;

      if (urlText.isNotEmpty) {
        final episodes = _parseEpisodes(urlText);
        if (episodes.isNotEmpty) {
          playUrls.add(PlayUrl(flag: flag, episodes: episodes));
        }
      }
    }

    return VideoDetail(
      id: video.id,
      name: video.name,
      pic: video.pic,
      note: video.note,
      type: video.type,
      actor: video.actor,
      director: video.director,
      des: video.des,
      year: video.year,
      area: video.area,
      lang: video.lang,
      playUrls: _normalizePlayUrls(playUrls),
    );
  }

  factory VideoDetail.fromJson(Map<String, dynamic> json) {
    final video = Video.fromJson(json);
    final playUrls = <PlayUrl>[];

    final playFrom = json['vod_play_from']?.toString() ?? '';
    final playUrl = json['vod_play_url']?.toString() ?? '';

    if (playFrom.isNotEmpty && playUrl.isNotEmpty) {
      final flags = playFrom.split('\$\$\$');
      final urls = playUrl.split('\$\$\$');

      for (int i = 0; i < flags.length && i < urls.length; i++) {
        final flag = flags[i].trim();
        final urlText = urls[i].trim();

        if (urlText.isNotEmpty) {
          final episodes = _parseEpisodes(urlText);
          if (episodes.isNotEmpty) {
            playUrls.add(
              PlayUrl(
                flag: flag.isEmpty ? '默认' : flag,
                episodes: episodes,
              ),
            );
          }
        }
      }
    }

    return VideoDetail(
      id: video.id,
      name: video.name,
      pic: video.pic,
      note: video.note,
      type: video.type,
      actor: video.actor,
      director: video.director,
      des: video.des,
      year: video.year,
      area: video.area,
      lang: video.lang,
      playUrls: _normalizePlayUrls(playUrls),
    );
  }

  static List<Episode> _parseEpisodes(String urlText) {
    final episodes = <Episode>[];
    final seen = <String>{};

    for (final rawEpisode in urlText.split('#')) {
      final episodeText = rawEpisode.trim();
      if (episodeText.isEmpty) {
        continue;
      }

      final parts = episodeText.split('\$');
      final name = parts.isNotEmpty ? parts[0].trim() : '播放';
      final url = parts.length > 1 ? parts[1].trim() : parts[0].trim();

      if (url.isEmpty) {
        continue;
      }

      final key = '${name.toLowerCase()}|$url';
      if (seen.add(key)) {
        episodes.add(Episode(
          name: name.isEmpty ? '播放' : name,
          url: url,
        ));
      }
    }

    return episodes;
  }

  static List<PlayUrl> _normalizePlayUrls(List<PlayUrl> playUrls) {
    final mergedByFlag = <String, List<Episode>>{};
    final flagOrder = <String>[];

    for (final playUrl in playUrls) {
      final normalizedFlag = playUrl.flag.trim().isEmpty ? '默认' : playUrl.flag.trim();
      final bucket = mergedByFlag.putIfAbsent(normalizedFlag, () {
        flagOrder.add(normalizedFlag);
        return <Episode>[];
      });

      for (final episode in playUrl.episodes) {
        final index = bucket.indexWhere(
          (item) => _episodeNameKey(item.name) == _episodeNameKey(episode.name),
        );

        if (index == -1) {
          bucket.add(episode);
          continue;
        }

        if (_scoreEpisodeUrl(episode.url) > _scoreEpisodeUrl(bucket[index].url)) {
          bucket[index] = episode;
        }
      }
    }

    final candidates = flagOrder
        .map((flag) => PlayUrl(flag: flag, episodes: mergedByFlag[flag] ?? const <Episode>[]))
        .where((playUrl) => playUrl.episodes.isNotEmpty)
        .toList();

    final deduplicated = <PlayUrl>[];

    for (final candidate in candidates) {
      final candidateSignature = _episodeGroupSignature(candidate.episodes);
      final existingIndex = deduplicated.indexWhere(
        (playUrl) => _episodeGroupSignature(playUrl.episodes) == candidateSignature,
      );

      if (existingIndex == -1) {
        deduplicated.add(candidate);
        continue;
      }

      if (_playUrlScore(candidate) > _playUrlScore(deduplicated[existingIndex])) {
        deduplicated[existingIndex] = candidate;
      }
    }

    return deduplicated;
  }

  static String _episodeNameKey(String name) {
    return name.trim().toLowerCase();
  }

  static int _scoreEpisodeUrl(String url) {
    final normalized = url.trim().toLowerCase();

    if (normalized.contains('.m3u8')) {
      return 4;
    }
    if (normalized.contains('.mp4') ||
        normalized.contains('.flv') ||
        normalized.contains('.mkv')) {
      return 3;
    }
    if (normalized.contains('/share/') || normalized.contains('share/')) {
      return 1;
    }
    return 2;
  }

  static String _episodeGroupSignature(List<Episode> episodes) {
    final names = episodes
        .map((episode) => _episodeNameKey(episode.name))
        .toList()
      ..sort();
    return names.join('#');
  }

  static int _playUrlScore(PlayUrl playUrl) {
    return playUrl.episodes.fold<int>(
      0,
      (score, episode) => score + _scoreEpisodeUrl(episode.url),
    );
  }
}

class PlayUrl {
  final String flag;
  final List<Episode> episodes;

  PlayUrl({
    required this.flag,
    required this.episodes,
  });
}

class Episode {
  final String name;
  final String url;

  Episode({
    required this.name,
    required this.url,
  });
}
