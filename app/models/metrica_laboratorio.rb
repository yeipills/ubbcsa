# app/models/metrica_laboratorio.rb
class MetricaLaboratorio < ApplicationRecord
  belongs_to :laboratorio
  belongs_to :sesion_laboratorio

  after_create :broadcast_metric

  validates :cpu_usage, presence: true
  validates :memory_usage, presence: true
  validates :network_usage, presence: true
  validates :timestamp, presence: true
  
  private

  def broadcast_metric
    MetricsChannel.broadcast_to(
      sesion_laboratorio,
      {
        type: 'metric',
        cpu: cpu_usage,
        memory: memory_usage,
        network: network_usage,
        timestamp: created_at
      }
    )
  end
end