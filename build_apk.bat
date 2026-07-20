@echo off
echo ================================
echo MeloBox App - 快速构建 APK
echo ================================
echo.

set FLUTTER_PATH=D:\software\flutter\bin
set PATH=%FLUTTER_PATH%;%PATH%

echo [1] 清理项目...
flutter clean

echo.
echo [2] 获取依赖...
flutter pub get

echo.
echo [3] 构建 Release APK...
flutter build apk --release

echo.
echo ================================
if exist "build\app\outputs\flutter-apk\app-release.apk" (
    echo 构建成功！
    echo APK 位置: build\app\outputs\flutter-apk\app-release.apk
    echo.
    echo 文件大小:
    dir "build\app\outputs\flutter-apk\app-release.apk" | find "app-release.apk"
) else (
    echo 构建失败！请查看上面的错误信息。
)

echo.
pause
