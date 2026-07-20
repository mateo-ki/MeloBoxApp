# MeloBox App - 安装和运行指南

## 1. 安装 Flutter SDK

### Windows 安装步骤

1. 下载 Flutter SDK
   访问：https://flutter.dev/docs/get-started/install/windows
   下载最新稳定版 Flutter SDK

2. 解压到指定目录（例如：`C:\src\flutter`）

3. 添加到系统环境变量
   - 打开"系统属性" -> "高级" -> "环境变量"
   - 在用户变量中找到 `Path`
   - 添加：`C:\src\flutter\bin`

4. 验证安装
```powershell
flutter --version
flutter doctor
```

## 2. 安装必要工具

运行 Flutter doctor 检查缺少的依赖：

```powershell
flutter doctor
```

根据提示安装：
- Android Studio (包含 Android SDK)
- Visual Studio Code (推荐)
- Chrome (用于 Web 开发)

### Android 开发环境

1. 安装 Android Studio
2. 安装 Android SDK (API 21 或更高)
3. 创建 Android 虚拟设备 (AVD) 或连接真机

### iOS 开发环境 (仅 macOS)

1. 安装 Xcode
2. 安装 CocoaPods：`sudo gem install cocoapods`

## 3. 安装项目依赖

在项目目录下运行：

```powershell
cd D:\project\dart\MeloBoxApp
flutter pub get
```

## 4. 运行应用

### 运行在 Android 设备/模拟器

```powershell
# 查看可用设备
flutter devices

# 运行应用
flutter run
```

### 运行在 Web 浏览器

```powershell
flutter run -d chrome
```

### 运行在 Windows 桌面

```powershell
flutter run -d windows
```

## 5. 构建发布版本

### 构建 Android APK

```powershell
# Debug APK
flutter build apk

# Release APK
flutter build apk --release

# 分架构构建（体积更小）
flutter build apk --split-per-abi
```

APK 输出位置：
- `build/app/outputs/flutter-apk/app-release.apk`

### 构建 Android App Bundle (AAB)

用于 Google Play 商店发布：

```powershell
flutter build appbundle --release
```

AAB 输出位置：
- `build/app/outputs/bundle/release/app-release.aab`

### 构建 Windows 应用

```powershell
flutter build windows --release
```

输出位置：
- `build/windows/runner/Release/`

## 6. 常见问题

### Flutter 命令未找到
确保 Flutter SDK 已添加到系统 PATH 环境变量

### Gradle 下载慢
配置 Gradle 镜像，编辑 `android/build.gradle`：
```gradle
repositories {
    maven { url 'https://maven.aliyun.com/repository/google' }
    maven { url 'https://maven.aliyun.com/repository/jcenter' }
    google()
    mavenCentral()
}
```

### 视频播放问题
- 确保设备/模拟器有网络连接
- 某些视频源可能需要特定的播放器后端
- iOS 需要配置 `Info.plist` 允许 HTTP 连接

### 依赖冲突
删除缓存重新安装：
```powershell
flutter clean
flutter pub get
```

## 7. 开发工具推荐

### Visual Studio Code
安装扩展：
- Flutter
- Dart
- Flutter Widget Snippets

### Android Studio
安装插件：
- Flutter
- Dart

## 8. 调试技巧

### 查看日志
```powershell
flutter logs
```

### 热重载
在运行应用时按 `r` 键进行热重载，按 `R` 键进行热重启

### 性能分析
```powershell
flutter run --profile
```

### 查看应用大小
```powershell
flutter build apk --analyze-size
```

## 9. 发布前检查清单

- [ ] 更改应用包名（`android/app/build.gradle` 中的 `applicationId`）
- [ ] 配置应用签名（创建 `keystore` 文件）
- [ ] 更新应用图标
- [ ] 更新应用名称
- [ ] 测试所有主要功能
- [ ] 检查网络权限配置
- [ ] 优化应用体积
- [ ] 混淆代码（Release 模式自动启用）

## 10. 快速命令参考

```powershell
# 创建新的 Flutter 项目
flutter create my_app

# 检查环境
flutter doctor -v

# 清理构建缓存
flutter clean

# 更新依赖
flutter pub upgrade

# 分析代码
flutter analyze

# 运行测试
flutter test

# 查看设备
flutter devices

# 查看模拟器
flutter emulators

# 启动模拟器
flutter emulators --launch <emulator_id>
```

## 联系和支持

如有问题，请查看：
- Flutter 官方文档：https://flutter.dev/docs
- Flutter 中文网：https://flutter.cn
- Stack Overflow：https://stackoverflow.com/questions/tagged/flutter
