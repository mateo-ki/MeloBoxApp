# MeloBox App

一个功能完整的 Flutter 视频流媒体应用，支持视频搜索播放、图片浏览、短视频观看等多种功能。

## ⚡ 快速开始

**首次使用？** → 查看 [START_HERE.md](START_HERE.md) ⭐

**查看所有文档** → [doc/INDEX.md](doc/INDEX.md) 📚

## ✨ 核心功能

### 🎬 视频功能
- ✅ 视频搜索（带历史记录）
- ✅ 分类筛选（电影/电视剧/综艺/动漫/纪录片/短剧）
- ✅ 视频详情展示
- ✅ 多播放源支持
- ✅ 选集播放
- ✅ 在线播放（Chewie播放器）
- ✅ 40+ 视频资源站点

### 🖼️ 图片功能
- ✅ 随机图片浏览
- ✅ 同源/换源刷新
- ✅ 自动刷新（1/3/5秒）
- ✅ 图片缩放
- ✅ 20+ 图片站点

### 🎥 短视频功能
- ✅ 短视频播放
- ✅ 换一个/换分类
- ✅ 自动循环
- ✅ 20+ 短视频站点

### 💾 用户数据
- ✅ 搜索历史（最多10条）
- ✅ 播放历史（最多50条）
- ✅ 收藏功能
- ✅ 数据管理

### 📥 下载管理
- ✅ 下载管理UI
- ⏳ 下载功能（待集成）

## 📊 项目规模

- **总文件数**: 50+
- **代码行数**: ~4700
- **功能模块**: 15+
- **支持站点**: 80+
- **完整文档**: 15个

## 🚀 如何运行

### 方法 1: 使用脚本（推荐）
```bash
# Windows
run.bat

# PowerShell
.\run.ps1
```

### 方法 2: 命令行
```bash
# 安装依赖
flutter pub get

# 运行应用
flutter run
```

### 方法 3: 构建 APK
详见 [doc/BUILD_GUIDE.md](doc/BUILD_GUIDE.md)

```bash
flutter build apk --release --android-skip-build-dependency-validation
```

## 📚 文档导航

### 🚀 入门指南
- [START_HERE.md](START_HERE.md) - 快速开始 ⭐
- [doc/INSTALL.md](doc/INSTALL.md) - 安装指南
- [doc/BUILD_GUIDE.md](doc/BUILD_GUIDE.md) - APK 构建指南

### 📖 功能文档
- [doc/FEATURES_COMPLETE.md](doc/FEATURES_COMPLETE.md) - 完整功能清单
- [doc/QUICK_GUIDE.md](doc/QUICK_GUIDE.md) - 快速参考指南
- [doc/CHANGELOG.md](doc/CHANGELOG.md) - 更新日志

### 🏗️ 技术文档
- [doc/PROJECT_OVERVIEW.md](doc/PROJECT_OVERVIEW.md) - 项目概览
- [doc/ARCHITECTURE.md](doc/ARCHITECTURE.md) - 架构设计

### 📋 项目报告
- [doc/DELIVERY.md](doc/DELIVERY.md) - 项目交付说明
- [doc/FINAL_REPORT.md](doc/FINAL_REPORT.md) - 最终报告

### 📚 查看所有文档
👉 [doc/INDEX.md](doc/INDEX.md)

## 🎯 技术栈

- **Flutter** 3.38.3 - UI 框架
- **Provider** 6.1.5+ - 状态管理
- **video_player** 2.11.1 - 视频播放
- **chewie** 1.14.1 - 播放器 UI
- **cached_network_image** 3.4.1 - 图片缓存
- **http** 1.6.0 / **dio** 5.9.2 - 网络请求
- **xml** 6.6.1 - XML 解析
- **shared_preferences** 2.5.5 - 本地存储

## 📂 项目结构

```
lib/
├── main.dart                 # 应用入口
├── models/                   # 数据模型（2个）
├── providers/                # 状态管理（7个）
├── screens/                  # 页面（10个）
├── widgets/                  # 组件（7个）
└── utils/                    # 工具（5个）
```

## 🎨 功能展示

### 主界面
```
┌──────────────────────────────────┐
│ ☰ MeloBox      ⋮  ♥  ⏱  ↻      │
├──────────────────────────────────┤
│ 🔍 搜索视频...            [搜索]  │
│ 📺 当前站点: 默认                │
│ [全部][电影][电视剧][综艺]...   │
├──────────────────────────────────┤
│ ┌────┬────┐ ┌────┬────┐         │
│ │📺  │📺  │ │📺  │📺  │         │
└──────────────────────────────────┘
```

### 功能入口
- **☰** - 侧边栏（80+ 站点）
- **⋮** - 更多（图片/短视频/下载）
- **♥** - 收藏列表
- **⏱** - 播放历史
- **↻** - 刷新

## ⚡ 性能特点

- 🚀 图片缓存优化
- 🚀 列表复用
- 🚀 延迟加载
- 🚀 状态管理优化

## ⚠️ 免责声明

⚖️ 本应用仅作技术演示和学习用途  
⚖️ 不提供、存储或分发任何内容  
⚖️ 内容来自第三方资源站点  
⚖️ 用户需遵守法律法规和版权规定  

## 📞 获取帮助

### 遇到问题？
1. 查看 [doc/INSTALL.md](doc/INSTALL.md) - 安装配置问题
2. 查看 [doc/BUILD_GUIDE.md](doc/BUILD_GUIDE.md) - 构建问题
3. 查看 [doc/QUICK_GUIDE.md](doc/QUICK_GUIDE.md) - 使用问题

### 想了解更多？
- 功能详情 → [doc/FEATURES_COMPLETE.md](doc/FEATURES_COMPLETE.md)
- 技术架构 → [doc/ARCHITECTURE.md](doc/ARCHITECTURE.md)
- 项目报告 → [doc/DELIVERY.md](doc/DELIVERY.md)

## 🎊 项目状态

**开发状态**: ✅ 完成  
**功能完成度**: 95%  
**文档完善度**: 100%  
**版本**: 1.0.0  
**更新日期**: 2026-06-17  

---

## 💝 感谢使用

希望 MeloBox App 对你有所帮助！

**开始使用** → [START_HERE.md](START_HERE.md) ⭐

---

*Built with Flutter 💙*
