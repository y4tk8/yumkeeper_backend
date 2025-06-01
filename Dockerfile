# --- ビルドステージ ---
# 最新軽量版Rubyのイメージ（2025年1月時点）
FROM ruby:3.3.7-alpine AS builder

ENV LANG=C.UTF-8 \
    TZ=Asia/Tokyo

RUN apk update && apk add --no-cache \
    build-base \
    yaml-dev \
    postgresql-dev \
    postgresql-client \
    git \
    bash \
    tzdata

WORKDIR /app
COPY Gemfile Gemfile.lock /app/
RUN bundle install
COPY . /app/

# --- 実行ステージ ---
FROM ruby:3.3.7-alpine

ENV LANG=C.UTF-8 \
    TZ=Asia/Tokyo

RUN apk update && apk add --no-cache \
    postgresql-client \
    bash \
    tzdata

WORKDIR /app
COPY --from=builder /app/ /app/
COPY --from=builder /usr/local/bundle /usr/local/bundle

COPY entrypoint.sh /usr/bin/
RUN chmod +x /usr/bin/entrypoint.sh
ENTRYPOINT [ "entrypoint.sh" ]

EXPOSE 3000

CMD [ "bundle", "exec", "puma", "-C", "config/puma.rb" ]