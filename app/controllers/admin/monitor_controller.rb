# app/controllers/admin/monitor_controller.rb
module Admin
  class MonitorController < Admin::BaseController
    def index
      @sesiones_activas = SesionLaboratorio.active
                                          .includes(:usuario, :laboratorio)
                                          .order(created_at: :desc)
      @metricas_sistema = SystemMetrics.current
      @alertas_recientes = SecurityAlert.recent.limit(10)
      @recursos_sistema = SystemResources.current_usage
    end

    def details
      @sesion = SesionLaboratorio.find(params[:id])
      @metricas_detalladas = @sesion.metricas_detalladas
      @actividad_usuario = @sesion.registro_actividad
    end
  end
end