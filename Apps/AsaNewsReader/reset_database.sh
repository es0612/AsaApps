#!/bin/bash

# AsaNewsReader データベースリセットスクリプト

echo "🔄 AsaNewsReader データベースリセット開始..."

# シミュレーターのディレクトリを探す
SIMULATOR_DIR=$(find ~/Library/Developer/CoreSimulator/Devices -name "*AsaNewsReader*" -type d 2>/dev/null | head -1)

if [ -z "$SIMULATOR_DIR" ]; then
    echo "❌ AsaNewsReaderのシミュレーターデータが見つかりません"
    echo "ℹ️  手動で以下のディレクトリを確認してください："
    echo "   ~/Library/Developer/CoreSimulator/Devices/*/data/Containers/Data/Application/*/Documents/"
    exit 1
fi

echo "📁 シミュレーターディレクトリ: $SIMULATOR_DIR"

# NewsReader関連のファイルを検索・削除
find "$SIMULATOR_DIR" -name "NewsReader*" -type f -exec rm -v {} \;

echo "✅ データベースファイルの削除が完了しました"
echo "🔄 アプリを再起動してフィード追加を試してください"