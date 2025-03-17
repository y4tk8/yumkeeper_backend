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
      end
    end
  end
end
