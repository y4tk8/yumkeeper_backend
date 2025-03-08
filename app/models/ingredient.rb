class Ingredient < ApplicationRecord
  belongs_to :recipe

  # decimal型の quantity を整数で返せるようオーバーライド
  def serializable_hash(options = {})
    super(options).merge(
      "quantity" => quantity.nil? ? nil : (quantity % 1 == 0 ? quantity.to_i : quantity.to_f)
    )
  end
end
