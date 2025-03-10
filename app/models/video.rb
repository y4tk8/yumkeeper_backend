class Video < ApplicationRecord
  belongs_to :recipe

  enum :status, { public: "public", private: "private", unlisted: "unlisted" }, prefix: true
end
