class Recipe < ApplicationRecord
  belongs_to :user
  has_many   :ingredients, dependent: :destroy
  has_one    :video,       dependent: :destroy
  accepts_nested_attributes_for :ingredients, allow_destroy: true
  accepts_nested_attributes_for :video,       allow_destroy: true

  validates :name, presence: true, length: { maximum: 100 }
end
