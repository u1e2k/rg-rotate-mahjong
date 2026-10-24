<#
.SYNOPSIS
    ANBERNIC RG Rotate向けビルド & ADB自動インストール・起動スクリプト (PowerShell版)
#>

$ErrorActionPreference = "Stop"

# 設定
$GODOT_BIN = "C:\Users\user\AppData\Local\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.7.2-stable_win64_console.exe"
$PACKAGE_NAME = "com.anbernic.rgrotatemahjong"
$ACTIVITY_NAME = "com.godot.game.GodotAppLauncher"
$APK_PATH = "build/rgrotatemahjong.apk"
$PRESET_NAME = "Android"

Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "   ANBERNIC RG Rotate Mahjong デプロイスクリプト   " -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan

# 1. ADB デバイスの接続確認
Write-Host "[1/5] ADB接続デバイスを確認中..." -ForegroundColor Yellow
$devicesOutput = & adb devices | Where-Object { $_ -match "\S" -and $_ -notmatch "List of devices attached" -and $_ -notmatch "^\*" }
$deviceList = @($devicesOutput)

if ($deviceList.Count -eq 0) {
    Write-Host "[ERROR] Androidデバイスが検出されませんでした。" -ForegroundColor Red
    Write-Host "RG RotateがUSBケーブルでPCに接続されているか確認してください。" -ForegroundColor Red
    exit 1
}

if ($deviceList.Count -gt 1) {
    Write-Host "[ERROR] 複数のデバイスが接続されています。1台のみ接続してください:" -ForegroundColor Red
    $deviceList | ForEach-Object { Write-Host " - $_" -ForegroundColor Red }
    exit 1
}

$deviceLine = $deviceList[0].Trim()
$deviceParts = -split $deviceLine
$deviceId = $deviceParts[0]
$deviceStatus = $deviceParts[1]

Write-Host "検出デバイス: $deviceId ($deviceStatus)" -ForegroundColor Green

if ($deviceStatus -eq "unauthorized") {
    Write-Host "[WARN] デバイスが 'unauthorized' (未許可) です！" -ForegroundColor Yellow
    Write-Host "==========================================================" -ForegroundColor Magenta
    Write-Host "【重要】RG Rotate実機の画面を確認してください！" -ForegroundColor Magenta
    Write-Host "『このパソコンからのUSBデバッグを常に許可しますか？』" -ForegroundColor Magenta
    Write-Host "というダイアログが表示されています。[常に許可] をタップしてください。" -ForegroundColor Magenta
    Write-Host "==========================================================" -ForegroundColor Magenta
    
    # ユーザーが実機で許可を押すまで待機 (最大30秒)
    Write-Host "許可を待機しています..." -ForegroundColor Cyan
    $authorized = $false
    for ($i = 0; $i -lt 15; $i++) {
        Start-Sleep -Seconds 2
        $check = & adb devices | Where-Object { $_ -match "^$deviceId\s+device" }
        if ($check) {
            $authorized = $true
            break
        }
    }
    if (-not $authorized) {
        Write-Host "[ERROR] USBデバッグが許可されませんでした。端末側で許可をタップしてから再実行してください。" -ForegroundColor Red
        exit 1
    }
    Write-Host "デバイスが許可されました！" -ForegroundColor Green
}

# 2. Godot CLIでAPKをビルド
Write-Host "`n[2/5] GodotによるAndroid APKエクスポート中..." -ForegroundColor Yellow
if (-not (Test-Path "build")) {
    New-Item -ItemType Directory -Path "build" | Out-Null
}

$buildProcess = Start-Process -FilePath $GODOT_BIN -ArgumentList "--headless", "--export-debug", "`"$PRESET_NAME`"", "`"$APK_PATH`"" -NoNewWindow -PassThru -Wait
if ($buildProcess.ExitCode -ne 0) {
    Write-Host "[ERROR] APKエクスポートに失敗しました (Exit Code: $($buildProcess.ExitCode))" -ForegroundColor Red
    exit 1
}

if (-not (Test-Path $APK_PATH)) {
    Write-Host "[ERROR] APKファイルが見つかりません: $APK_PATH" -ForegroundColor Red
    exit 1
}
$apkSize = (Get-Item $APK_PATH).Length / 1MB
Write-Host "APKビルド完了: $APK_PATH ($([math]::Round($apkSize, 2)) MB)" -ForegroundColor Green

# 3. adb install -r で実機にインストール
Write-Host "`n[3/5] 実機にAPKを転送・インストール中..." -ForegroundColor Yellow
& adb -s $deviceId install -r $APK_PATH
if ($LASTEXITCODE -ne 0) {
    Write-Host "[ERROR] APKのインストールに失敗しました。" -ForegroundColor Red
    exit 1
}
Write-Host "インストール成功！" -ForegroundColor Green

# 4. アプリケーションの起動
Write-Host "`n[4/5] RG Rotate実機上でアプリを起動中..." -ForegroundColor Yellow
& adb -s $deviceId shell am start -n "$PACKAGE_NAME/$ACTIVITY_NAME"
if ($LASTEXITCODE -ne 0) {
    Write-Host "[ERROR] アプリの起動に失敗しました。" -ForegroundColor Red
    exit 1
}
Write-Host "アプリ起動完了！" -ForegroundColor Green

# 5. logcat追跡
Write-Host "`n[5/5] Godotのログ出力を追跡開始 (Ctrl+Cで終了)..." -ForegroundColor Yellow
Write-Host "--------------------------------------------------" -ForegroundColor DarkGray
& adb -s $deviceId logcat -c
& adb -s $deviceId logcat -s Godot
