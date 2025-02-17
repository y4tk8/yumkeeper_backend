class ChangeAllowPasswordChangeDefault < ActiveRecord::Migration[7.2]
  def change
    change_column_default :users, :allow_password_change, false
  end
end
