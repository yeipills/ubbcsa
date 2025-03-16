# app/services/laboratorio_service.rb
class LaboratorioService
  class << self
    def iniciar_sesion(sesion)
      begin
        Rails.logger.info("Intentando iniciar sesión en LaboratorioService para sesión ID: #{sesion.id}")
        
        # Si se está ejecutando en un entorno sin Docker, simular el proceso
        if ENV['SIMULAR_DOCKER'] == 'true' || !command_exists?('docker')
          Rails.logger.info("Iniciando sesión en servicio externo con ID: #{sesion.id}")
          Rails.logger.info("Simulando inicio de sesión para sesión ID: #{sesion.id}")
          
          sesion.update(estado: 'activa', container_id: "container-simulado-#{sesion.id}")
          Rails.logger.info("Sesión ID: #{sesion.id} activada correctamente en modo simulación")
          return true
        end
        
        # En entorno real, usar DockerLabService para crear un contenedor dedicado
        if defined?(DockerLabService) && DockerLabService.respond_to?(:create_environment)
          Rails.logger.info("Usando DockerLabService para crear ambiente para sesión ID: #{sesion.id}")
          
          # Crear entorno Docker para esta sesión
          resultado = DockerLabService.create_environment(sesion)
          
          if resultado
            sesion.update(estado: 'activa')
            Rails.logger.info("Contenedor creado exitosamente: #{sesion.container_id}")
            return true
          else
            Rails.logger.error("Error al crear contenedor para sesión #{sesion.id}")
            return false
          end
        else
          # Fallback a comando antiguo si DockerLabService no está disponible
          Rails.logger.info("DockerLabService no disponible, usando método antiguo")
          tipo = sesion.laboratorio.tipo
          
          # Generar un ID de contenedor único para la sesión
          container_id = "lab-#{sesion.id}-#{Time.now.to_i}"
          sesion.update(container_id: container_id)
          
          sistema = `docker exec ubbcsa-ttyd-1 /home/kali/labs/init.sh #{tipo}`
          
          if sistema
            sesion.update(estado: 'activa')
            return true
          else
            return false
          end
        end
      rescue StandardError => e
        Rails.logger.error("Error iniciando sesión: #{e.message}")
        Rails.logger.error(e.backtrace.join("\n"))
        return false
      end
    end

    def finalizar_sesion(sesion)
      begin
        # Si se está ejecutando en un entorno sin Docker, simular el proceso
        if ENV['SIMULAR_DOCKER'] == 'true' || !command_exists?('docker')
          Rails.logger.info("Finalizando sesión en servicio externo con ID: #{sesion.id}")
          Rails.logger.info("Simulando finalización para sesión ID: #{sesion.id}")
          Rails.logger.info("Sesión ID #{sesion.id} finalizada exitosamente en modo simulación")
          
          return true
        end
        
        # En entorno real, usar DockerLabService para destruir el contenedor
        if defined?(DockerLabService) && DockerLabService.respond_to?(:destroy_environment)
          Rails.logger.info("Usando DockerLabService para destruir ambiente de sesión ID: #{sesion.id}")
          
          # Destruir entorno Docker para esta sesión
          resultado = DockerLabService.destroy_environment(sesion)
          
          if resultado
            Rails.logger.info("Contenedor #{sesion.container_id} destruido exitosamente")
            return true
          else
            Rails.logger.error("Error al destruir contenedor para sesión #{sesion.id}")
            return false
          end
        else
          # Fallback a comando antiguo si DockerLabService no está disponible
          Rails.logger.info("DockerLabService no disponible, usando método antiguo")
          
          sistema = `docker exec ubbcsa-ttyd-1 rm -rf /home/kali/labs/workspace/*`
          
          if sistema
            return true
          else
            return false
          end
        end
      rescue StandardError => e
        Rails.logger.error("Error finalizando sesión: #{e.message}")
        return false
      end
    end

    def reiniciar_sesion(sesion)
      begin
        # Si se está ejecutando en un entorno sin Docker, simular el proceso
        if ENV['SIMULAR_DOCKER'] == 'true' || !command_exists?('docker')
          Rails.logger.info("Reiniciando sesión en servicio externo con ID: #{sesion.id}")
          Rails.logger.info("Simulando reinicio para sesión ID: #{sesion.id}")
          Rails.logger.info("Sesión ID #{sesion.id} reiniciada exitosamente en modo simulación")
          
          return true
        end
        
        # En entorno real, usar DockerLabService para restaurar el entorno
        if defined?(DockerLabService) && DockerLabService.respond_to?(:restore_environment)
          Rails.logger.info("Usando DockerLabService para restaurar ambiente de sesión ID: #{sesion.id}")
          
          # Restaurar entorno Docker para esta sesión
          resultado = DockerLabService.restore_environment(sesion)
          
          if resultado
            Rails.logger.info("Contenedor #{sesion.container_id} restaurado exitosamente")
            return true
          else
            Rails.logger.error("Error al restaurar contenedor para sesión #{sesion.id}")
            return false
          end
        else
          # Fallback a comando antiguo si DockerLabService no está disponible
          Rails.logger.info("DockerLabService no disponible, usando método antiguo")
          
          tipo = sesion.laboratorio.tipo
          sistema = `docker exec ubbcsa-ttyd-1 /home/kali/labs/reset.sh #{tipo}`
          
          if sistema
            return true
          else
            return false
          end
        end
      rescue StandardError => e
        Rails.logger.error("Error reiniciando sesión: #{e.message}")
        return false
      end
    end
    
    def pausar_sesion(sesion)
      begin
        # Si se está ejecutando en un entorno sin Docker, simular el proceso
        if ENV['SIMULAR_DOCKER'] == 'true' || !command_exists?('docker')
          Rails.logger.info("Pausando sesión en servicio externo con ID: #{sesion.id}")
          Rails.logger.info("Simulando pausa para sesión ID: #{sesion.id}")
          Rails.logger.info("Sesión ID #{sesion.id} pausada exitosamente en modo simulación")
          
          return true
        end
        
        # En entorno real, usar DockerLabService para pausar el contenedor
        if defined?(DockerLabService) && DockerLabService.respond_to?(:pause_environment)
          Rails.logger.info("Usando DockerLabService para pausar ambiente de sesión ID: #{sesion.id}")
          
          # Pausar entorno Docker para esta sesión
          resultado = DockerLabService.pause_environment(sesion)
          
          if resultado
            Rails.logger.info("Contenedor #{sesion.container_id} pausado exitosamente")
            return true
          else
            Rails.logger.error("Error al pausar contenedor para sesión #{sesion.id}")
            return false
          end
        else
          # No hay implementación de pausa en el método antiguo
          Rails.logger.info("DockerLabService no disponible, no se puede pausar")
          return true
        end
      rescue StandardError => e
        Rails.logger.error("Error pausando sesión: #{e.message}")
        return false
      end
    end

    private

    def command_exists?(command)
      system("which #{command} > /dev/null 2>&1")
    end
  end
end