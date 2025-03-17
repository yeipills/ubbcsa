# app/controllers/sesion_laboratorios_controller.rb
class SesionLaboratoriosController < ApplicationController
  before_action :authenticate_usuario!
  before_action :set_sesion, except: [:create]
  before_action :verificar_sesion_activa, only: [:show]
  before_action :verificar_sesion_modificable, only: %i[pausar completar destroy]

  def show
    @sesion = current_usuario.sesion_laboratorios.find(params[:id])
    
    # Obtener métricas para mostrar en la interfaz
    if defined?(MetricsService)
      metrics_service = MetricsService.new(@sesion)
      @metricas = metrics_service.get_cached_metrics
    else
      @metricas = {
        cpu_usage: Random.rand(10.0..95.0).round(2),
        memory_usage: Random.rand(20.0..80.0).round(2),
        network_usage: Random.rand(100.0..1000.0).round(2),
        timestamp: Time.current
      }
    end
    
    # Obtener actividad reciente
    @actividad_reciente = @sesion.actividad_reciente
    
    # Programar trabajo en segundo plano para monitorear métricas si no está corriendo ya
    if @sesion.activa?
      # Usamos Redis para verificar si ya hay un job ejecutándose para esta sesión
      job_key = "metrics_job_#{@sesion.id}"
      
      unless Rails.cache.exist?(job_key)
        MonitorMetricsJob.perform_later(@sesion.id)
        # Marcar que hay un job en ejecución (expira después de 10 segundos por seguridad)
        Rails.cache.write(job_key, true, expires_in: 10.seconds)
      end
    end
    
    # La URL de ttyd se maneja directamente en el partial _terminal.html.erb

    # Agregar estadisticas
    @estadisticas = {
      sesiones_activas: current_usuario.sesion_laboratorios.activas.count,
      laboratorios_completados: current_usuario.sesion_laboratorios.completadas.count,
      cursos_inscritos: current_usuario.cursos.count
    }
    
    # Obtener ejercicios y objetivos de la sesión si existen
    if @sesion.laboratorio.present?
      # Verificar si la tabla Ejercicio existe antes de intentar acceder
      if ActiveRecord::Base.connection.table_exists?('ejercicios')
        @ejercicios = @sesion.laboratorio.ejercicios.order(:orden) rescue []
        @ejercicios_completados = current_usuario.ejercicio_completados.where(laboratorio: @sesion.laboratorio).pluck(:ejercicio_id) rescue []
      else
        @ejercicios = []
        @ejercicios_completados = []
      end
    end

    respond_to do |format|
      format.html
      format.json { render json: { 
                     sesion: @sesion, 
                     metricas: @metricas,
                     actividad: @actividad_reciente
                   } 
                 }
    end
  rescue ActiveRecord::RecordNotFound
    flash_error('Sesión no encontrada')
    redirect_to dashboard_path
  rescue StandardError => e
    Rails.logger.error("Error al cargar sesión: #{e.message}")
    Rails.logger.error(e.backtrace.join("\n")) if Rails.env.development?
    flash_error('Error al cargar la sesión')
    redirect_to dashboard_path
  end

  def create
    @laboratorio = Laboratorio.find_by(id: params[:laboratorio_id])
    unless @laboratorio
      flash_error('Laboratorio no encontrado')
      redirect_to laboratorios_path
      return
    end

    if current_usuario.sesion_laboratorios.activas.exists?(laboratorio: @laboratorio)
      flash_alert('Ya tienes una sesión activa para este laboratorio')
      redirect_to @laboratorio
      return
    end

    @sesion = current_usuario.sesion_laboratorios.new(
      laboratorio: @laboratorio,
      estado: 'iniciando',
      tiempo_inicio: Time.current
    )

    if @sesion.save
      begin
        Rails.logger.info "Intentando iniciar sesión en LaboratorioService para sesión ID: #{@sesion.id}"

        resultado = LaboratorioService.iniciar_sesion(@sesion)

        raise 'El servicio no pudo iniciar la sesión correctamente' unless resultado

        @sesion.update(estado: 'activa')
        Rails.logger.info "Sesión ID: #{@sesion.id} activada correctamente en LaboratorioService"
        flash_success('Sesión iniciada correctamente')
        redirect_to @sesion
      rescue StandardError => e
        Rails.logger.error("Error en LaboratorioService al iniciar sesión ID #{@sesion.id}: #{e.message}")
        Rails.logger.error(e.backtrace.join("\n")) # Registrar el stacktrace para más detalles
        flash_error("Error al iniciar la sesión: #{e.message}")
        redirect_to @laboratorio
      end
    else
      Rails.logger.error("Error al guardar sesión: #{@sesion.errors.full_messages.join(', ')}")
      flash_error("Error al crear la sesión: #{@sesion.errors.full_messages.join(', ')}")
      redirect_to @laboratorio
    end
  rescue StandardError => e
    Rails.logger.error("Error inesperado en create: #{e.message}")
    Rails.logger.error(e.backtrace.join("\n"))
    flash_error('Error inesperado al crear la sesión')
    redirect_to laboratorios_path
  end

  def pausar
    if @sesion.update(estado: 'pausada')
      LaboratorioService.pausar_sesion(@sesion)
      flash_success('Sesión pausada correctamente')
      redirect_to @sesion
    else
      flash_error('No se pudo pausar la sesión')
      redirect_to @sesion
    end
  end

  def completar
    if @sesion.update(estado: 'completada', tiempo_fin: Time.current)
      LaboratorioService.finalizar_sesion(@sesion)
      flash_success('Laboratorio completado exitosamente')
      redirect_to dashboard_path
    else
      flash_error('Error al completar el laboratorio')
      redirect_to @sesion
    end
  end

  def destroy
    if LaboratorioService.finalizar_sesion(@sesion)
      @sesion.update(estado: 'abandonada', tiempo_fin: Time.current)
      flash_success('Sesión finalizada correctamente')
      redirect_to dashboard_path
    else
      flash_error('Error al finalizar la sesión')
      redirect_to @sesion
    end
  rescue StandardError => e
    Rails.logger.error("Error al destruir sesión #{params[:id]}: #{e.message}")
    flash_error('Error inesperado al finalizar la sesión')
    redirect_to @sesion
  end

  def reset
    @sesion = SesionLaboratorio.find(params[:id])

    # Verificar que el usuario sea el propietario de la sesión
    unless @sesion.usuario == current_usuario
      flash_error('No tienes permisos para reiniciar esta sesión')
      redirect_to dashboard_path
      return
    end

    # Intentar reiniciar el terminal
    begin
      # Aquí puedes implementar la lógica para reiniciar el terminal
      # Por ejemplo, usando LaboratorioService
      resultado = LaboratorioService.reiniciar_sesion(@sesion)

      if resultado
        flash_success('Terminal reiniciada correctamente')
        redirect_to @sesion
      else
        flash_error('Error al reiniciar la terminal')
        redirect_to @sesion
      end
    rescue StandardError => e
      Rails.logger.error("Error al reiniciar sesión: #{e.message}")
      flash_error('Error inesperado al reiniciar la sesión')
      redirect_to @sesion
    end
  end

  def update
    @sesion = SesionLaboratorio.find(params[:id])
    if @sesion.update(sesion_laboratorio_params)
      flash_success('Sesión actualizada')
      redirect_to @sesion
    else
      render :edit
    end
  end

  private

  def sesion_laboratorio_params
    params.require(:sesion_laboratorio).permit(:estado, :notas, :puntuacion)
  end

  def set_sesion
    @sesion = current_usuario.sesion_laboratorios.find_by(id: params[:id])
    return if @sesion

    flash_error('Sesión no encontrada')
    redirect_to dashboard_path
  end

  def verificar_sesion_activa
    unless @sesion.activa?
      flash_error('Esta sesión no está activa')
      redirect_to dashboard_path
      return false
    end
    true
  end

  def verificar_sesion_modificable
    return if @sesion&.estado.in?(%w[activa pausada])

    flash_error('Esta sesión no puede ser modificada')
    redirect_to dashboard_path
  end
end
