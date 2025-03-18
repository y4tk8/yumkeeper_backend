class RemoveProfileImageUrlFromUsers < ActiveRecord::Migration[7.2]
  def change
    remove_column :users, :profile_image_url, :string
  end
end
