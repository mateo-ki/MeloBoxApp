# 📦 MeloBox App - APK 构建指南

## ⚠️ 构建问题说明

由于 Gradle 版本兼容性问题，APK 自动构建遇到了一些挑战。

建议你在本地环境手动构建 APK。

---

## 🛠️ 手动构建步骤

### 方法 1: 使用 Android Studio（推荐）

1. **打开项目**
   ```
   用 Android Studio 打开: D:\project\dart\MeloBoxApp
   ```

2. **等待 Gradle 同步完成**
   - Android Studio 会自动同步依赖
   - 如有错误提示，点击 "Try Again"

3. **构建 APK**
   ```
   菜单: Build → Flutter → Build APK
   ```
   
4. **获取 APK**
   ```
   位置: build/app/outputs/flutter-apk/app-release.apk
   ```

---

### 方法 2: 命令行构建

1. **打开 PowerShell**
   ```powershell
   cd D:\project\dart\MeloBoxApp
   ```

2. **设置环境变量**
   ```powershell
   $env:Path += ";D:\software\flutter\bin"
   ```

3. **清理项目**
   ```powershell
   flutter clean
   ```

4. **获取依赖**
   ```powershell
   flutter pub get
   ```

5. **构建 APK（跳过验证）**
   ```powershell
   flutter build apk --release --android-skip-build-dependency-validation
   ```

6. **获取 APK**
   ```
   位置: build\app\outputs\flutter-apk\app-release.apk
   ```

---

### 方法 3: 使用提供的脚本

直接双击运行：
```
D:\project\dart\MeloBoxApp\build_apk.bat
```

如果失败，编辑脚本添加跳过验证参数：
```bat
flutter build apk --release --android-skip-build-dependency-validation
```

---

## 🔧 常见问题解决

### 问题 1: Gradle 版本不兼容

**错误信息**:
```
Your project's Gradle version (X.X.X) is lower than...
```

**解决方案**:
使用跳过验证参数构建：
```bash
flutter build apk --release --android-skip-build-dependency-validation
```

---

### 问题 2: Kotlin 版本冲突

**错误信息**:
```
Incompatible classes were found in dependencies...
```

**解决方案**:

1. 清理 Gradle 缓存
   ```powershell
   cd android
   Remove-Item -Recurse -Force .gradle
   cd ..
   flutter clean
   ```

2. 重新构建
   ```powershell
   flutter build apk --release --android-skip-build-dependency-validation
   ```

---

### 问题 3: Android SDK 版本

**错误信息**:
```
requires Android SDK version XX or higher
```

**解决方案**:
已配置 compileSdk = 36，应该可以正常构建。

---

### 问题 4: NDK 版本

**错误信息**:
```
requires Android NDK XX.X.XXXXX
```

**解决方案**:
已配置 ndkVersion = "28.2.13676358"，Gradle 会自动下载。

---

## 📋 当前配置

### Gradle
```
版本: 8.9
位置: android/gradle/wrapper/gradle-wrapper.properties
```

### Android Gradle Plugin
```
版本: 8.6.0
位置: android/build.gradle
```

### Kotlin
```
版本: 2.2.20
位置: android/build.gradle
```

### 编译 SDK
```
compileSdk: 36
targetSdk: 35
位置: android/app/build.gradle
```

---

## ✅ 推荐的构建方法

### 最简单的方法：

```powershell
cd D:\project\dart\MeloBoxApp
$env:Path += ";D:\software\flutter\bin"
flutter build apk --release --android-skip-build-dependency-validation
```

**等待几分钟，APK 会生成在：**
```
build\app\outputs\flutter-apk\app-release.apk
```

---

## 📱 安装 APK

### 方法 1: USB 连接手机
```bash
adb install build\app\outputs\flutter-apk\app-release.apk
```

### 方法 2: 直接传输
1. 将 APK 文件传输到手机
2. 在手机上打开文件管理器
3. 找到 APK 文件并安装
4. 允许"安装未知来源应用"

---

## 🎯 预期结果

成功构建后：
- APK 文件大小: 约 20-30 MB
- 安装包位置: `build\app\outputs\flutter-apk\app-release.apk`
- 应用 ID: `com.melobox.app`
- 版本: 1.0.0

---

## 💡 提示

1. **首次构建**会下载很多依赖，需要较长时间（5-15分钟）
2. **网络连接**要稳定，需要下载 Gradle 插件和 SDK
3. **磁盘空间**确保有足够空间（建议至少 5GB）
4. **使用跳过验证**参数可以绕过大部分版本检查问题

---

## 🆘 如果还是失败

尝试这个方法：

```powershell
# 1. 完全清理
cd D:\project\dart\MeloBoxApp
Remove-Item -Recurse -Force build, android\.gradle, .dart_tool

# 2. 设置环境
$env:Path += ";D:\software\flutter\bin"
$env:ANDROID_SDK_ROOT = "D:\software\android\sdk"

# 3. 更新 Flutter
flutter upgrade

# 4. 构建
flutter build apk --release --android-skip-build-dependency-validation
```

---

## 📞 需要帮助？

如果构建过程中遇到其他问题：

1. 查看完整的错误日志
2. 确认 Flutter 和 Android SDK 已正确安装
3. 尝试在 Android Studio 中打开项目

---

**祝构建顺利！** 🎉

---

*更新日期: 2026-06-17*
