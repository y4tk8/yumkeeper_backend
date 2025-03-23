require "rails_helper"

RSpec.describe "Delete User Account", type: :request do
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
end
