class AddCachedAtToVideos < ActiveRecord::Migration[7.2]
  def change
    add_column :videos, :cached_at, :timestamp, null: false

    add_index :videos, :cached_at
  end
end
