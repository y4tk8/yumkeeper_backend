class RemoveIsActivatedFromUsers < ActiveRecord::Migration[7.2]
  def change
    remove_column :users, :is_activated, :boolean
  end
end
