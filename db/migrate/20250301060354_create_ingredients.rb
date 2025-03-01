class CreateIngredients < ActiveRecord::Migration[7.2]
  def change
    create_table :ingredients do |t|
      t.references :recipe, null: false, foreign_key: true
      t.string :name, limit: 50, null: false
      t.decimal :quantity, precision: 6, scale: 3
      t.string :unit, limit: 20
      t.string :category, limit: 20, null: false

      t.timestamps
    end
  end
end
