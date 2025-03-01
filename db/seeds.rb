require "factory_bot_rails"

users = FactoryBot.create_list(:user, 5, :confirmed)

# 各ユーザーに5つのレシピを作成
users.each do |user|
  recipes = FactoryBot.create_list(:recipe, 5, user: user)

  # 各レシピに5つの材料 or 調味料を作成
  recipes.each do |recipe|
    5.times do
      FactoryBot.create(:ingredient, recipe: recipe)
    end
  end
end

puts "Seed data created successfully!"
