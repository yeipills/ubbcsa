class Friend < ApplicationRecord
  belongs_to :user
  belongs_to :friend, class_name: 'User'
  belongs_to :status, class_name: 'FriendStatus'

  validates :user_id, :friend_id, :status_id, presence: true
  validates :user_id, uniqueness: { scope: :friend_id }
end
