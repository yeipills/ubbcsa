class WettyController < ApplicationController
  before_action :authenticate_usuario!
  before_action :set_sesion
  before_action :verificar_acceso
  
  def show
    @wetty_url = generate_wetty_url
    # Generar token seguro para autenticación de sesión
    @token = generate_session_token
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
    # Detectar entorno - Docker vs host local
    host = request.host
    protocol = request.protocol.gsub("://", "")
    
    # En desarrollo, usamos la configuración directa para acceder a Wetty
    if Rails.env.development?
      # Usar el mismo host que la aplicación web, pero con el puerto de wetty
      # Esto asegura que el usuario pueda acceder a wetty desde su navegador
      port = "3001"
    else
      # En producción, usamos el mismo puerto que la aplicación
      port = request.port.to_s
    end
    
    # Incluimos la información del contenedor
    container_id = @sesion.container_id || 'no-container'
    username = current_usuario.email.split('@').first.gsub(/[^a-zA-Z0-9]/, '') # Sanitizar username
    
    # Crear/actualizar usuario en el contenedor si es necesario
    if @sesion.container_id.present?
      Rails.logger.info("Preparando usuario #{username} para contenedor #{container_id}")
      # Enviar variables de entorno para la creación del usuario en el contenedor
      user_id = current_usuario.id
      session_id = @sesion.id
    end
    
    Rails.logger.info("Generando URL Wetty con: host=#{host}, port=#{port}, protocol=#{protocol}")
    
    # URL con token de sesión seguro para mantener la autenticación
    # Se asegura que la URL sea accesible desde el navegador del usuario
    "#{protocol}://#{host}:#{port}/wetty?token=#{@token}&containerId=#{container_id}&username=#{username}"
  end
  
  def generate_session_token
    # Generar token único para esta sesión
    token = SecureRandom.urlsafe_base64(32)
    # Almacenar token en caché con tiempo de expiración (30 minutos)
    Rails.cache.write("wetty_token:#{token}", {
      usuario_id: current_usuario.id,
      sesion_id: @sesion.id,
      container_id: @sesion.container_id
    }, expires_in: 30.minutes)
    
    token
  end
end