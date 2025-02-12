require "rails_helper"

RSpec.describe User, type: :model do
  describe "ユーザーのサインアップ" do
    let(:user) { build(:user) }

    context "有効なユーザー" do
      it "有効なメールアドレス、パスワード、確認用パスワードでサインアップが成功する" do
        expect(user).to be_valid
      end

      it "サインアップが成功した結果、DBにユーザーが保存される" do
        expect { create(:user) }.to change { User.count }.by(1)
      end
    end

    context "無効なユーザー" do
      it "入力値が何もないとサインアップできない" do
        invalid_user = User.new
        expect(invalid_user).not_to be_valid
        expect(invalid_user.errors[:email]).to include("メールアドレスを入力してください")
        expect(invalid_user.errors[:password]).to include("パスワードを入力してください")
      end

      it "メールアドレスが空文字だとサインアップできない" do
        user.email = ""
        expect(user).not_to be_valid
        expect(user.errors[:email]).to include("メールアドレスを入力してください")
      end

      it "メールアドレスの形式が間違っているとサインアップできない" do
        user.email = "invalid-email"
        expect(user).not_to be_valid
        expect(user.errors[:email]).to include("メールアドレスは正しい形式で入力してください")
      end

      it "入力したメールアドレスと同一のメールアドレスがDBに登録済みの場合、サインアップできない" do
        create(:user, email: "test@example.com")
        duplicate_user = build(:user, email: "test@example.com")
        expect(duplicate_user).not_to be_valid
        expect(duplicate_user.errors[:email]).to include("入力したメールアドレスはすでに存在します")
      end

      it "パスワードが空文字だとサインアップできない" do
        user.password = ""
        user.password_confirmation = ""
        expect(user).not_to be_valid
        expect(user.errors[:password]).to include("パスワードを入力してください")
      end

      it "パスワードが短すぎるとサインアップできない" do
        user.password = "a1"
        user.password_confirmation = "a1"
        expect(user).not_to be_valid
        expect(user.errors[:password]).to include("パスワードは英字と数字を含んだ8文字以上にしてください")
      end

      it "パスワードの形式が間違っているとサインアップできない" do
        user.password = "password"
        user.password_confirmation = "password"
        expect(user).not_to be_valid
        expect(user.errors[:password]).to include("パスワードは英字と数字を含んだ8文字以上にしてください")
      end

      it "パスワードと確認用パスワードが一致しないとサインアップできない" do
        user.password_confirmation = "DifferentPassword1"
        expect(user).not_to be_valid
        expect(user.errors[:password_confirmation]).to include("入力したパスワードが一致しません")
      end
    end
  end
end