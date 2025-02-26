# app/models/concerns/metricas_concern.rb
module MetricasConcern
  extend ActiveSupport::Concern

  included do
    def get_cpu_usage
      Rails.cache.fetch("#{cache_key}/cpu_usage", expires_in: 5.seconds) do
        MetricsService.get_cpu_usage(self)
      end
    end

    def get_memory_usage
      Rails.cache.fetch("#{cache_key}/memory_usage", expires_in: 5.seconds) do
        MetricsService.get_memory_usage(self)
      end
    end

    def get_network_usage
      Rails.cache.fetch("#{cache_key}/network_usage", expires_in: 5.seconds) do
        MetricsService.get_network_usage(self)
      end
    end
  end
end