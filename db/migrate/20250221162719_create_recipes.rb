class CreateRecipes < ActiveRecord::Migration[7.2]
  def change
    create_table :recipes do |t|
      t.references :user, null: false, foreign_key: true
      t.string :name, null: false, limit: 100
      t.text :notes

      t.timestamps
    end
  end
end
