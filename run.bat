@echo off
echo ================================
echo MeloBox App - Flutter 项目
echo ================================
echo.

where flutter >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo [错误] Flutter 未安装或未添加到 PATH 环境变量
    echo.
    echo 请先安装 Flutter SDK：
    echo https://flutter.dev/docs/get-started/install/windows
    echo.
    pause
    exit /b 1
)

echo [1] 检查 Flutter 环境
flutter doctor
echo.

echo [2] 安装依赖
flutter pub get
echo.

echo [3] 可用设备列表
flutter devices
echo.

echo ================================
echo 选择操作：
echo ================================
echo 1. 运行应用（自动选择设备）
echo 2. 运行在 Chrome 浏览器
echo 3. 运行在 Windows 桌面
echo 4. 构建 Android APK
echo 5. 构建 Release APK
echo 6. 清理项目
echo 7. 退出
echo.

set /p choice=请输入选项 (1-7):

if "%choice%"=="1" (
    echo.
    echo 正在启动应用...
    flutter run
) else if "%choice%"=="2" (
    echo.
    echo 正在启动 Web 应用...
    flutter run -d chrome
) else if "%choice%"=="3" (
    echo.
    echo 正在启动 Windows 应用...
    flutter run -d windows
) else if "%choice%"=="4" (
    echo.
    echo 正在构建 Debug APK...
    flutter build apk
    echo.
    echo APK 位置: build\app\outputs\flutter-apk\app-debug.apk
) else if "%choice%"=="5" (
    echo.
    echo 正在构建 Release APK...
    flutter build apk --release
    echo.
    echo APK 位置: build\app\outputs\flutter-apk\app-release.apk
) else if "%choice%"=="6" (
    echo.
    echo 正在清理项目...
    flutter clean
    echo 清理完成！
) else if "%choice%"=="7" (
    exit /b 0
) else (
    echo.
    echo 无效的选项！
)

echo.
pause
