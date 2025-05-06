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

                # メールアドレスをユニーク値に変更。退会ユーザーが同一メールアドレスで再登録できるように。
                email_prefix, email_domain = current_api_v1_user.email.split("@")
                new_email = "#{email_prefix}_deleted_#{SecureRandom.hex(6)}@#{email_domain}"

                current_api_v1_user.update!(
                  is_deleted: true,
                  confirmed_at: nil,
                  tokens: {},
                  email: new_email
                )
              end
              render json: { message: "退会が正常に完了しました" }, status: :ok
            rescue ActiveRecord::RecordInvalid => e
              Rails.logger.error "退会バリデーションエラー: #{e.record.errors.full_messages.join(', ')}"
              render json: { error: "退会に失敗しました", details: "#{e.record.errors.full_messages.join(', ')}" }, status: :internal_server_error
            rescue => e
              Rails.logger.error "退会エラー: #{e.message}"
              render json: { error: "退会に失敗しました" }, status: :internal_server_error
            end
          else
            render json: { error: "ユーザーが見つかりません" }, status: :not_found
          end
        end
      end
    end
  end
end
