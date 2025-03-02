module Api
  module V1
    class RecipesController < ApplicationController
      # モデル名をキーにJSONデータを自動ラップする機能をオフに
      wrap_parameters false

      before_action :authenticate_api_v1_user! # Devise Token Authでユーザーのサインインを必須に
      before_action :set_user
      before_action :set_recipe, only: [:show, :update, :destroy]

      def index
        recipes = @user.recipes.order(created_at: :desc)
        render json: { recipes: recipes, recipe_count: @user.recipe_count }, status: :ok
      end

      def show
        render json: {
          recipe: {
            id: @recipe.id,
            name: @recipe.name,
            notes: @recipe.notes,
            created_at: @recipe.created_at,
            updated_at: @recipe.updated_at,
            ingredients: @recipe.ingredients.map do |ingredient|
              {
                id: ingredient.id,
                name: ingredient.name,
                quantity: ingredient.quantity,
                unit: ingredient.unit,
                category: ingredient.category
              }
            end
          }
        }, status: :ok
      end

      def create
        recipe = @user.recipes.build(recipe_params)

        if recipe.save
          render json: { message: "レシピが作成されました", recipe: recipe, ingredient: recipe.ingredients }, status: :created
        else
          render json: { error: "レシピの作成に失敗しました", details: recipe.errors.messages[:name] }, status: :unprocessable_entity
        end
      end

      def update
        if @recipe.update(recipe_params)
          render json: { message: "レシピが更新されました", recipe: @recipe, ingredient: @recipe.ingredients }, status: :ok
        else
          render json: { error: "レシピの更新に失敗しました", details: @recipe.errors.messages[:name] }, status: :unprocessable_entity
        end
      end

      def destroy
        if @recipe.destroy
          render json: { message: "レシピが削除されました" }, status: :ok
        else
          render json: { error: "レシピの削除に失敗しました" }, status: :unprocessable_entity
        end
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

      # ストロングパラメータ
      def recipe_params
        params.require(:recipe).permit(
          :name, :notes,
          ingredients_attributes: [:id, :name, :quantity, :unit, :category, :_destroy] # "_destroy": trueで指定IDの材料を削除
        )
      end
    end
  end
end
