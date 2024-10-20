class Enrollment < ApplicationRecord
  belongs_to :user
  belongs_to :course
  has_many :course_progresses, dependent: :destroy

  validates :user_id, :course_id, presence: true
end
