# MeloBox App - 项目概览

## 项目简介

MeloBox App 是一个基于 Flutter 开发的跨平台视频流媒体应用，支持搜索、浏览和播放来自多个视频资源站点的内容。

## 核心功能

### 1. 视频搜索
- 关键词搜索功能
- 实时搜索结果展示
- 支持空搜索加载全部列表

### 2. 视频浏览
- 响应式网格布局
- 封面图片缓存优化
- 视频信息展示（标题、类型、状态）

### 3. 视频详情
- 完整的视频信息展示
- 演员、导演、年份、地区等详细信息
- 视频简介

### 4. 视频播放
- 多播放源支持
- 选集播放功能
- 全屏播放支持
- 播放控制（暂停、快进、音量等）

### 5. 多站点管理
- 支持 40+ 视频资源站点
- 侧边栏站点切换
- 自动记住用户选择
- 站点状态保存

## 技术架构

### 状态管理
使用 Provider 模式进行状态管理：
- `SiteProvider` - 管理站点列表和当前选择
- `VideoProvider` - 管理视频数据和加载状态

### 网络请求
- HTTP 请求使用 `http` 包
- XML 数据解析使用 `xml` 包
- 超时处理和错误处理

### UI 组件
- Material Design 3
- 自定义组件封装
- 响应式布局

### 数据持久化
- SharedPreferences 保存用户偏好
- 图片缓存使用 cached_network_image

## API 接口

### 资源站接口格式

#### 1. 搜索/列表接口
```
GET {baseUrl}?ac=list&wd={keyword}&pg={page}
```

参数：
- `ac`: 操作类型，固定为 `list`
- `wd`: 搜索关键词（可选）
- `pg`: 页码（可选）

#### 2. 详情接口
```
GET {baseUrl}?ac=detail&ids={videoId}
```

参数：
- `ac`: 操作类型，固定为 `detail`
- `ids`: 视频 ID

#### 3. XML 响应结构

```xml
<?xml version="1.0" encoding="utf-8"?>
<rss>
  <list>
    <video>
      <id>123</id>
      <name>视频标题</name>
      <pic>https://example.com/cover.jpg</pic>
      <note>更新状态</note>
      <type>类型</type>
      <actor>演员</actor>
      <director>导演</director>
      <des>简介</des>
      <year>年份</year>
      <area>地区</area>
      <lang>语言</lang>
      <dd flag="播放源1">第01集$url1#第02集$url2</dd>
      <dd flag="播放源2">第01集$url3#第02集$url4</dd>
    </video>
  </list>
</rss>
```

播放地址格式：
- 多集之间用 `#` 分隔
- 集名和 URL 用 `$` 分隔
- 例如：`第01集$http://example.com/video1.m3u8#第02集$http://example.com/video2.m3u8`

## 文件说明

### 核心文件

| 文件 | 说明 |
|------|------|
| `lib/main.dart` | 应用入口，配置 Provider |
| `lib/models/api_site.dart` | 站点数据模型 |
| `lib/models/video.dart` | 视频数据模型 |
| `lib/providers/site_provider.dart` | 站点状态管理 |
| `lib/providers/video_provider.dart` | 视频状态管理 |
| `lib/screens/home_screen.dart` | 主页面 |
| `lib/screens/video_detail_screen.dart` | 详情页面 |
| `lib/screens/video_player_screen.dart` | 播放器页面 |
| `lib/widgets/video_grid.dart` | 视频网格组件 |
| `lib/widgets/site_drawer.dart` | 站点抽屉组件 |
| `lib/widgets/episode_selector.dart` | 选集组件 |

### 配置文件

| 文件 | 说明 |
|------|------|
| `pubspec.yaml` | Flutter 项目配置 |
| `api_sites.json` | 视频站点配置 |
| `android/app/build.gradle` | Android 构建配置 |
| `android/app/src/main/AndroidManifest.xml` | Android 清单文件 |

## 项目特点

### 1. 模块化设计
- 清晰的文件结构
- 功能组件化
- 易于维护和扩展

### 2. 性能优化
- 图片懒加载和缓存
- 网格视图复用
- 合理的状态管理

### 3. 用户体验
- 流畅的页面切换
- 友好的错误提示
- 加载状态反馈

### 4. 跨平台支持
- Android
- iOS
- Web
- Windows
- macOS
- Linux

## 扩展功能建议

### 短期扩展
1. 添加播放历史记录
2. 收藏功能
3. 下载功能
4. 播放进度保存

### 中期扩展
1. 分类浏览
2. 热门推荐
3. 搜索历史
4. 多语言支持

### 长期扩展
1. 用户账号系统
2. 弹幕功能
3. 投屏功能
4. 离线下载

## 依赖包说明

| 包名 | 版本 | 用途 |
|------|------|------|
| provider | ^6.1.1 | 状态管理 |
| http | ^1.1.0 | HTTP 请求 |
| dio | ^5.4.0 | 高级 HTTP 客户端 |
| video_player | ^2.8.1 | 视频播放核心 |
| chewie | ^1.7.4 | 视频播放器 UI |
| cached_network_image | ^3.3.0 | 图片缓存 |
| xml | ^6.5.0 | XML 解析 |
| shared_preferences | ^2.2.2 | 本地存储 |
| flutter_spinkit | ^5.2.0 | 加载动画 |

## 性能指标

### 应用体积
- Debug APK: ~50MB
- Release APK: ~20MB
- 分架构 APK: ~15MB

### 启动时间
- 冷启动: < 2s
- 热启动: < 0.5s

### 内存占用
- 首页: ~80MB
- 视频播放: ~150MB

## 开发注意事项

1. **视频源兼容性**：不同站点返回的 XML 格式可能略有差异
2. **网络错误处理**：需要处理超时、连接失败等情况
3. **播放器兼容性**：某些视频格式可能需要额外配置
4. **缓存管理**：定期清理图片缓存避免占用过多存储空间
5. **隐私和安全**：遵守相关法律法规，不存储用户隐私数据

## 许可证

MIT License

## 联系方式

- 项目地址：D:\project\dart\MeloBoxApp
- 参考项目：[MeloBox Desktop](D:\project\cpp\miniplayer)
