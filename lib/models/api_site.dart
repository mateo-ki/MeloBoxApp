class ApiSite {
  final String baseUrl;
  final String name;
  final String type;
  final bool? followRedirects;

  ApiSite({
    required this.baseUrl,
    required this.name,
    required this.type,
    this.followRedirects,
  });

  factory ApiSite.fromJson(Map<String, dynamic> json) {
    return ApiSite(
      baseUrl: json['baseUrl'] as String,
      name: json['name'] as String,
      type: json['type'] as String,
      followRedirects: json['followRedirects'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'baseUrl': baseUrl,
      'name': name,
      'type': type,
      if (followRedirects != null) 'followRedirects': followRedirects,
    };
  }

  ApiSite copyWith({
    String? baseUrl,
    String? name,
    String? type,
    bool? followRedirects,
  }) {
    return ApiSite(
      baseUrl: baseUrl ?? this.baseUrl,
      name: name ?? this.name,
      type: type ?? this.type,
      followRedirects: followRedirects ?? this.followRedirects,
    );
  }
}

class ApiSitesConfig {
  final int currentIndex;
  final List<ApiSite> sites;

  ApiSitesConfig({
    required this.currentIndex,
    required this.sites,
  });

  factory ApiSitesConfig.fromJson(Map<String, dynamic> json) {
    return ApiSitesConfig(
      currentIndex: json['currentIndex'] as int,
      sites: (json['sites'] as List)
          .map((site) => ApiSite.fromJson(site as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'currentIndex': currentIndex,
      'sites': sites.map((site) => site.toJson()).toList(),
    };
  }
}
