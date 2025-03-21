class ApplicationController < ActionController::API
  # モデル名をキーにJSONデータを自動ラップする機能をオフに
  wrap_parameters false

  # トークンベースのユーザー認証
  include DeviseTokenAuth::Concerns::SetUserByToken

  # ページネーション
  include Pagy::Backend
end
