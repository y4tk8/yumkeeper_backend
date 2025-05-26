module TestSupport
  module Api
    module V1
      class TestUserConfirmationsController < ApplicationController

        # フロントのE2Eテストでユーザーを`認証済み`に
        def update
          return head :forbidden unless Rails.env.development? || Rails.env.test?

          user = User.find_by(email: params[:email])

          if user
            user.update!(confirmed_at: Time.current)
            render json: { message: "User confirmed." }, status: :ok
          else
            render json: { error: "User not found." }, status: :not_found
          end
        end
      end
    end
  end
end
