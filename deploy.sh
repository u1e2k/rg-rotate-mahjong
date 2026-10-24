#!/usr/bin/env bash
# ANBERNIC RG Rotate向けビルド & ADB自動インストール・起動スクリプト (Bash版)

set -e

GODOT_BIN="C:/Users/user/AppData/Local/Microsoft/WinGet/Packages/GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe/Godot_v4.7.2-stable_win64_console.exe"
PACKAGE_NAME="com.anbernic.rgrotatemahjong"
ACTIVITY_NAME="com.godot.game.GodotAppLauncher"
APK_PATH="build/rgrotatemahjong.apk"
PRESET_NAME="Android"

echo "=================================================="
echo "   ANBERNIC RG Rotate Mahjong デプロイスクリプト   "
echo "=================================================="

# 1. デバイス確認
echo "[1/5] ADB接続デバイスを確認中..."
DEVICES=$(adb devices | grep -v "List of devices attached" | grep -v "^$" | grep -v "^\*")
COUNT=$(echo "$DEVICES" | grep -v "^$" | wc -l)

if [ "$COUNT" -eq 0 ]; then
    echo "[ERROR] Androidデバイスが検出されませんでした。"
    exit 1
fi

if [ "$COUNT" -gt 1 ]; then
    echo "[ERROR] 複数のデバイスが接続されています。1台のみ接続してください。"
    exit 1
fi

DEVICE_ID=$(echo "$DEVICES" | awk '{print $1}')
DEVICE_STATUS=$(echo "$DEVICES" | awk '{print $2}')

echo "検出デバイス: $DEVICE_ID ($DEVICE_STATUS)"

if [ "$DEVICE_STATUS" = "unauthorized" ]; then
    echo "【重要】RG Rotate実機の画面で『このパソコンからのUSBデバッグを常に許可しますか？』を許可してください。"
    for i in {1..15}; do
        sleep 2
        STATUS=$(adb devices | grep "^$DEVICE_ID" | awk '{print $2}')
        if [ "$STATUS" = "device" ]; then
            echo "デバイスが許可されました！"
            break
        fi
    done
fi

# 2. ビルド
echo "[2/5] GodotによるAndroid APKエクスポート中..."
mkdir -p build
"$GODOT_BIN" --headless --export-debug "$PRESET_NAME" "$APK_PATH"

# 3. インストール
echo "[3/5] 実機にAPKをインストール中..."
adb -s "$DEVICE_ID" install -r "$APK_PATH"

# 4. 起動
echo "[4/5] RG Rotate実機上でアプリを起動中..."
adb -s "$DEVICE_ID" shell am start -n "$PACKAGE_NAME/$ACTIVITY_NAME"

# 5. ログ監視
echo "[5/5] Godotログを追跡中 (Ctrl+Cで終了)..."
adb -s "$DEVICE_ID" logcat -c
adb -s "$DEVICE_ID" logcat -s Godot
