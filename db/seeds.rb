require "factory_bot_rails"

users = FactoryBot.create_list(:user, 5, :confirmed)

# 1人目: 110件 / 他4人: 各5件 のレシピを作成（1人目はページネーション確認のため多めに作成）
users.each_with_index do |user, index|
  recipe_count = index.zero? ? 110 : 5

  recipes = FactoryBot.create_list(:recipe, recipe_count, user: user)

  # 各レシピに3つの材料 or 調味料と1つの動画を紐付ける
  recipes.each do |recipe|
    3.times { FactoryBot.create(:ingredient, recipe: recipe) }
    FactoryBot.create(:video, thumbnail_url: "", recipe: recipe) # thumbnail_urlは空文字 -> フロントでデフォルト画像を表示する
  end
end

puts "Seed data created successfully!"
