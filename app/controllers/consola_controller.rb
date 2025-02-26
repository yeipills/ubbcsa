# app/controllers/consolas_controller.rb
class ConsolasController < ApplicationController
  before_action :authenticate_usuario!
  before_action :set_sesion_laboratorio
  before_action :verify_access
  
  def show
    @metricas = @sesion_laboratorio.metricas_actuales
    @ejercicios = @sesion_laboratorio.laboratorio.ejercicios_activos
    @terminal_url = generate_terminal_url
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

  def generate_terminal_url
    port = Rails.env.development? ? 3001 : 443
    "http://localhost:#{port}/wetty/#{@sesion_laboratorio.id}"
  end
end