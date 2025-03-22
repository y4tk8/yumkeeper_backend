FactoryBot.define do
  factory :recipe do
    name { Faker::Food.dish }
    notes { Faker::Food.description }
    association :user
  end

  trait :with_ingredients do
    after(:create) do |recipe|
      create_list(:ingredient, 3, recipe: recipe)
    end
  end

  trait :with_video do
    after(:create) do |recipe|
      create(:video, recipe: recipe)
    end
  end
end
