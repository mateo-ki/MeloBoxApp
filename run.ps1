# MeloBox App Runner
Write-Host "================================" -ForegroundColor Cyan
Write-Host "MeloBox App - Flutter 项目" -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan
Write-Host ""

# 检查 Flutter 是否安装
if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
    Write-Host "[错误] Flutter 未安装或未添加到 PATH 环境变量" -ForegroundColor Red
    Write-Host ""
    Write-Host "请先安装 Flutter SDK："
    Write-Host "https://flutter.dev/docs/get-started/install/windows"
    Write-Host ""
    Read-Host "按 Enter 键退出"
    exit 1
}

Write-Host "[1] 检查 Flutter 环境" -ForegroundColor Yellow
flutter doctor
Write-Host ""

Write-Host "[2] 安装依赖" -ForegroundColor Yellow
flutter pub get
Write-Host ""

Write-Host "[3] 可用设备列表" -ForegroundColor Yellow
flutter devices
Write-Host ""

Write-Host "================================" -ForegroundColor Cyan
Write-Host "选择操作：" -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan
Write-Host "1. 运行应用（自动选择设备）"
Write-Host "2. 运行在 Chrome 浏览器"
Write-Host "3. 运行在 Windows 桌面"
Write-Host "4. 构建 Android APK (Debug)"
Write-Host "5. 构建 Android APK (Release)"
Write-Host "6. 清理项目"
Write-Host "7. 退出"
Write-Host ""

$choice = Read-Host "请输入选项 (1-7)"

switch ($choice) {
    "1" {
        Write-Host ""
        Write-Host "正在启动应用..." -ForegroundColor Green
        flutter run
    }
    "2" {
        Write-Host ""
        Write-Host "正在启动 Web 应用..." -ForegroundColor Green
        flutter run -d chrome
    }
    "3" {
        Write-Host ""
        Write-Host "正在启动 Windows 应用..." -ForegroundColor Green
        flutter run -d windows
    }
    "4" {
        Write-Host ""
        Write-Host "正在构建 Debug APK..." -ForegroundColor Green
        flutter build apk
        Write-Host ""
        Write-Host "APK 位置: build\app\outputs\flutter-apk\app-debug.apk" -ForegroundColor Green
    }
    "5" {
        Write-Host ""
        Write-Host "正在构建 Release APK..." -ForegroundColor Green
        flutter build apk --release
        Write-Host ""
        Write-Host "APK 位置: build\app\outputs\flutter-apk\app-release.apk" -ForegroundColor Green
    }
    "6" {
        Write-Host ""
        Write-Host "正在清理项目..." -ForegroundColor Green
        flutter clean
        Write-Host "清理完成！" -ForegroundColor Green
    }
    "7" {
        exit 0
    }
    default {
        Write-Host ""
        Write-Host "无效的选项！" -ForegroundColor Red
    }
}

Write-Host ""
Read-Host "按 Enter 键退出"
