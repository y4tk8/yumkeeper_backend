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
        post "/api/v1/auth", params: valid_params

        expect(response).to have_http_status(:ok)
      end

      it "Usersテーブルのレコードが1増える" do
        expect {
          post "/api/v1/auth", params: valid_params
        }.to change { User.count }.by(1)
      end

      it "アカウント認証メールが送信される" do
        expect {
          post "/api/v1/auth", params: valid_params
        }.to change { ActionMailer::Base.deliveries.count }.by(1)
      end
    end

    context "重複するメールアドレスがDBに存在する場合" do
      it "リクエストが失敗し、ステータス422が返る" do
        create(:user, email: valid_params[:email])

        post "/api/v1/auth", params: valid_params

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.parsed_body["errors"]["email"]).to include("入力したメールアドレスはすでに存在します")
      end
    end

    context "パスワードが8文字未満 または 確認用パスワードと一致しない場合" do
      it "エラーメッセージと共に、ステータス422が返る（パスワードが8文字未満）" do
        post "/api/v1/auth", params: { email: "test@example.com", password: "Pass1", password_confirmation: "Pass1" }

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.parsed_body["errors"]["password"]).to include("パスワードは英字と数字を含んだ8文字以上にしてください")
      end

      it "エラーメッセージと共に、ステータス422が返る（確認用パスワードと不一致）" do
        post "/api/v1/auth", params: { email: "test@example.com", password: "Password1", password_confirmation: "DifferentPass1" }

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
        post "/api/v1/auth/sign_in", params: { email: user.email, password: user.password }

        expect(response).to have_http_status(:ok)
        expect(response.headers["access-token"]).to be_present
        expect(response.headers["client"]).to be_present
        expect(response.headers["uid"]).to eq(user.email)
      end
    end

    context "誤ったメールアドレス または パスワードの場合" do
      it "サインインに失敗し、ステータス401が返る（誤ったメールアドレス）" do
        post "/api/v1/auth/sign_in", params: { email: "wrong_email@example.com", password: user.password }

        expect(response).to have_http_status(:unauthorized)
        expect(response.parsed_body["errors"]).to include("ログイン用の認証情報が正しくありません。再度お試しください。")
      end

      it "サインインに失敗し、ステータス401が返る（誤ったパスワード）" do
        post "/api/v1/auth/sign_in", params: { email: user.email, password: "wrong_password" }

        expect(response).to have_http_status(:unauthorized)
        expect(response.parsed_body["errors"]).to include("ログイン用の認証情報が正しくありません。再度お試しください。")
      end
    end

    context "メール認証が完了していない場合" do
      let(:unconfirmed_user) { create(:user, confirmed_at: nil) }

      it "サインインが失敗し、ステータス401が返る" do
        post "/api/v1/auth/sign_in", params: { email: unconfirmed_user.email, password: unconfirmed_user.password }

        expect(response).to have_http_status(:unauthorized)
        expect(response.parsed_body["errors"]).to include("ログイン用の認証情報が正しくありません。再度お試しください。")
      end
    end

    context "退会済みユーザーの場合" do
      let(:deleted_user) { create(:user, :deleted) } # confirmed_at はあえてnilにせずテスト

      it "サインインが失敗し、ステータス401が返る" do
        post "/api/v1/auth/sign_in", params: { email: deleted_user.email, password: deleted_user.password }

        expect(response).to have_http_status(:unauthorized)
        expect(response.parsed_body["errors"]).to include("ログイン用の認証情報が正しくありません。再度お試しください。")
      end
    end
  end

  # ユーザーのサインアウト
  describe "DELETE /api/v1/auth/sign_out" do
    let(:user) { create(:user, :confirmed) }

    # サインインで認証情報をレスポンスとして取得
    let(:headers) do
      post "/api/v1/auth/sign_in", params: { email: user.email, password: user.password }
      {
        "access-token" => response.headers["access-token"],
        "client" => response.headers["client"],
        "uid" => response.headers["uid"]
      }
    end

    context "認証情報が正しい場合" do
      it "サインアウトが成功し、ステータス200が返る" do
        delete "/api/v1/auth/sign_out", headers: headers

        expect(response).to have_http_status(:ok)
        expect(response.parsed_body["success"]).to be true
      end

      it "サインアウト後、ユーザーのtokensカラムが空になる" do
        delete "/api/v1/auth/sign_out", headers: headers

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

    let(:headers) do
      # サインインで認証情報をレスポンスとして取得
      post "/api/v1/auth/sign_in", params: { email: user.email, password: user.password }
      {
        "access-token" => response.headers["access-token"],
        "client" => response.headers["client"],
        "uid" => response.headers["uid"]
      }
    end

    context "認証情報が正しい場合" do
      it "退会処理が成功し、ステータス200が返る" do
        delete "/api/v1/auth", headers: headers

        expect(response).to have_http_status(:ok)
        expect(response.parsed_body["message"]).to include("退会処理が正常に完了しました。")
      end

      it "ユーザーのアカウントが論理削除される" do
        delete "/api/v1/auth", headers: headers

        user.reload
        expect(user.is_deleted).to be true
        expect(user.confirmed_at).to be_nil
        expect(user.tokens).to be_empty
      end
    end

    context "認証情報がない、または間違っている場合" do
      it "退会処理に失敗し、ステータス404が返る（認証情報がない）" do
        delete "/api/v1/auth"

        expect(response).to have_http_status(:not_found)
        expect(response.parsed_body["message"]).to include("ユーザーが見つかりません。")
      end

      it "退会処理に失敗し、ステータス404が返る（認証情報が間違っている）" do
        invalid_headers = {
          "access-token" => "invalid_token",
          "client" => "invalid_client",
          "uid" => "invalid_uid@example.com"
        }

        delete "/api/v1/auth", headers: invalid_headers

        expect(response).to have_http_status(:not_found)
        expect(response.parsed_body["message"]).to include("ユーザーが見つかりません。")
      end
    end
  end
end
