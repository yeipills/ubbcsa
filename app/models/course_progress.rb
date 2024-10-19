class CourseProgress < ApplicationRecord
  belongs_to :enrollment

  validates :progress_percent, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }
  validates :horas_aprendidas, numericality: { greater_than_or_equal_to: 0 }
end
