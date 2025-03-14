# app/controllers/consola_controller.rb
class ConsolaController < ApplicationController
  before_action :authenticate_usuario!
  before_action :set_sesion_laboratorio
  before_action :verify_access
  
  def show
    @sesion = @sesion_laboratorio
    @metricas = obtener_metricas
    @ejercicios = @sesion_laboratorio.laboratorio&.ejercicios || []
    @historial_comandos = obtener_historial_comandos
  end

  private

  def set_sesion_laboratorio
    @sesion_laboratorio = SesionLaboratorio.find(params[:sesion_laboratorio_id])
  end

  def verify_access
    unless @sesion_laboratorio.usuario == current_usuario
      redirect_to dashboard_path, alert: 'No tienes acceso a esta consola'
    end
  end

  def obtener_metricas
    return {} unless @sesion_laboratorio&.container_id
    
    # Intentar obtener métricas actuales
    begin
      DockerLabService.get_metrics(@sesion_laboratorio)
    rescue => e
      Rails.logger.error("Error obteniendo métricas: #{e.message}")
      {}
    end
  end
  
  def obtener_historial_comandos
    # Obtener últimos 20 comandos ejecutados
    LogTerminal.where(
      sesion_laboratorio: @sesion_laboratorio,
      tipo: ['comando', 'resultado', 'error']
    ).order(created_at: :desc).limit(20)
  end
end