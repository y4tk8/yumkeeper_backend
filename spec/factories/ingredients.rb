FactoryBot.define do
  factory :ingredient do
    association :recipe

    # 60%の確率で材料（ingredient）、40%の確率で調味料（seasoning）
    after(:build) do |ingredient|
      if rand < 0.6
        ingredient.name = Faker::Food.ingredient
        ingredient.quantity = rand(1..5)
        ingredient.unit = ["個", "本", "枚"].sample
        ingredient.category = "ingredient"
      else
        ingredient.name = Faker::Food.spice
        ingredient.quantity = rand(1.0..10.0).round(1)
        ingredient.unit = ["g", "ml", "杯"].sample
        ingredient.category = "seasoning"
      end
    end
  end
end
