# app/models/concerns/metricas_concern.rb
module MetricasConcern
  extend ActiveSupport::Concern

  included do
    def get_cpu_usage
      Rails.cache.fetch("#{cache_key}/cpu_usage", expires_in: 5.seconds) do
        if defined?(MetricsService) && respond_to?(:container_id) && container_id.present?
          metrics = MetricsService.new(self).collect_metrics
          metrics[:cpu_usage]
        else
          0.0
        end
      end
    end

    def get_memory_usage
      Rails.cache.fetch("#{cache_key}/memory_usage", expires_in: 5.seconds) do
        if defined?(MetricsService) && respond_to?(:container_id) && container_id.present?
          metrics = MetricsService.new(self).collect_metrics
          metrics[:memory_usage]
        else
          0.0
        end
      end
    end

    def get_network_usage
      Rails.cache.fetch("#{cache_key}/network_usage", expires_in: 5.seconds) do
        if defined?(MetricsService) && respond_to?(:container_id) && container_id.present?
          metrics = MetricsService.new(self).collect_metrics
          metrics[:network_usage]
        else
          0.0
        end
      end
    end
    
    # Obtener todas las métricas en una sola llamada
    def get_all_metrics
      Rails.cache.fetch("#{cache_key}/all_metrics", expires_in: 5.seconds) do
        if defined?(MetricsService) && respond_to?(:container_id) && container_id.present?
          MetricsService.new(self).collect_metrics
        else
          {
            cpu_usage: 0.0,
            memory_usage: 0.0,
            network_usage: 0.0,
            timestamp: Time.current
          }
        end
      end
    end
    
    # Obtener el historial de métricas
    def get_metric_history(limit = 20)
      if self.respond_to?(:metrica_laboratorios)
        self.metrica_laboratorios.order(created_at: :desc).limit(limit)
      else
        []
      end
    end
  end
end