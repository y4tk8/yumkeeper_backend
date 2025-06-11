## Pumaの設定

# Pumaの稼働スレッド数の最大値、最小値を定義
max_threads_count = ENV.fetch("RAILS_MAX_THREADS", 5)
min_threads_count = ENV.fetch("RAILS_MIN_THREADS", 1)
threads min_threads_count, max_threads_count

# Specifies the `port` that Puma will listen on to receive requests; default is 3000.
port ENV.fetch("PORT", 3000)

# Allow puma to be restarted by `bin/rails restart` command.
plugin :tmp_restart

# Specify the PID file. Defaults to tmp/pids/server.pid in development.
# In other environments, only set the PID file if requested.
pidfile ENV["PIDFILE"] if ENV["PIDFILE"]

# ルートディレクトリのパスを動的に取得
app_root = File.expand_path("../..", __FILE__)

# Nginxと共有するソケット保存用のディレクトリを作成
socket_dir = "#{app_root}/tmp/sockets"
Dir.mkdir(socket_dir) unless Dir.exist?(socket_dir)

# 本番環境 or 開発環境でリバースプロキシを経由したい場合、Nginxとの通信のためソケットファイルを取得
# それ以外はRailsサーバーを直接起動
bind_address = ENV["RAILS_ENV"] == "production" || ENV["USE_REVERSE_PROXY"] == "true" ?
  "unix://#{app_root}/tmp/sockets/puma.sock" :
  "tcp://0.0.0.0:3000"
bind bind_address

# ログ出力
if ENV.fetch("RAILS_ENV", "development") == "production"
  stdout_redirect(nil, nil, true) # 本番: STDOUTへ -> CloudWatch に流す
else
  stdout_redirect "#{app_root}/log/puma.stdout.log", "#{app_root}/log/puma.stderr.log", true # 開発: ログファイルへ出力
end
