# 最新軽量版Nginxのイメージ(2025年1月時点)
FROM nginx:1.27.3-alpine

# 既定のNginx設定ファイルを削除
RUN rm -f /etc/nginx/conf.d/*

# カスタム設定ファイルを配置
COPY ./nginx/nginx.conf /etc/nginx/conf.d/nginx.conf

# Nginxをフォアグラウンド起動(デーモンをオフにしないと起動しない)
CMD /usr/sbin/nginx -g 'daemon off;' -c /etc/nginx/nginx.conf