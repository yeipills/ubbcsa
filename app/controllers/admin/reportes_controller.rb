# app/controllers/admin/reportes_controller.rb
class Admin::ReportesController < ApplicationController
  before_action :authenticate_admin!

  def index
    @periodo = params[:periodo] || 'month'
    @categoria = params[:categoria]
    
    @metricas = MetricsService.new
    @estadisticas = @metricas.get_system_stats(@periodo, @categoria)
    @top_laboratorios = Laboratorio.top_utilizados(@periodo)
    @rendimiento_usuarios = Usuario.rendimiento_general(@periodo)
  end
end