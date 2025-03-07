class AddIndexesAndConstraintsToVideos < ActiveRecord::Migration[7.2]
  def change
    add_index :videos, [:status, :is_embeddable, :is_deleted], name: 'index_videos_on_status_embeddable_deleted'
  end
end
