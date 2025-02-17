module Api
  module V1
    module Auth
      class PasswordsController < DeviseTokenAuth::PasswordsController

        private

        # 外部URLへのリダイレクトを許可する
        def redirect_options
          {
            allow_other_host: true
          }
        end
      end
    end
  end
end
