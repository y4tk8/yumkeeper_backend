class CreateVideos < ActiveRecord::Migration[7.2]
  def change
    create_table :videos do |t|
      t.references :recipe, null: false, foreign_key: true
      t.text :thumbnail, null: false
      t.column :status, :video_status, null: false, default: "public"
      t.boolean :is_embeddable, null: false, default: true
      t.boolean :is_deleted, null: false, default: false

      t.timestamps
    end
  end
end
