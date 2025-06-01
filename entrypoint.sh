#!/bin/bash
set -e  # エラーが発生するとスクリプトを終了

# Railsサーバー安定起動のために server.pid を削除するよう設定
rm -f /app/tmp/pids/server.pid

if [ "$RAILS_ENV" = "production" ]; then
  # 本番環境（AWS ECS on Fargate）への初回デプロイ時に利用
  # 初回デプロイ後にコメントアウトする
  bundle exec rails db:create || echo "Database already exists. Skipping creation."

  bundle exec rails db:migrate
fi

# Dockerfileで定義した CMDのコマンド を実行
exec "$@"