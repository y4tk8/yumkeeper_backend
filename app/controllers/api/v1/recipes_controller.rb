module Api
  module V1
    class RecipesController < ApplicationController
      before_action :authenticate_api_v1_user! # Devise Token Authでユーザーのサインインを必須に
      before_action :set_user
      before_action :set_recipe, only: [:show, :update, :destroy]

      def index
        recipes = @user.recipes.order(created_at: :desc)
        render json: { recipes: recipes, recipe_count: @user.recipe_count }, status: :ok
      end

      def show
      end

      def create
      end

      def update
      end

      def destroy
      end

      private

      # ユーザーを取得する
      def set_user
        param_user = User.find_by(id: params[:user_id])

        # サインインユーザーとパラメータ指定ユーザーが一致するか検証
        if current_api_v1_user == param_user
          @user = param_user
        else
          render json: { error: "アクセス権限がありません。" }, status: :forbidden
        end
      end

      # ユーザーの各レシピを取得する
      def set_recipe
        @recipe = @user.recipes.find_by(id: params[:id])

        unless @recipe
          render json: { error: "レシピが見つかりません。" }, status: :forbidden
        end
      end
    end
  end
end
