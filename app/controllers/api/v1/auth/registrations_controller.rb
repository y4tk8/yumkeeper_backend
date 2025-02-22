module Api
  module V1
    module Auth
      class RegistrationsController < DeviseTokenAuth::RegistrationsController

        # DELETE /api/v1/auth
        def destroy
          if current_api_v1_user
            current_api_v1_user.update(is_deleted: true, confirmed_at: nil, tokens: {})
            render json: { message: "退会処理が正常に完了しました。" }, status: :ok
          else
            render json: { message: ["ユーザーが見つかりません。"] }, status: :not_found
          end
        end
      end
    end
  end
end
