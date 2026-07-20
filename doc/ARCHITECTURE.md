# MeloBox App - 项目架构

## 📐 整体架构

```
┌─────────────────────────────────────────────────────────┐
│                     Presentation Layer                   │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐              │
│  │ Screens  │  │ Widgets  │  │  Theme   │              │
│  └────┬─────┘  └────┬─────┘  └────┬─────┘              │
└───────┼─────────────┼─────────────┼─────────────────────┘
        │             │             │
┌───────▼─────────────▼─────────────▼─────────────────────┐
│                   Business Logic Layer                   │
│  ┌──────────────────────────────────────────────────┐   │
│  │              Providers (State Management)         │   │
│  │  ┌──────────┐  ┌──────────┐  ┌──────────┐       │   │
│  │  │  Site    │  │  Video   │  │ History  │       │   │
│  │  └──────────┘  └──────────┘  └──────────┘       │   │
│  └──────────────────────────────────────────────────┘   │
└───────┼─────────────────────────────────────────────────┘
        │
┌───────▼─────────────────────────────────────────────────┐
│                     Data Layer                           │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐              │
│  │  Models  │  │ Network  │  │  Local   │              │
│  │          │  │  (HTTP)  │  │ Storage  │              │
│  └──────────┘  └──────────┘  └──────────┘              │
└─────────────────────────────────────────────────────────┘
```

---

## 📂 目录结构详解

```
lib/
├── main.dart                          # 应用入口
│
├── models/                            # 数据模型层
│   ├── api_site.dart                 # 站点模型
│   │   ├── ApiSite                   # 单个站点
│   │   └── ApiSitesConfig            # 站点配置
│   └── video.dart                    # 视频模型
│       ├── Video                     # 视频信息
│       ├── VideoDetail               # 视频详情
│       ├── PlayUrl                   # 播放源
│       └── Episode                   # 剧集
│
├── providers/                         # 状态管理层
│   ├── site_provider.dart            # 站点管理
│   │   ├── 加载站点列表
│   │   ├── 切换当前站点
│   │   └── 站点索引持久化
│   ├── video_provider.dart           # 视频数据管理
│   │   ├── 搜索视频
│   │   ├── 加载列表
│   │   ├── 获取详情
│   │   └── 错误处理
│   ├── search_history_provider.dart  # 搜索历史
│   │   ├── 保存搜索记录
│   │   ├── 加载历史
│   │   └── 清空历史
│   ├── play_history_provider.dart    # 播放历史
│   │   ├── 记录播放
│   │   ├── 查询历史
│   │   └── 管理记录
│   └── favorite_provider.dart        # 收藏管理
│       ├── 添加收藏
│       ├── 移除收藏
│       └── 判断状态
│
├── screens/                           # 页面层
│   ├── home_screen.dart              # 主页
│   │   ├── 搜索栏
│   │   ├── 站点显示
│   │   └── 视频网格
│   ├── video_detail_screen.dart      # 视频详情页
│   │   ├── 封面展示
│   │   ├── 详细信息
│   │   └── 选集列表
│   ├── video_player_screen.dart      # 播放器页
│   │   └── Chewie 播放器
│   ├── favorites_screen.dart         # 收藏&历史页
│   │   ├── FavoritesScreen
│   │   └── HistoryScreen
│   ├── image_viewer_screen.dart      # 图片浏览页
│   │   ├── 图片显示
│   │   ├── 刷新控制
│   │   └── 自动刷新
│   ├── short_video_screen.dart       # 短视频页
│   │   ├── 视频播放
│   │   └── 切换控制
│   ├── settings_screen.dart          # 设置页
│   │   └── 数据管理
│   └── about_screen.dart             # 关于页
│       └── 应用信息
│
├── widgets/                           # 组件层
│   ├── video_grid.dart               # 视频网格
│   │   ├── 网格布局
│   │   ├── 视频卡片
│   │   └── 加载/错误状态
│   ├── site_drawer.dart              # 站点抽屉
│   │   ├── 站点列表
│   │   ├── 切换功能
│   │   └── 设置入口
│   ├── episode_selector.dart         # 选集选择器
│   │   ├── 播放源标签
│   │   └── 集数按钮
│   ├── common_widgets.dart           # 通用组件
│   │   ├── LoadingWidget
│   │   ├── EmptyWidget
│   │   ├── ErrorWidget
│   │   └── SearchHistoryChip
│   └── search_bar.dart               # 搜索栏
│       ├── 输入框
│       └── 历史下拉
│
└── utils/                             # 工具层
    ├── constants.dart                # 常量配置
    │   ├── AppConstants
    │   └── AppStrings
    ├── theme.dart                    # 主题配置
    │   ├── AppColors
    │   └── AppTheme
    ├── network_helper.dart           # 网络工具
    │   ├── 重试机制
    │   └── 异常处理
    └── helpers.dart                  # 辅助函数
        ├── DateTimeHelper
        ├── StringHelper
        └── ValidationHelper
```

