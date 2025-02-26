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

      it "レシピ名が100文字以上だと無効" do
        recipe = user.recipes.build(name: "a" * 101, notes: "テストのメモ")
        expect(recipe).to be_invalid
        expect(recipe.errors["name"]).to include("レシピ名は100文字以内で入力してください")
      end
    end
  end
end
