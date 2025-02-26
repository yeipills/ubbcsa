# app/controllers/admin/dashboard_controller.rb
module Admin
  class DashboardController < Admin::BaseController
    def index
      @total_usuarios = Usuario.count
      @total_laboratorios = Laboratorio.count
      @sesiones_activas = SesionLaboratorio.active.count
      @metricas_sistema = MetricsService.system_metrics
    end
  end
end
