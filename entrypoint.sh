#!/bin/bash
set -e  # エラーが発生するとスクリプトを終了

# Railsサーバー安定起動のために server.pid を削除するよう設定
rm -f /app/tmp/pids/server.pid

# Dockerfileで定義した CMDのコマンド を実行
exec "$@"