FactoryBot.define do
  # 有効なユーザー
  factory :user do
    email { Faker::Internet.unique.email } # 一意でランダムなメールアドレスを生成
    password { "Password1" }
    password_confirmation { password }

    # メール認証に成功
    trait :confirmed do
      confirmed_at { Time.current }
    end
  end
end
