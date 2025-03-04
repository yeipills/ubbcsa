# app/controllers/dashboard_controller.rb
class DashboardController < ApplicationController
  before_action :authenticate_usuario!
  before_action :set_cache_headers

  def index
    @data = DashboardService.new(current_usuario).load_data
    @laboratorios_activos = @data[:laboratorios_activos]
    @sesiones_recientes = @data[:sesiones_recientes]
    @laboratorios_disponibles = @data[:laboratorios_disponibles]
    @estadisticas = @data[:estadisticas]
    @cursos = @data[:cursos]
    @laboratorios = @data[:laboratorios]
    @progreso = @data[:progreso]
  rescue StandardError => e
    handle_error(e)
    set_empty_data
  end

  private

  def set_empty_data
    @estadisticas = {
      sesiones_activas: 0,
      laboratorios_completados: 0,
      cursos_inscritos: 0
    }
    @laboratorios_activos = []
    @sesiones_recientes = []
    @laboratorios_disponibles = []
    @cursos = []
    @laboratorios = []
    @progreso = 0
  end

  def load_dashboard_data
    DashboardService.new(current_usuario).load_data
  end

  def empty_dashboard_data
    OpenStruct.new(
      laboratorios_activos: [],
      sesiones_recientes: [],
      laboratorios_disponibles: [],
      estadisticas: {
        sesiones_activas: 0,
        laboratorios_completados: 0,
        cursos_inscritos: 0
      },
      cursos: [],
      laboratorios: [],
      progreso: 0
    )
  end

  def set_cache_headers
    response.headers['Cache-Control'] = 'no-cache, no-store'
    response.headers['Pragma'] = 'no-cache'
    response.headers['Expires'] = 'Mon, 01 Jan 1990 00:00:00 GMT'
  end

  def handle_error(error)
    Rails.logger.error("Dashboard Error: #{error.class} - #{error.message}")
    Rails.logger.error(error.backtrace.join("\n"))
    flash.now[:alert] = t('dashboard.errors.load_failed', default: 'Hubo un problema al cargar el dashboard')
  end
end
