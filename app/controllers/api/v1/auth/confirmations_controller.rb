module Api
  module V1
    module Auth
      class ConfirmationsController < DeviseTokenAuth::ConfirmationsController

        protected

        # 認証メール再送後のレスポンスメッセージをカスタマイズ
        def render_create_success
          render json: {
            success: true,
            message: "アカウント認証メールを再送しました。メールをご確認ください。"
          }
        end

        private

        # 外部URLへのリダイレクトを許可する
        def redirect_options
          {
            allow_other_host: true
          }
        end
      end
    end
  end
end
