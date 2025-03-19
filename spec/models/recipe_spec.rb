require "rails_helper"

RSpec.describe Recipe, type: :model do
  describe "Recipeのバリデーションチェック" do
    let(:user) { create(:user) }

    context "有効な場合" do
      it "レシピ名、メモが適切なら有効" do
        recipe = user.recipes.build(name: "テストレシピ", notes: "テストのメモ")
        expect(recipe).to be_valid
      end
    end

    context "無効な場合" do
      it "レシピ名が存在しなければ無効" do
        recipe = user.recipes.build(name: nil, notes: "テストのメモ")
        expect(recipe).to be_invalid
        expect(recipe.errors["name"]).to include("レシピ名を入力してください")
      end

      it "レシピ名が101文字以上だと無効" do
        recipe = user.recipes.build(name: "a" * 101, notes: "テストのメモ")
        expect(recipe).to be_invalid
        expect(recipe.errors["name"]).to include("レシピ名は100文字以内で入力してください")
      end
    end
  end

  describe "dependent: :destroy の動作チェック" do
    let!(:recipe) { create(:recipe) }
    let!(:ingredients) { create_list(:ingredient, 3, recipe: recipe) }
    let!(:video) { create(:video, recipe: recipe) }

    it "レシピを削除すると関連する材料（ingredients）も削除される" do
      expect { recipe.destroy }.to change { Ingredient.count }.by(-3)
    end

    it "レシピを削除すると関連する動画（video）も削除される" do
      expect { recipe.destroy }.to change { Video.count }.by(-1)
    end
  end
end
