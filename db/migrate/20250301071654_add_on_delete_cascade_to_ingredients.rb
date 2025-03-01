class AddOnDeleteCascadeToIngredients < ActiveRecord::Migration[7.2]
  def change
    remove_foreign_key :ingredients, :recipes
    add_foreign_key :ingredients, :recipes, on_delete: :cascade
  end
end
