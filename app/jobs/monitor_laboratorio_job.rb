# app/jobs/monitor_laboratorio_job.rb
class MonitorLaboratorioJob < ApplicationJob
  queue_as :default

  def perform(sesion_id)
    sesion = SesionLaboratorio.find(sesion_id)
    return unless sesion.activa?

    metrics = obtener_metricas(sesion)
    
    ActionCable.server.broadcast(
      "laboratorio_#{sesion_id}",
      {
        type: 'metrics',
        **metrics
      }
    )

    # Programar siguiente actualización
    self.class.set(wait: 5.seconds).perform_later(sesion_id) if sesion.activa?
  end

  private

  def obtener_metricas(sesion)
    container_id = `docker ps -qf "name=#{sesion.laboratorio.tipo}"`.strip
    return {} if container_id.empty?

    {
      cpu: `docker stats --no-stream --format "{{.CPUPerc}}" #{container_id}`.strip,
      memory: `docker stats --no-stream --format "{{.MemPerc}}" #{container_id}`.strip,
      network: `docker stats --no-stream --format "{{.NetIO}}" #{container_id}`.strip
    }
  end
end