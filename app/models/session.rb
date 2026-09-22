class Session < ApplicationRecord
  belongs_to :user, inverse_of: :sessions

  scope :recent, -> { order(created_at: :desc, id: :desc) }
end
