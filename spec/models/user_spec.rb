require "rails_helper"

RSpec.describe User, type: :model do
  describe "Userのバリデーションチェック" do
    let(:user) { build(:user) }

    context "有効な場合" do
      it "メールアドレス、パスワード、確認用パスワードが適切なら有効" do
        expect(user).to be_valid
      end

      it "新しいユーザーがDBに保存される" do
        expect { create(:user) }.to change { User.count }.by(1)
      end
    end

    context "無効な場合" do
      it "すべての項目が空だと無効" do
        invalid_user = User.new
        expect(invalid_user).not_to be_valid
        expect(invalid_user.errors[:email]).to include("メールアドレスを入力してください")
        expect(invalid_user.errors[:password]).to include("パスワードを入力してください")
      end

      it "メールアドレスが空文字だと無効" do
        user.email = ""
        expect(user).not_to be_valid
        expect(user.errors[:email]).to include("メールアドレスを入力してください")
      end

      it "メールアドレスの形式が間違っていると無効" do
        user.email = "invalid-email"
        expect(user).not_to be_valid
        expect(user.errors[:email]).to include("メールアドレスは正しい形式で入力してください")
      end

      it "重複するメールアドレスがDBに存在すると無効" do
        create(:user, email: "test@example.com")
        duplicate_user = build(:user, email: "test@example.com")
        expect(duplicate_user).not_to be_valid
        expect(duplicate_user.errors[:email]).to include("入力したメールアドレスはすでに存在します")
      end

      it "パスワードが空文字だと無効" do
        user.password = ""
        user.password_confirmation = ""
        expect(user).not_to be_valid
        expect(user.errors[:password]).to include("パスワードを入力してください")
      end

      it "パスワードが8文字未満だと無効" do
        user.password = "a1"
        user.password_confirmation = "a1"
        expect(user).not_to be_valid
        expect(user.errors[:password]).to include("パスワードは8文字以上で入力してください")
      end

      it "パスワードが英字・数字どちらも含んでいないと無効" do
        user.password = "password"
        user.password_confirmation = "password"
        expect(user).not_to be_valid
        expect(user.errors[:password]).to include("パスワードは英字と数字を含んでください")
      end

      it "パスワードと確認用パスワードが一致しないと無効" do
        user.password_confirmation = "DifferentPassword1"
        expect(user).not_to be_valid
        expect(user.errors[:password_confirmation]).to include("入力したパスワードが一致しません")
      end
    end
  end

  describe "dependent: :destroy の動作チェック" do
    let!(:user) { create(:user) }
    let!(:recipes) { create_list(:recipe, 5, user: user) }

    it "ユーザーを削除すると関連するレシピ（recipe）も削除される" do
      expect { user.destroy }.to change { Recipe.count }.by(-5)
    end
  end

  describe "プロフィール情報のバリデーションチェック" do
    let(:user) { build(:user) }

    context "有効な場合" do
      it "ユーザー名が適切なら有効" do
        expect(user).to be_valid
      end

      it "画像が適切なら正常にアップロードされる" do
        user.profile_image.attach(
          io: File.open(Rails.root.join("spec/fixtures/profile_image.webp")),
          filename: "profile_image.webp",
          content_type: "image/webp"
        )

        expect(user.profile_image).to be_attached
        expect(user).to be_valid
      end
    end

    context "無効な場合" do
      it "ユーザー名が21文字以上だと無効" do
        user.username = "a" * 21
        expect(user).to be_invalid
        expect(user.errors["username"]).to include("ユーザー名は20文字以内で入力してください")
      end

      it "画像サイズが5MBを超えると無効" do
        large_file = Tempfile.new(["large_image", ".jpg"])
        large_file.write("a" * 5.1.megabytes)
        large_file.rewind

        user.profile_image.attach(
          io: large_file,
          filename: "large_image.jpg",
          content_type: "image/jpeg"
        )

        expect(user).to be_invalid
        expect(user.errors[:profile_image]).to include("プロフィール画像は5MB以下にしてください")
      end

      it "許可されていない形式の画像をアップロードすると無効" do
        user.profile_image.attach(
          io: File.open(Rails.root.join("spec/fixtures/invalid_image.txt")),
          filename: "invalid_image.txt",
          content_type: "text/plain"
        )

        expect(user).to be_invalid
        expect(user.errors[:profile_image]).to include("プロフィール画像はJPEG, PNG, GIF, WEBP形式のみアップロード可能です")
      end
    end
  end

  describe "#profile_image_url" do
    context "画像がアップロード済みの場合" do
      let(:user) { create(:user, :with_profile_image) }

      it "アップロードされた画像のURLを返す" do
        expect(user.profile_image_url).to include("/rails/active_storage/blobs/")
      end
    end

    context "画像がアップロードされていない場合" do
      let(:user) { create(:user) }

      it "デフォルトの画像URLを返す" do
        expect(user.profile_image_url).to eq("/default_profile_image.png")
      end
    end
  end
end
