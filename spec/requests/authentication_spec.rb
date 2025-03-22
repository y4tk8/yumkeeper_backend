require "rails_helper"

RSpec.describe "User Authentication", type: :request do
  # ユーザーのサインアップ
  describe "POST /api/v1/auth" do
    let(:valid_params) do
      {
        email: "test@example.com",
        password: "Password1",
        password_confirmation: "Password1"
      }
    end

    context "正しいメールアドレス、パスワード、確認用パスワードの場合" do
      it "サインアップが成功し、ステータス200が返る" do
        post "/api/v1/auth", params: valid_params, as: :json

        expect(response).to have_http_status(:ok)
      end

      it "Usersテーブルのレコードが1増える" do
        expect {
          post "/api/v1/auth", params: valid_params, as: :json
        }.to change { User.count }.by(1)
      end

      it "アカウント認証メールが送信される" do
        expect {
          post "/api/v1/auth", params: valid_params, as: :json
        }.to change { ActionMailer::Base.deliveries.count }.by(1)
      end
    end

    context "重複するメールアドレスがDBに存在する場合" do
      it "リクエストが失敗し、ステータス422が返る" do
        create(:user, email: valid_params[:email])

        post "/api/v1/auth", params: valid_params, as: :json

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.parsed_body["errors"]["email"]).to include("入力したメールアドレスはすでに存在します")
      end
    end

    context "パスワードが8文字未満 または 確認用パスワードと一致しない場合" do
      it "エラーメッセージと共に、ステータス422が返る（パスワードが8文字未満）" do
        post "/api/v1/auth", params: { email: "test@example.com", password: "Pass1", password_confirmation: "Pass1" }, as: :json

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.parsed_body["errors"]["password"]).to include("パスワードは英字と数字を含んだ8文字以上にしてください")
      end

      it "エラーメッセージと共に、ステータス422が返る（確認用パスワードと不一致）" do
        post "/api/v1/auth", params: { email: "test@example.com", password: "Password1", password_confirmation: "DifferentPass1" }, as: :json

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.parsed_body["errors"]["password_confirmation"]).to include("入力したパスワードが一致しません")
      end
    end
  end

  # ユーザーのサインイン
  describe "POST /api/v1/auth/sign_in" do
    let(:user) { create(:user, :confirmed) }

    context "正しいメールアドレスとパスワードの場合" do
      it "サインインが成功し、ステータス200が返る" do
        post "/api/v1/auth/sign_in", params: { email: user.email, password: user.password }, as: :json

        expect(response).to have_http_status(:ok)
        expect(response.headers["access-token"]).to be_present
        expect(response.headers["client"]).to be_present
        expect(response.headers["uid"]).to eq(user.email)
      end
    end

    context "誤ったメールアドレス または パスワードの場合" do
      it "サインインに失敗し、ステータス401が返る（誤ったメールアドレス）" do
        post "/api/v1/auth/sign_in", params: { email: "wrong_email@example.com", password: user.password }, as: :json

        expect(response).to have_http_status(:unauthorized)
        expect(response.parsed_body["errors"]).to include("ログイン用の認証情報が正しくありません。再度お試しください。")
      end

      it "サインインに失敗し、ステータス401が返る（誤ったパスワード）" do
        post "/api/v1/auth/sign_in", params: { email: user.email, password: "wrong_password" }, as: :json

        expect(response).to have_http_status(:unauthorized)
        expect(response.parsed_body["errors"]).to include("ログイン用の認証情報が正しくありません。再度お試しください。")
      end
    end

    context "メール認証が完了していない場合" do
      let(:unconfirmed_user) { create(:user, confirmed_at: nil) }

      it "サインインが失敗し、ステータス401が返る" do
        post "/api/v1/auth/sign_in", params: { email: unconfirmed_user.email, password: unconfirmed_user.password }, as: :json

        expect(response).to have_http_status(:unauthorized)
        expect(response.parsed_body["errors"]).to include("ログイン用の認証情報が正しくありません。再度お試しください。")
      end
    end

    context "退会済みユーザーの場合" do
      let(:deleted_user) { create(:user, :deleted) }

      it "サインインが失敗し、ステータス401が返る" do
        post "/api/v1/auth/sign_in", params: { email: deleted_user.email, password: deleted_user.password }, as: :json

        expect(response).to have_http_status(:unauthorized)
        expect(response.parsed_body["errors"]).to include("ログイン用の認証情報が正しくありません。再度お試しください。")
      end
    end
  end

  # ユーザーのサインアウト
  describe "DELETE /api/v1/auth/sign_out" do
    let(:user) { create(:user, :confirmed) }
    let(:auth_headers) { user.create_new_auth_token } # Devise Token Authの認証情報

    context "認証情報が正しい場合" do
      it "サインアウトが成功し、ステータス200が返る" do
        delete "/api/v1/auth/sign_out", headers: auth_headers

        expect(response).to have_http_status(:ok)
        expect(response.parsed_body["success"]).to be_truthy
      end

      it "サインアウト後、ユーザーのtokensカラムが空になる" do
        delete "/api/v1/auth/sign_out", headers: auth_headers

        user.reload
        expect(user.tokens).to be_empty
      end
    end

    context "認証情報がない、または間違っている場合" do
      it "サインアウトに失敗し、ステータス404が返る（認証情報がない）" do
        delete "/api/v1/auth/sign_out"

        expect(response).to have_http_status(:not_found)
        expect(response.parsed_body["errors"]).to include("ユーザーが見つからないか、ログインしていません。")
      end

      it "サインアウトに失敗し、ステータス404が返る（認証情報が間違っている）" do
        invalid_headers = {
          "access-token" => "invalid_token",
          "client" => "invalid_client",
          "uid" => "invalid_uid@example.com"
        }

        delete "/api/v1/auth/sign_out", headers: invalid_headers

        expect(response).to have_http_status(:not_found)
        expect(response.parsed_body["errors"]).to include("ユーザーが見つからないか、ログインしていません。")
      end
    end
  end

  # ユーザーの退会
  describe "DELETE /api/v1/auth" do
    let(:user) { create(:user, :confirmed) }
    let!(:recipes) { create_list(:recipe, 3, user: user) }
    let(:auth_headers) { user.create_new_auth_token } # Devise Token Authの認証情報

    context "認証情報が正しい場合" do
      it "退会処理が成功し、ステータス200が返る" do
        delete "/api/v1/auth", headers: auth_headers

        expect(response).to have_http_status(:ok)
        expect(response.parsed_body["message"]).to include("退会処理が正常に完了しました。")
      end

      it "ユーザーのアカウントが論理削除される" do
        delete "/api/v1/auth", headers: auth_headers

        user.reload
        expect(user.is_deleted).to be true
        expect(user.confirmed_at).to be_nil
        expect(user.tokens).to be_empty
      end

      it "関連するレシピが全て削除される" do
        expect { delete "/api/v1/auth", headers: auth_headers }.to change { Recipe.count }.by(-3)
      end
    end

    context "認証情報がない、または間違っている場合" do
      it "退会処理に失敗し、ステータス404が返る（認証情報がない）" do
        delete "/api/v1/auth"

        expect(response).to have_http_status(:not_found)
        expect(response.parsed_body["error"]).to include("ユーザーが見つかりません。")
      end

      it "退会処理に失敗し、ステータス404が返る（認証情報が間違っている）" do
        invalid_headers = {
          "access-token" => "invalid_token",
          "client" => "invalid_client",
          "uid" => "invalid_uid@example.com"
        }

        delete "/api/v1/auth", headers: invalid_headers

        expect(response).to have_http_status(:not_found)
        expect(response.parsed_body["error"]).to include("ユーザーが見つかりません。")
      end
    end

    context "トランザクション処理の確認" do
      before do
        allow_any_instance_of(User).to receive(:delete_recipes).and_raise(StandardError)
      end

      it "エラーが発生した場合、ユーザーは論理削除されない" do
        expect { delete "/api/v1/auth", headers: auth_headers }.not_to change { user.reload.is_deleted }
      end

      it "エラーが発生した場合、関連するレシピは削除されない" do
        expect { delete "/api/v1/auth", headers: auth_headers }.not_to change { Recipe.count }
      end

      it "退会処理に失敗し、ステータス500が返る" do
        delete "/api/v1/auth", headers: auth_headers

        expect(response).to have_http_status(:internal_server_error)
        expect(response.parsed_body["error"]).to include("退会処理に失敗しました。")
      end
    end
  end

  # アカウント認証メールを再送信
  # NOTE: セキュリティ観点（総当たり攻撃防止）から、すべて同様にステータス200を返す
  describe "POST /api/v1/auth/confirmation" do
    context "未認証ユーザーがリクエストした場合" do
      let(:unconfirmed_user) { create(:user, confirmed_at: nil) }

      it "認証メールが再送され、ステータス200が返る" do
        expect {
          post "/api/v1/auth/confirmation", params: { email: unconfirmed_user.email, redirect_url: "http://frontend.example.com/confirmation" }, as: :json
        }.to change { ActionMailer::Base.deliveries.count }.by(1)

        expect(response).to have_http_status(:ok)
        expect(response.parsed_body["message"]).to include("アカウント認証メールを再送しました。メールをご確認ください。")
      end
    end

    context "認証済みユーザーがリクエストした場合" do
      let(:user) { create(:user, :confirmed) }

      it "認証メールが送信され、ステータス200が返る" do
        expect {
          post "/api/v1/auth/confirmation", params: { email: user.email, redirect_url: "http://frontend.example.com/confirmation" }, as: :json
        }.to change { ActionMailer::Base.deliveries.count }.by(1)

        expect(response).to have_http_status(:ok)
        expect(response.parsed_body["message"]).to include("アカウント認証メールを再送しました。メールをご確認ください。")
      end
    end

    context "退会済みユーザーがリクエストした場合" do
      let(:deleted_user) { create(:user, :deleted, confirmed_at: nil) }

      it "認証メールが送信され、ステータス200が返る" do
        expect {
          post "/api/v1/auth/confirmation", params: { email: deleted_user.email, redirect: "http://frontend.example.com/confirmation" }, as: :json
        }.to change { ActionMailer::Base.deliveries.count }.by(1)

        expect(response).to have_http_status(:ok)
        expect(response.parsed_body["message"]).to include("アカウント認証メールを再送しました。メールをご確認ください。")
      end
    end

    context "存在しないメールアドレスを指定した場合" do
      it "認証メールは送信されず、ステータス200が返る" do
        expect {
          post "/api/v1/auth/confirmation", params: { email: "nonexistent@example.com", redirect: "http://frontend.example.com/confirmation" }, as: :json
        }.not_to change { ActionMailer::Base.deliveries.count }

        expect(response).to have_http_status(:ok)
        expect(response.parsed_body["message"]).to include("アカウント認証メールを再送しました。メールをご確認ください。")
      end
    end
  end
end
