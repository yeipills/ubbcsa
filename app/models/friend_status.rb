class FriendStatus < ApplicationRecord
  has_many :friends

  validates :status, presence: true, uniqueness: true
end
