module Api
  module V1
    class VideosController < ApplicationController
      before_action :authenticate_api_v1_user! # Devise Token Authでユーザーのサインインを必須に
      before_action :set_video
      before_action :authorize_user

      def update
        if @video.update(video_params)
          render json: { message: "動画が更新されました", video: @video }, status: :ok
        else
          render json: { error: "動画の更新に失敗しました", details: @video.errors.full_messages }, status: :unprocessable_entity
        end
      end

      private

      # レシピページに埋め込む動画を取得する
      def set_video
        @video = Video.find_by(id: params[:id])

        unless @video
          render json: { error: "動画が見つかりません。" }, status: :not_found
        end
      end

      # サインインユーザーと動画保持ユーザーが同一か検証する
      def authorize_user
        unless current_api_v1_user == @video.recipe.user
          render json: { error: "アクセス権限がありません。" }, status: :forbidden
        end
      end

      # ストロングパラメータ
      def video_params
        params.require(:video).permit(:etag, :status, :is_embeddable, :is_deleted, :cached_at)
      end
    end
  end
end
