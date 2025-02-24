FactoryBot.define do
  factory :recipe do
    name { Faker::Food.dish }
    notes { Faker::Food.description }
    association :user
  end
end
