class RemoveCheckConfirmationTimes < ActiveRecord::Migration[7.2]
  def change
    # アカウント認証メール再送信に適応するため制約を削除
    remove_check_constraint :users, name: "check_confirmation_times"
  end
end
