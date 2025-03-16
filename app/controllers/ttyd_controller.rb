class TTYDController < ApplicationController
  # Este controlador maneja la integración con ttyd
  before_action :authenticate_usuario!
  before_action :set_sesion
  before_action :verificar_acceso
  before_action :verify_container_status
  
  def show
    @ttyd_url = generate_ttyd_url
    @token = generate_session_token
    @lab_config = get_lab_config
    render layout: false
  end

  private

  def set_sesion
    @sesion = SesionLaboratorio.find(params[:sesion_laboratorio_id])
  rescue ActiveRecord::RecordNotFound
    redirect_to root_path, alert: 'Sesión no encontrada'
  end

  def verificar_acceso
    unless @sesion.usuario == current_usuario || current_usuario.admin?
      redirect_to root_path, alert: 'No tienes acceso a esta sesión'
    end
  end
  
  def verify_container_status
    unless @sesion.container_id.present?
      redirect_to laboratorios_path, alert: 'No hay un contenedor activo para esta sesión. Inicia el laboratorio primero.'
      return
    end
    
    status = check_container_status(@sesion.container_id)
    
    case status
    when 'running'
      # El contenedor está en ejecución, continuar
      return
    when 'exited', 'created'
      # Intentar iniciar el contenedor
      if start_container(@sesion.container_id)
        flash.now[:notice] = 'El contenedor ha sido reiniciado'
        return
      else
        redirect_to laboratorio_path(@sesion.laboratorio), 
          alert: 'No se pudo iniciar el contenedor. Por favor, reinicia el laboratorio.'
        return
      end
    else
      # El contenedor no existe o está en un estado desconocido
      redirect_to laboratorio_path(@sesion.laboratorio), 
        alert: 'El contenedor no está disponible. Por favor, reinicia el laboratorio.'
      return
    end
  end

  def generate_ttyd_url
    # Configuración base de la URL según el entorno
    protocol = request.ssl? ? "https" : "http"
    host = determine_ttyd_host
    port = determine_ttyd_port
    
    # Parámetros para la autenticación y configuración de la sesión
    username = sanitize_username(current_usuario.email)
    container_id = @sesion.container_id || 'no-container'
    
    # Crear token para autorización
    session_token = "#{username}-#{@sesion.id}-#{Time.now.to_i}"
    # Guardar token en caché para validación
    Rails.cache.write("ttyd_token:#{session_token}", { username: username, session_id: @sesion.id }, expires_in: 1.hour)
    
    # Log para depuración
    Rails.logger.info("Generando URL ttyd: host=#{host}, port=#{port}, protocol=#{protocol}, container=#{container_id}")
    
    # URL directa a ttyd - asegurar que no hay /ttyd en la URL
    "#{protocol}://#{host}:#{port}/?token=#{session_token}&container_id=#{container_id}&username=#{username}"
  end
  
  def determine_ttyd_host
    if Rails.env.development?
      # En desarrollo usamos el host local
      request.host
    else
      # En producción usamos el host configurado o el mismo host de la aplicación
      ENV['TTYD_HOST'] || request.host
    end
  end
  
  def determine_ttyd_port
    if Rails.env.development?
      # Puerto específico para desarrollo
      "3000"
    else
      # En producción, puerto configurado o el mismo que la aplicación
      ENV['TTYD_PORT'] || request.port.to_s
    end
  end
  
  def sanitize_username(email)
    # Crear un nombre de usuario válido basado en el email
    username = email.split('@').first
    # Eliminar caracteres no alfanuméricos
    username.gsub(/[^a-zA-Z0-9]/, '')
  end

  def check_container_status(container_id)
    return 'unknown' if container_id.blank? || container_id == 'no-container'
    
    begin
      result = `docker inspect --format='{{.State.Status}}' #{container_id} 2>/dev/null`.strip
      return result.presence || 'not-found'
    rescue => e
      Rails.logger.error("Error verificando estado del contenedor: #{e.message}")
      return 'error'
    end
  end
  
  def start_container(container_id)
    return false if container_id.blank? || container_id == 'no-container'
    
    begin
      Rails.logger.info("Iniciando contenedor: #{container_id}")
      result = `docker start #{container_id} 2>&1`
      success = $?.success?
      
      if success
        # Verificar si realmente inició
        retries = 0
        while retries < 3
          sleep 1
          current_status = check_container_status(container_id)
          return true if current_status == 'running'
          retries += 1
        end
        
        Rails.logger.error("El contenedor no entró en estado 'running' después de iniciarlo")
        return false
      else
        Rails.logger.error("Error iniciando contenedor: #{result}")
        return false
      end
    rescue => e
      Rails.logger.error("Excepción iniciando contenedor: #{e.message}")
      return false
    end
  end
  
  def get_lab_config
    tipo = @sesion.laboratorio.tipo
    {
      nombre: @sesion.laboratorio.nombre,
      tipo: tipo,
      usuario: current_usuario.email,
      container_id: @sesion.container_id,
      session_id: @sesion.id,
      description: @sesion.laboratorio.descripcion
    }
  end
  
  def generate_session_token
    # Generar un token simple como identificador de sesión (no para autenticación)
    SecureRandom.hex(16)
  end
end