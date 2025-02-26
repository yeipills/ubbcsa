# app/controllers/reportes_controller.rb
class ReportesController < ApplicationController
  before_action :authenticate_usuario!
  before_action :verify_can_view_reports

  def show
    @usuario = current_usuario
    @periodo = params[:periodo] || 'month'
    @metricas = MetricsService.new(@usuario).get_metrics_for(@periodo)
    @laboratorios_completados = @usuario.sesion_laboratorios.completed
    @habilidades_adquiridas = @usuario.habilidades_por_categoria
  end

  private

  def verify_can_view_reports
    verify_role_access(['profesor', 'admin'])
  end
end