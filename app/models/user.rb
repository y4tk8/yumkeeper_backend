# frozen_string_literal: true

class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :lockable, :timeoutable, :trackable, :omniauthable, :rememberable
  devise :database_authenticatable, :registerable,
          :recoverable, :validatable, :confirmable

  include DeviseTokenAuth::Concerns::User
end
