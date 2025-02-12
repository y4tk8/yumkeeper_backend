FactoryBot.define do
  # 有効なユーザー
  factory :user do
    email { Faker::Internet.unique.email } # 一意でランダムなメールアドレスを生成
    password { "Password1" }
    password_confirmation { password }
    confirmed_at { Time.current }
  end
end