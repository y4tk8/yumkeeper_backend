require "factory_bot_rails"

users = FactoryBot.create_list(:user, 5, :confirmed)

# 各ユーザーに5つのレシピを作成
users.each do |user|
  FactoryBot.create_list(:recipe, 5, user: user)
end

puts "Seed data created successfully!"
