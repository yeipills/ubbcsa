# app/controllers/api/terminal_controller.rb
module Api
  class TerminalController < ApplicationController
    skip_before_action :verify_authenticity_token, only: [:validate_token, :metrics, :command, :ping]
    before_action :authenticate_usuario!, except: [:validate_token, :ping]
    
    # Endpoint para verificar estado de la API
    def ping
      render json: { status: 'ok', timestamp: Time.current }
    end
    
    # Validación de token para ttyd
    def validate_token
      # Normalización de parámetros desde cualquier formato (JSON, params)
      normalize_parameters
      
      token = params[:token]
      container_id = params[:container_id] || params[:containerId]
      username = params[:username]
      
      # Registrar información detallada para depuración
      log_validation_attempt(token, container_id, username, nil)
      
      # Modo de desarrollo para pruebas
      if Rails.env.development? && !Rails.env.test?
        handle_development_mode(username, nil, nil, nil)
        return
      end
      
      # Validar token en producción - para ttyd el formato es "username-sesion_id-timestamp"
      validate_ttyd_token(token)
    end
    
    # Obtener métricas de un contenedor/sesión
    def metrics
      session_id = params[:session_id]
      
      # Verificar acceso a sesión
      authorize_session_access(session_id)
      
      # Obtener métricas
      metrics = collect_metrics(session_id)
      
      render json: metrics
    rescue => e
      render json: { error: e.message }, status: :internal_server_error
    end
    
    # Ejecutar comando en contenedor principal
    def command
      session_id = params[:session_id]
      command = params[:command]
      
      # Verificar parámetros
      if session_id.blank? || command.blank?
        return render json: { error: 'Faltan parámetros requeridos' }, status: :bad_request
      end
      
      # Verificar acceso a sesión
      authorize_session_access(session_id)
      
      # Ejecutar comando
      result = execute_command_in_container(session_id, command)
      
      render json: result
    rescue => e
      render json: { error: e.message }, status: :internal_server_error
    end
    
    # Ejecutar comando en máquina objetivo
    def execute_on_target
      session_id = params[:session_id]
      target_name = params[:target_name]
      command = params[:command]
      
      # Verificar parámetros
      if session_id.blank? || target_name.blank? || command.blank?
        return render json: { error: 'Faltan parámetros requeridos' }, status: :bad_request
      end
      
      # Verificar acceso a sesión
      authorize_session_access(session_id)
      
      # Ejecutar comando en objetivo
      result = execute_command_on_target_machine(session_id, target_name, command)
      
      render json: result
    rescue => e
      render json: { error: e.message }, status: :internal_server_error
    end
    
    # Desplegar nueva máquina objetivo
    def deploy_target
      session_id = params[:session_id]
      target_type = params[:target_type]
      
      # Verificar parámetros
      if session_id.blank? || target_type.blank?
        return render json: { error: 'Faltan parámetros requeridos' }, status: :bad_request
      end
      
      # Verificar acceso a sesión
      authorize_session_access(session_id)
      
      # Intentar desplegar objetivo
      result = deploy_target_machine(session_id, target_type)
      
      render json: result
    rescue => e
      render json: { error: e.message }, status: :internal_server_error
    end
    
    # Reiniciar máquina objetivo
    def restart_target
      session_id = params[:session_id]
      target_name = params[:target_name]
      
      # Verificar parámetros
      if session_id.blank? || target_name.blank?
        return render json: { error: 'Faltan parámetros requeridos' }, status: :bad_request
      end
      
      # Verificar acceso a sesión
      authorize_session_access(session_id)
      
      # Reiniciar máquina objetivo
      result = restart_target_machine(session_id, target_name)
      
      render json: result
    rescue => e
      render json: { error: e.message }, status: :internal_server_error
    end
    
    # Listar objetivos disponibles
    def list_targets
      session_id = params[:session_id]
      
      # Verificar parámetros
      if session_id.blank?
        return render json: { error: 'Falta ID de sesión' }, status: :bad_request
      end
      
      # Verificar acceso a sesión
      authorize_session_access(session_id)
      
      # Obtener lista de objetivos
      targets = get_available_targets(session_id)
      
      render json: { success: true, targets: targets }
    rescue => e
      render json: { error: e.message }, status: :internal_server_error
    end
    
    private
    
    def normalize_parameters
      # Extraer parámetros de JSON en el body si es necesario
      if request.post? && request.headers['Content-Type'] =~ /json/
        begin
          json_params = JSON.parse(request.body.read)
          # Fusionar con params existentes, priorizando los existentes
          json_params.each do |key, value|
            params[key] ||= value
          end
          # Compatibilidad con diferentes formatos
          params[:container_id] ||= params[:containerId] || json_params['containerId']
        rescue => e
          Rails.logger.error("Error al parsear JSON del body: #{e.message}")
        end
      end
    end
    
    def log_validation_attempt(token, container_id, username, session_id)
      headers_debug = request.headers.env.select { |k, v| k.start_with?('HTTP_') }.to_json
      Rails.logger.info("Validando token: #{token}, container_id: #{container_id}, username: #{username}, session_id: #{session_id}, IP: #{request.remote_ip}")
      Rails.logger.debug("Headers de conexión: #{headers_debug}")
    end
    
    def handle_development_mode(username, user_id, lab_id, session_id)
      Rails.logger.info("Modo desarrollo: acceso permitido")
      render json: {
        valid: true,
        username: username || 'kali',
        user_id: user_id || 1,
        session_id: session_id || 1,
        lab_id: lab_id || 1
      }
    end
    
    def validate_ttyd_token(token)
      Rails.logger.info("Validando token para ttyd: #{token}")
      
      # En modo desarrollo, permitir siempre el acceso sin token
      if Rails.env.development?
        Rails.logger.info("Modo desarrollo: acceso permitido sin validación de token")
        return render json: {
          valid: true,
          username: 'kali',
          session_id: params[:session_id] || '1',
          container_id: params[:container_id] || 'local-dev'
        }
      end
      
      return render json: { valid: false, error: 'Token no proporcionado' }, status: :unauthorized unless token.present?
      
      # Buscar token en la caché
      cached_data = Rails.cache.read("ttyd_token:#{token}")
      Rails.logger.info("Datos de caché ttyd: #{cached_data.inspect}")
      
      if cached_data.present?
        # Token válido, obtener datos
        username = cached_data[:username]
        session_id = cached_data[:session_id]
        
        # Buscar sesión
        sesion = SesionLaboratorio.find_by(id: session_id)
        
        if sesion.present?
          # Verificar que el contenedor existe
          if sesion.container_id.present? && check_container_status(sesion.container_id) == 'running'
            render json: {
              valid: true,
              username: username,
              session_id: session_id,
              container_id: sesion.container_id
            }
          else
            render json: { valid: true, username: 'kali' }
          end
        else
          render json: { valid: true, username: 'kali' }
        end
      else
        # Verificar si es red local en desarrollo
        is_local_request = Rails.env.development? || 
                          request.remote_ip == '127.0.0.1' || 
                          request.remote_ip.start_with?('172.')
        
        if is_local_request
          render json: {
            valid: true,
            username: 'kali',
            session_id: params[:session_id] || '1',
            container_id: params[:container_id] || 'local-dev'
          }
        else
          render json: { valid: false, error: 'Token inválido o expirado' }, status: :unauthorized
        end
      end
    end
    
    def handle_valid_token(cached_data, container_id, username)
      # Token válido, obtener datos
      usuario = Usuario.find_by(id: cached_data[:usuario_id])
      sesion = SesionLaboratorio.find_by(id: cached_data[:sesion_id])
      
      if usuario && sesion
        # Derivar nombre de usuario
        username ||= sanitize_username(usuario.email)
        
        # Crear usuario en contenedor si es necesario
        if container_id.present? && container_id != 'no-container'
          ensure_user_exists_in_container(container_id, username, usuario.id, sesion.id)
        end
        
        render json: {
          valid: true,
          username: username,
          user_id: usuario.id,
          session_id: sesion.id,
          lab_id: sesion.laboratorio_id
        }
      else
        render json: { valid: false, error: 'Datos de sesión inválidos' }, status: :unauthorized
      end
    end
    
    def handle_local_request(username, user_id, session_id, lab_id)
      Rails.logger.info("Acceso desde red local permitido con usuario '#{username || 'kali'}'")
      render json: {
        valid: true,
        username: username || 'kali',
        user_id: user_id || 1,
        session_id: session_id || 1,
        lab_id: lab_id || 1
      }
    end
    
    def sanitize_username(email)
      # Sanitizar nombre de usuario
      username = email.split('@').first
      username.gsub(/[^a-zA-Z0-9]/, '')
    end
    
    def ensure_user_exists_in_container(container_id, username, user_id, session_id)
      begin
        create_dynamic_user(container_id, username, user_id, session_id)
      rescue => e
        Rails.logger.error("Error creando usuario dinámico (no fatal): #{e.message}")
      end
    end
    
    def authorize_session_access(session_id)
      sesion = SesionLaboratorio.find_by(id: session_id)
      
      # Verificar si la sesión existe
      unless sesion.present?
        raise "Sesión no encontrada: #{session_id}"
      end
      
      # Verificar permisos según el rol
      if current_usuario.admin?
        # Los administradores tienen acceso completo a todas las sesiones
        return sesion
      elsif current_usuario.profesor?
        # Los profesores solo pueden acceder a sesiones de sus cursos
        curso = sesion.laboratorio.curso
        unless curso.profesor_id == current_usuario.id
          raise "Acceso no autorizado: el profesor no es dueño del curso"
        end
      else
        # Los estudiantes solo pueden acceder a sus propias sesiones
        unless sesion.usuario_id == current_usuario.id
          raise "Acceso no autorizado: la sesión no pertenece a este usuario"
        end
      end
      
      sesion
    end
    
    def collect_metrics(session_id)
      sesion = SesionLaboratorio.find_by(id: session_id)
      
      # Obtener métricas del servicio más adecuado
      metrics = if defined?(DockerLabService) && DockerLabService.respond_to?(:get_metrics)
        DockerLabService.get_metrics(sesion)
      else 
        MetricsService.collect_metrics(sesion)
      end
      
      # Asegurar formato consistente
      metrics.is_a?(Hash) ? metrics : {}
    end
    
    def execute_command_in_container(session_id, command)
      sesion = SesionLaboratorio.find_by(id: session_id)
      
      if sesion && sesion.container_id.present?
        DockerLabService.execute_command(sesion, command)
      else
        { success: false, output: 'Contenedor no disponible para esta sesión' }
      end
    end
    
    def execute_command_on_target_machine(session_id, target_name, command)
      sesion = SesionLaboratorio.find_by(id: session_id)
      
      if sesion && sesion.resource_usage.is_a?(Hash) && 
         sesion.resource_usage['targets'].is_a?(Hash) &&
         sesion.resource_usage['targets'][target_name].present?
        
        DockerLabService.execute_command_on_target(sesion, target_name, command)
      else
        { success: false, output: 'Máquina objetivo no disponible' }
      end
    end
    
    def deploy_target_machine(session_id, target_type)
      sesion = SesionLaboratorio.find_by(id: session_id)
      
      if DockerLabService.create_custom_target(sesion, target_type)
        { success: true, message: "Máquina objetivo #{target_type} desplegada correctamente" }
      else
        { success: false, error: "No se pudo desplegar la máquina objetivo #{target_type}" }
      end
    end
    
    def restart_target_machine(session_id, target_name)
      sesion = SesionLaboratorio.find_by(id: session_id)
      
      # Verificar existencia del target
      unless sesion.resource_usage.is_a?(Hash) && 
             sesion.resource_usage['targets'].is_a?(Hash) && 
             sesion.resource_usage['targets'][target_name].present?
        return { success: false, error: "Máquina objetivo no encontrada" }
      end
      
      # Obtener ID del contenedor
      container_id = sesion.resource_usage['targets'][target_name]['container_id']
      unless container_id.present?
        return { success: false, error: "ID de contenedor no disponible" }
      end
      
      # Reiniciar contenedor
      result = `docker restart #{container_id} 2>&1`
      success = $?.success?
      
      if success
        { success: true, message: "Máquina objetivo reiniciada correctamente" }
      else
        { success: false, error: "Error al reiniciar máquina objetivo: #{result}" }
      end
    end
    
    def get_available_targets(session_id)
      sesion = SesionLaboratorio.find_by(id: session_id)
      DockerLabService.list_targets(sesion)
    end
    
    def create_dynamic_user(container_id, username, user_id, session_id)
      return unless container_id.present? && container_id != 'no-container'
      
      # Comando para crear usuario en el contenedor
      cmd = "docker exec #{container_id} /usr/local/bin/create_dynamic_user.sh #{username} #{user_id} #{session_id}"
      Rails.logger.info("Ejecutando: #{cmd}")
      
      result = `#{cmd} 2>&1`
      success = $?.success?
      
      if success
        Rails.logger.info("Usuario #{username} creado en contenedor #{container_id}")
      else
        Rails.logger.error("Error creando usuario en contenedor: #{result}")
        raise "Error creando usuario: #{result}"
      end
    end
  end
end