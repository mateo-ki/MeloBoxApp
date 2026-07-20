class AppConstants {
  // API 配置
  static const int apiTimeout = 10;
  static const int maxRetries = 3;

  // 分页配置
  static const int pageSize = 20;
  static const int gridColumns = 2;

  // 缓存配置
  static const int imageCacheMaxAge = 7; // 天
  static const int dataCacheMaxAge = 1; // 天

  // 播放器配置
  static const double defaultVolume = 0.8;
  static const bool autoPlay = true;

  // UI 配置
  static const double cardAspectRatio = 0.7;
  static const double gridSpacing = 16.0;

  // 存储键
  static const String keyCurrentSiteIndex = 'currentSiteIndex';
  static const String keySearchHistory = 'searchHistory';
  static const String keyPlayHistory = 'playHistory';
  static const String keyFavorites = 'favorites';
  static const String keyThemeMode = 'themeMode';
}

class AppStrings {
  // 应用名称
  static const String appName = 'MeloBox';

  // 通用
  static const String ok = '确定';
  static const String cancel = '取消';
  static const String retry = '重试';
  static const String loading = '加载中...';
  static const String noData = '暂无数据';
  static const String error = '错误';

  // 主页
  static const String search = '搜索';
  static const String searchHint = '搜索视频...';
  static const String videoSites = '视频站点';
  static const String currentSite = '当前站点';
  static const String noVideos = '暂无视频';
  static const String searchOrRefresh = '搜索或刷新查看视频';

  // 详情
  static const String videoDetail = '视频详情';
  static const String episodes = '选集播放';
  static const String description = '简介';
  static const String type = '类型';
  static const String year = '年份';
  static const String area = '地区';
  static const String language = '语言';
  static const String director = '导演';
  static const String actor = '演员';

  // 错误信息
  static const String networkError = '网络连接失败';
  static const String parseError = '数据解析失败';
  static const String videoNotFound = '未找到视频';
  static const String siteError = '站点加载失败';
}
