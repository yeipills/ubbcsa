# app/models/concerns/progreso_concern.rb
module ProgresoConcern
  extend ActiveSupport::Concern

  included do
    def calcular_progreso
      Rails.cache.fetch("#{cache_key}/progreso", expires_in: 1.minute) do
        ProgressCalculator.new(self).calculate
      end
    end
  end
end