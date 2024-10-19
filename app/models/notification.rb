class Notification < ApplicationRecord
  belongs_to :user

  validates :mensaje, presence: true
end
