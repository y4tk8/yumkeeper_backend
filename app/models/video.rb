class Video < ApplicationRecord
  belongs_to :recipe, touch: true

  enum :status, { public: "public", private: "private", unlisted: "unlisted" }, prefix: true
end
