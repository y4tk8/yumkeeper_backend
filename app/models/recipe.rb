class Recipe < ApplicationRecord
  belongs_to :user
  has_many :ingredients, dependent: :destroy

  validates :name, presence: true, length: { maximum: 100 }
end
