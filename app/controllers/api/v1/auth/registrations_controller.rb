module Api
  module V1
    module Auth
      class RegistrationsController < DeviseTokenAuth::RegistrationsController

        # DELETE /api/v1/auth
        def destroy
          if current_api_v1_user
            begin
              ActiveRecord::Base.transaction do
                current_api_v1_user.delete_recipes
                current_api_v1_user.update!(is_deleted: true, confirmed_at: nil, tokens: {})
              end
              render json: { message: "退会処理が正常に完了しました。" }, status: :ok
            rescue => e
              render json: { error: "退会処理に失敗しました。" }, status: :internal_server_error
            end
          else
            render json: { error: "ユーザーが見つかりません。" }, status: :not_found
          end
        end
      end
    end
  end
end
