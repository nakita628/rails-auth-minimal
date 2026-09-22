class User < ApplicationRecord
  validates :email_address, presence: true, uniqueness: true
  validates :password_digest, presence: { if: :password }

  has_many :sessions, dependent: :destroy

  has_secure_password
  normalizes :email_address, with: ->(e) { e.strip.downcase }
end
