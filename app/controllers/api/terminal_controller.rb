# app/controllers/api/terminal_controller.rb
module Api
  class TerminalController < ApplicationController
    skip_before_action :verify_authenticity_token, only: [:validate_token, :metrics]
    before_action :authenticate_usuario!, except: [:validate_token]
    
    def validate_token
      Rails.logger.info("Método: #{request.method}, Params: #{params.inspect}, Headers: #{request.headers['Content-Type']}")
      
      # En POST, los parámetros pueden venir en el body como JSON
      if request.post? && request.headers['Content-Type'] =~ /json/
        begin
          json_params = JSON.parse(request.body.read)
          params[:token] ||= json_params['token']
          params[:container_id] ||= json_params['container_id']
          params[:containerId] ||= json_params['containerId']
          params[:username] ||= json_params['username']
        rescue => e
          Rails.logger.error("Error al parsear JSON del body: #{e.message}")
        end
      end
      
      token = params[:token]
      container_id = params[:container_id]
      
      # Para compatibilidad con diferentes formatos de parámetros
      container_id ||= params[:containerId]
      username = params[:username]
      
      Rails.logger.info("Validando token: #{token}, container_id: #{container_id}, username: #{username}, IP: #{request.remote_ip}")
      
      # En desarrollo, permitimos acceso para facilitar pruebas
      if Rails.env.development?
        Rails.logger.info("Modo desarrollo: acceso permitido")
        render json: {
          valid: true,
          username: username || 'kali',
          user_id: 1,
          session_id: 1
        }
        return
      end
      
      # Buscar token en la caché
      cached_data = token.present? ? Rails.cache.read("wetty_token:#{token}") : nil
      Rails.logger.info("Datos de caché: #{cached_data.inspect}")
      
      if cached_data.present?
        # Token válido, obtenemos el usuario y sesión
        usuario = Usuario.find_by(id: cached_data[:usuario_id])
        sesion = SesionLaboratorio.find_by(id: cached_data[:sesion_id])
        
        # Verificamos que existan usuario y sesión
        if usuario && sesion
          # Derivamos un nombre de usuario apropiado
          username = usuario.email.split('@').first.gsub(/[^a-zA-Z0-9]/, '')
          
          # Creamos usuario en el contenedor si es necesario (para Wetty)
          if container_id.present? && container_id != 'no-container'
            begin
              create_dynamic_user(container_id, username, usuario.id, sesion.id)
            rescue => e
              Rails.logger.error("Error creando usuario dinámico: #{e.message}")
              # Continuamos aunque haya error, wetty usará el usuario por defecto
            end
          end
          
          render json: {
            valid: true,
            username: username,
            user_id: usuario.id,
            session_id: sesion.id
          }
        else
          Rails.logger.error("Datos de sesión inválidos - Usuario: #{usuario&.id}, Sesión: #{sesion&.id}")
          
          # En desarrollo, permitimos acceso aunque fallen las validaciones
          if Rails.env.development?
            render json: {
              valid: true,
              username: username || 'kali',
              user_id: 1,
              session_id: 1
            }
          else
            render json: { valid: false, error: 'Datos de sesión inválidos' }, status: :unauthorized
          end
        end
      else
        # En desarrollo, si no hay token pero la solicitud viene de la red local, permitimos
        if Rails.env.development? || request.remote_ip == '127.0.0.1' || request.remote_ip.start_with?('172.')
          Rails.logger.info("Sin token pero en desarrollo o red local: acceso permitido con usuario '#{username || 'kali'}'")
          render json: {
            valid: true,
            username: username || 'kali',
            user_id: 1,
            session_id: 1
          }
        else
          Rails.logger.error("Token inválido o expirado: #{token}, IP: #{request.remote_ip}")
          render json: { valid: false, error: 'Token inválido o expirado' }, status: :unauthorized
        end
      end
    end
    
    def metrics
      session_id = params[:session_id]
      
      # Verificar acceso a sesión
      sesion = SesionLaboratorio.find_by(id: session_id)
      if sesion.present? && (sesion.usuario_id == current_usuario.id || current_usuario.admin?)
        # Obtener métricas actuales - prioriza DockerLabService, usa MetricsService como fallback
        metrics = if defined?(DockerLabService) && DockerLabService.respond_to?(:get_metrics)
          DockerLabService.get_metrics(sesion)
        else 
          MetricsService.collect_metrics(sesion)
        end
        
        # Asegurarnos de que los campos requeridos existen
        metrics = metrics.is_a?(Hash) ? metrics : {}
        
        render json: metrics
      else
        render json: { error: 'Acceso no autorizado' }, status: :unauthorized
      end
    rescue => e
      render json: { error: e.message }, status: :internal_server_error
    end
    
    def command
      session_id = params[:session_id]
      command = params[:command]
      
      # Verificar acceso y comando
      if session_id.blank? || command.blank?
        return render json: { error: 'Faltan parámetros requeridos' }, status: :bad_request
      end
      
      # Verificar acceso a sesión
      sesion = SesionLaboratorio.find_by(id: session_id)
      if sesion.present? && sesion.usuario_id == current_usuario.id
        # Ejecutar comando
        result = DockerLabService.execute_command(sesion, command)
        
        render json: {
          success: result[:success],
          output: result[:output]
        }
      else
        render json: { error: 'Acceso no autorizado' }, status: :unauthorized
      end
    rescue => e
      render json: { error: e.message }, status: :internal_server_error
    end
    
    # Ejecutar comando en una máquina objetivo específica
    def execute_on_target
      session_id = params[:session_id]
      target_name = params[:target_name]
      command = params[:command]
      
      # Verificar parámetros
      if session_id.blank? || target_name.blank? || command.blank?
        return render json: { error: 'Faltan parámetros requeridos' }, status: :bad_request
      end
      
      # Verificar acceso a sesión
      sesion = SesionLaboratorio.find_by(id: session_id)
      if sesion.present? && sesion.usuario_id == current_usuario.id
        # Ejecutar comando en el objetivo
        result = DockerLabService.execute_command_on_target(sesion, target_name, command)
        
        render json: {
          success: result[:success],
          output: result[:output]
        }
      else
        render json: { error: 'Acceso no autorizado' }, status: :unauthorized
      end
    rescue => e
      render json: { error: e.message }, status: :internal_server_error
    end
    
    # Desplegar una nueva máquina objetivo
    def deploy_target
      session_id = params[:session_id]
      target_type = params[:target_type]
      
      # Verificar parámetros
      if session_id.blank? || target_type.blank?
        return render json: { error: 'Faltan parámetros requeridos' }, status: :bad_request
      end
      
      # Verificar acceso a sesión
      sesion = SesionLaboratorio.find_by(id: session_id)
      if sesion.present? && sesion.usuario_id == current_usuario.id
        # Desplegar objetivo
        success = DockerLabService.create_custom_target(sesion, target_type)
        
        if success
          render json: { success: true, message: "Máquina objetivo desplegada correctamente" }
        else
          render json: { success: false, error: "Error al desplegar máquina objetivo" }
        end
      else
        render json: { error: 'Acceso no autorizado' }, status: :unauthorized
      end
    rescue => e
      render json: { error: e.message }, status: :internal_server_error
    end
    
    # Reiniciar una máquina objetivo
    def restart_target
      session_id = params[:session_id]
      target_name = params[:target_name]
      
      # Verificar parámetros
      if session_id.blank? || target_name.blank?
        return render json: { error: 'Faltan parámetros requeridos' }, status: :bad_request
      end
      
      # Verificar acceso a sesión
      sesion = SesionLaboratorio.find_by(id: session_id)
      if sesion.present? && sesion.usuario_id == current_usuario.id
        # Verificar que el target existe
        if !sesion.resource_usage.is_a?(Hash) || !sesion.resource_usage['targets'].is_a?(Hash) || 
           !sesion.resource_usage['targets'][target_name].present?
          return render json: { success: false, error: "Máquina objetivo no encontrada" }
        end
        
        # Obtener ID del contenedor
        container_id = sesion.resource_usage['targets'][target_name]['container_id']
        if container_id.blank?
          return render json: { success: false, error: "ID de contenedor no disponible" }
        end
        
        # Reiniciar contenedor
        `docker restart #{container_id} 2>&1`
        success = $?.success?
        
        if success
          render json: { success: true, message: "Máquina objetivo reiniciada correctamente" }
        else
          render json: { success: false, error: "Error al reiniciar máquina objetivo" }
        end
      else
        render json: { error: 'Acceso no autorizado' }, status: :unauthorized
      end
    rescue => e
      render json: { error: e.message }, status: :internal_server_error
    end
    
    # Listar objetivos disponibles para una sesión
    def list_targets
      session_id = params[:session_id]
      
      # Verificar parámetros
      if session_id.blank?
        return render json: { error: 'Falta ID de sesión' }, status: :bad_request
      end
      
      # Verificar acceso a sesión
      sesion = SesionLaboratorio.find_by(id: session_id)
      if sesion.present? && sesion.usuario_id == current_usuario.id
        # Obtener lista de objetivos
        targets = DockerLabService.list_targets(sesion)
        
        render json: { success: true, targets: targets }
      else
        render json: { error: 'Acceso no autorizado' }, status: :unauthorized
      end
    rescue => e
      render json: { error: e.message }, status: :internal_server_error
    end
    
    private
    
    def create_dynamic_user(container_id, username, user_id, session_id)
      return unless container_id.present?
      
      # Ejecutar script para crear usuario en el contenedor
      cmd = "docker exec #{container_id} /usr/local/bin/create_dynamic_user.sh #{username} #{user_id} #{session_id}"
      Rails.logger.info("Ejecutando: #{cmd}")
      
      result = `#{cmd} 2>&1`
      success = $?.success?
      
      if success
        Rails.logger.info("Usuario #{username} creado en contenedor #{container_id}: #{result}")
      else
        Rails.logger.error("Error creando usuario en contenedor: #{result}")
        raise "Error creando usuario: #{result}"
      end
    end
  end
end