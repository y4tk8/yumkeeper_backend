module Api
  module V1
    class UsersController < ApplicationController
      before_action :authenticate_api_v1_user! # Devise Token Authでユーザーのサインインを必須に
      before_action :set_user

      def show
        render json: {
          user: {
            id: @user.id,
            username: @user.username,
            profile_image_url: @user.profile_image_url
          }
        }, status: :ok
      end

      def update
        if @user.update(user_params)
          update_profile_image if params[:profile_image].present?

          render json: {
            message: "プロフィールを更新しました",
            user: {
              id: @user.id,
              username: @user.username,
              profile_image_url: @user.profile_image_url
            }
          }, status: :ok
        else
          render json: { error: "プロフィールの更新に失敗しました", details: @user.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def delete_profile_image
        if @user.profile_image.attached?
          @user.profile_image.purge
          render json: { message: "プロフィール画像を削除しました", profile_image_url: @user.profile_image_url }, status: :ok
        else
          render json: { error: "プロフィール画像が設定されていません" }, status: :not_found
        end
      end

      private

      # ユーザーを取得する
      def set_user
        param_user = User.find_by(id: params[:id])

        # サインインユーザーとパラメータ指定ユーザーが一致するか検証
        if current_api_v1_user == param_user
          @user = param_user
        else
          render json: { error: "アクセス権限がありません。" }, status: :forbidden
        end
      end

      # ストロングパラメータ
      def user_params
        params.require(:user).permit(:username, :profile_image)
      end
    end
  end
end
