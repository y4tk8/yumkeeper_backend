class AddCheckConstraintsToIngredients < ActiveRecord::Migration[7.2]
  def change
    # categoryは 'ingredient' または 'seasoning' のみ許可
    execute <<-SQL
      ALTER TABLE ingredients ADD CONSTRAINT check_category_valid CHECK (category IN ('ingredient', 'seasoning'));
    SQL
  end
end
