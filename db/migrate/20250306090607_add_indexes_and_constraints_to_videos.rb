class AddIndexesAndConstraintsToVideos < ActiveRecord::Migration[7.2]
  def change
    add_index :videos, [:status, :is_embeddable, :is_deleted], name: 'index_videos_on_status_embeddable_deleted'
    add_index :videos, :cached_at, name: 'index_videos_on_cached_at'

    # cached_at が現在時刻以降であることをCHECK制約で制御
    execute <<-SQL
      ALTER TABLE videos ADD CONSTRAINT check_cached_at CHECK (cached_at >= NOW());
    SQL
  end
end
