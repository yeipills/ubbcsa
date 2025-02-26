# app/services/laboratorio_service.rb
class LaboratorioService
  class << self
    def iniciar_sesion(sesion)
      begin
        Rails.logger.info("Intentando iniciar sesión en LaboratorioService para sesión ID: #{sesion.id}")
        
        # Verificamos si está disponible el API externo
        Rails.logger.info("Verificando ExternoAPI: #{defined?(ExternoAPI)}")
        
        # Si se está ejecutando en un entorno sin Docker, simular el proceso
        if ENV['SIMULAR_DOCKER'] == 'true' || !command_exists?('docker')
          Rails.logger.info("Iniciando sesión en servicio externo con ID: #{sesion.id}")
          Rails.logger.info("Simulando inicio de sesión en ExternoAPI para sesión ID: #{sesion.id}")
          Rails.logger.info("Sesión ID #{sesion.id} iniciada exitosamente en el servicio externo")
          
          sesion.update(estado: 'activa')
          Rails.logger.info("Sesión ID: #{sesion.id} activada correctamente en LaboratorioService")
          return true
        end
        
        # En entorno real, ejecutar comandos Docker
        tipo = sesion.laboratorio.tipo
        sistema = `docker exec ubbcsa-wetty-1 /home/kali/labs/init.sh #{tipo}`
        
        if sistema
          sesion.update(estado: 'activa')
          return true
        else
          return false
        end
      rescue StandardError => e
        Rails.logger.error("Error iniciando sesión: #{e.message}")
        return false
      end
    end

    def finalizar_sesion(sesion)
      begin
        # Si se está ejecutando en un entorno sin Docker, simular el proceso
        if ENV['SIMULAR_DOCKER'] == 'true' || !command_exists?('docker')
          Rails.logger.info("Finalizando sesión en servicio externo con ID: #{sesion.id}")
          Rails.logger.info("Simulando finalización en ExternoAPI para sesión ID: #{sesion.id}")
          Rails.logger.info("Sesión ID #{sesion.id} finalizada exitosamente en el servicio externo")
          
          return true
        end
        
        # En entorno real, ejecutar comandos Docker
        sistema = `docker exec ubbcsa-wetty-1 rm -rf /home/kali/labs/workspace/*`
        
        if sistema
          return true
        else
          return false
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
          Rails.logger.info("Simulando reinicio en ExternoAPI para sesión ID: #{sesion.id}")
          Rails.logger.info("Sesión ID #{sesion.id} reiniciada exitosamente en el servicio externo")
          
          return true
        end
        
        # En entorno real, ejecutar comandos Docker para reiniciar
        tipo = sesion.laboratorio.tipo
        sistema = `docker exec ubbcsa-wetty-1 /home/kali/labs/reset.sh #{tipo}`
        
        if sistema
          return true
        else
          return false
        end
      rescue StandardError => e
        Rails.logger.error("Error reiniciando sesión: #{e.message}")
        return false
      end
    end

    private

    def command_exists?(command)
      system("which #{command} > /dev/null 2>&1")
    end
  end
end