---

## 🔄 数据流

### 视频搜索流程

```
User Input (搜索关键词)
    ↓
HomeScreen
    ↓
VideoProvider.searchVideos()
    ↓
HTTP Request → API Server
    ↓
XML Response
    ↓
Parse to Video Models
    ↓
Update State (notifyListeners)
    ↓
UI Update (VideoGrid)
    ↓
Display Results
```

### 收藏流程

```
User Action (点击收藏)
    ↓
VideoDetailScreen
    ↓
FavoriteProvider.toggleFavorite()
    ↓
Update Memory List
    ↓
SharedPreferences.setString()
    ↓
Save to Local Storage
    ↓
notifyListeners()
    ↓
UI Update (图标变化)
```

### 站点切换流程

```
User Action (选择站点)
    ↓
SiteDrawer
    ↓
SiteProvider.setCurrentIndex()
    ↓
Update Current Site
    ↓
Save to SharedPreferences
    ↓
VideoProvider.clearVideos()
    ↓
VideoProvider.loadVideoList()
    ↓
Load New Site Data
    ↓
notifyListeners()
    ↓
UI Update (显示新站点视频)
```

---

## 🧩 模块依赖关系

```
main.dart
  ├─→ Providers (注入)
  │    ├─→ SiteProvider
  │    ├─→ VideoProvider
  │    ├─→ SearchHistoryProvider
  │    ├─→ PlayHistoryProvider
  │    └─→ FavoriteProvider
  │
  └─→ HomeScreen
       ├─→ VideoGrid
       │    └─→ VideoDetailScreen
       │         └─→ VideoPlayerScreen
       ├─→ SiteDrawer
       │    └─→ SettingsScreen
       │         └─→ AboutScreen
       ├─→ FavoritesScreen
       ├─→ HistoryScreen
       ├─→ ImageViewerScreen
       └─→ ShortVideoScreen
```

---

## 📊 状态管理

### Provider 架构

```
┌──────────────────────────────────────┐
│         ChangeNotifier               │
│                                      │
│  ┌────────────────────────────────┐ │
│  │     State Variables            │ │
│  │  • _sites                      │ │
│  │  • _currentIndex               │ │
│  │  • _isLoading                  │ │
│  └────────────────────────────────┘ │
│                                      │
│  ┌────────────────────────────────┐ │
│  │     Public Methods             │ │
│  │  • loadSites()                 │ │
│  │  • setCurrentIndex()           │ │
│  │  • getter methods              │ │
│  └────────────────────────────────┘ │
│                                      │
│  ┌────────────────────────────────┐ │
│  │     notifyListeners()          │ │
│  │     ↓                          │ │
│  │  Consumer Widgets Rebuild      │ │
│  └────────────────────────────────┘ │
└──────────────────────────────────────┘
```

---

## 🎨 UI 组件层次

