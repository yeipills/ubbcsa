class WettyController < ApplicationController
  before_action :authenticate_usuario!
  before_action :set_sesion
  before_action :verificar_acceso
  
  def show
    @wetty_url = generate_wetty_url
    render layout: false
  end

  private

  def set_sesion
    @sesion = SesionLaboratorio.find(params[:sesion_laboratorio_id])
  end

  def verificar_acceso
    unless @sesion.usuario == current_usuario
      redirect_to root_path, alert: 'No tienes acceso a esta sesión'
    end
  end

  def generate_wetty_url
    port = Rails.env.development? ? 3001 : 443
    "http://localhost:#{port}/wetty"
  end
end