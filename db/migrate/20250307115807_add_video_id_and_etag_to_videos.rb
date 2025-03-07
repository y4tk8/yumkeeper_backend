class AddVideoIdAndEtagToVideos < ActiveRecord::Migration[7.2]
  def change
    add_column :videos, :video_id, :string, limit: 11, null: false
    add_column :videos, :etag, :string, limit: 255

    add_index :videos, :video_id
  end
end
