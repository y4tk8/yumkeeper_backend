class AddIndexToUsersOnConfirmedAtAndIsDeleted < ActiveRecord::Migration[7.2]
  def change
    add_index :users, [:confirmed_at, :is_deleted], name: "index_users_on_confirmed_at_and_is_deleted"
  end
end
