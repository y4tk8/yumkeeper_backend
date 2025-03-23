FactoryBot.define do
  # 有効なユーザー
  factory :user do
    email { Faker::Internet.unique.email } # 一意でランダムなメールアドレスを生成
    password { "Password1" }
    password_confirmation { password }
    username { "テストユーザー" }

    # メール認証に成功
    trait :confirmed do
      confirmed_at { Time.current }
    end

    # 退会済み
    trait :deleted do
      is_deleted { true }
    end

    # プロフィール画像をアップロード済み
    trait :with_profile_image do
      after(:build) do |user|
        user.profile_image.attach(
          io: File.open(Rails.root.join("spec/fixtures/profile_image.webp")),
          filename: "profile_image.webp",
          content_type: "image/webp"
        )
      end
    end

    # ゲストユーザー
    trait :guest do
      email { "guest_#{SecureRandom.hex(6)}@example.com" }
      confirmed_at { Time.current }
      role { "ゲスト" }
    end
  end
end