```
MaterialApp
  └─→ MultiProvider
       └─→ HomeScreen (Scaffold)
            ├─→ AppBar
            │    ├─→ Leading (Menu)
            │    ├─→ Title
            │    └─→ Actions (Icons)
            │
            ├─→ Drawer (SiteDrawer)
            │    ├─→ DrawerHeader
            │    ├─→ ListView (Sites)
            │    └─→ Settings Entry
            │
            └─→ Body
                 ├─→ SearchBar
                 ├─→ Site Info
                 └─→ VideoGrid
                      └─→ GridView
                           └─→ VideoCard (x N)
```

---

## 🔌 网络层

### API 请求流程

```
Provider
  ↓
http.get(url)
  ↓
try-catch
  ├─→ Success (200)
  │    ↓
  │  XmlDocument.parse()
  │    ↓
  │  Model.fromXml()
  │    ↓
  │  Update State
  │
  └─→ Error
       ↓
     Set Error Message
       ↓
     Update State
```

### API 端点

```
Video API:
  • {baseUrl}?ac=list&wd={keyword}      # 搜索
  • {baseUrl}?ac=list&pg={page}         # 列表
  • {baseUrl}?ac=detail&ids={id}        # 详情

Image API:
  • {baseUrl}?t={timestamp}             # 随机图片

Short Video API:
  • {baseUrl}&t={timestamp}             # 短视频
```

---

## 💾 本地存储

### SharedPreferences 结构

```
Key: currentSiteIndex
Value: 0 (int)

Key: search_history
Value: ["关键词1", "关键词2", ...] (JSON)

Key: play_history
Value: [
  {
    "videoId": "123",
    "videoName": "xxx",
    "episodeName": "第01集",
    "watchTime": "2026-06-17T12:00:00.000"
  },
  ...
] (JSON)

Key: favorites
Value: [
  {
    "videoId": "123",
    "videoName": "xxx",
    "videoPic": "url",
    "addTime": "2026-06-17T12:00:00.000"
  },
  ...
] (JSON)
```

---

## 🎯 核心设计模式

### 1. Provider Pattern (状态管理)
```dart
ChangeNotifierProvider(
  create: (_) => VideoProvider(),
  child: Consumer<VideoProvider>(
    builder: (context, provider, child) {
      return Widget();
    },
  ),
)
```

### 2. Repository Pattern (数据访问)
```dart
class VideoProvider {
  Future<void> searchVideos() async {
    // 网络请求
    final response = await http.get(...);
    // 数据解析
    final videos = parse(response);
    // 状态更新
    _videos = videos;
    notifyListeners();
  }
}
```

### 3. Factory Pattern (模型创建)
```dart
class Video {
  factory Video.fromXml(XmlElement element) {
    return Video(
      id: element.findElements('id').first.text,
      name: element.findElements('name').first.text,
      ...
    );
  }
}
```

---

## 🚀 性能优化

### 图片缓存
```
CachedNetworkImage
  ├─→ Memory Cache (快速访问)
  ├─→ Disk Cache (持久化)
  └─→ Network (最后选项)
```

### 列表复用
```
GridView.builder
  └─→ 只构建可见项
       └─→ 滚动时复用 Widget
```

### 延迟加载
```
Assets (api_sites.json)
  └─→ 首次加载时读取
       └─→ 缓存在内存中
```

---

## 📈 扩展性设计

### 添加新功能
```
1. 创建 Provider (如需要)
2. 创建 Screen/Widget
3. 在 main.dart 注册 Provider
4. 添加路由/入口
```

### 添加新站点类型
```
1. 在 api_sites.json 添加站点
2. 创建对应的 Screen
3. 在 SiteProvider 中过滤
4. 添加 UI 入口
```

---

## 🔧 配置管理

```
constants.dart
  ├─→ API 配置 (超时、重试)
  ├─→ UI 配置 (网格列数、间距)
  ├─→ 缓存配置 (时长、大小)
  └─→ 存储键 (SharedPreferences)
```

---

**架构版本**: 1.0.0  
**更新日期**: 2026-06-17  

基于 **Clean Architecture** 和 **MVVM** 设计理念 ✨
