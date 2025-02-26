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
        expect(user.errors[:password]).to include("パスワードは英字と数字を含んだ8文字以上にしてください")
      end

      it "パスワードが英字・数字どちらも含んでいないと無効" do
        user.password = "password"
        user.password_confirmation = "password"
        expect(user).not_to be_valid
        expect(user.errors[:password]).to include("パスワードは英字と数字を含んだ8文字以上にしてください")
      end

      it "パスワードと確認用パスワードが一致しないと無効" do
        user.password_confirmation = "DifferentPassword1"
        expect(user).not_to be_valid
        expect(user.errors[:password_confirmation]).to include("入力したパスワードが一致しません")
      end
    end
  end
end
