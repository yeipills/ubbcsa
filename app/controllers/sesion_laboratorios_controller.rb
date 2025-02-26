# app/controllers/sesion_laboratorios_controller.rb
class SesionLaboratoriosController < ApplicationController
  before_action :authenticate_usuario!
  before_action :set_sesion, except: [:create]
  before_action :verificar_sesion_activa, only: [:show]
  before_action :verificar_sesion_modificable, only: [:pausar, :completar, :destroy]

  def show
    begin
      @sesion = current_usuario.sesion_laboratorios.find(params[:id])
      @metricas = MetricsService.new(@sesion).collect_metrics
      @actividad_reciente = @sesion.actividad_reciente
  
      # 🔹 Agregar estadisticas si no está definido
      @estadisticas = {
        sesiones_activas: current_usuario.sesion_laboratorios.activas.count,
        laboratorios_completados: current_usuario.sesion_laboratorios.completadas.count,
        cursos_inscritos: current_usuario.cursos.count
      }
  
      respond_to do |format|
        format.html
        format.json { render json: { metricas: @metricas } }
      end
    rescue ActiveRecord::RecordNotFound
      redirect_to dashboard_path, alert: 'Sesión no encontrada'
    rescue StandardError => e
      Rails.logger.error("Error al cargar sesión: #{e.message}")
      redirect_to dashboard_path, alert: "Error al cargar la sesión"
    end
  end

  def create
    @laboratorio = Laboratorio.find_by(id: params[:laboratorio_id])
    unless @laboratorio
      redirect_to laboratorios_path, alert: 'Laboratorio no encontrado'
      return
    end
  
    if current_usuario.sesion_laboratorios.activas.exists?(laboratorio: @laboratorio)
      redirect_to @laboratorio, alert: 'Ya tienes una sesión activa para este laboratorio'
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
  
        if resultado
          @sesion.update(estado: 'activa')
          Rails.logger.info "Sesión ID: #{@sesion.id} activada correctamente en LaboratorioService"
          redirect_to @sesion, notice: 'Sesión iniciada correctamente'
        else
          raise "El servicio no pudo iniciar la sesión correctamente"
        end
      rescue StandardError => e
        Rails.logger.error("Error en LaboratorioService al iniciar sesión ID #{@sesion.id}: #{e.message}")
        Rails.logger.error(e.backtrace.join("\n"))  # Registrar el stacktrace para más detalles
        redirect_to @laboratorio, alert: "Error al iniciar la sesión: #{e.message}"
      end
    else
      Rails.logger.error("Error al guardar sesión: #{@sesion.errors.full_messages.join(', ')}")
      redirect_to @laboratorio, alert: "Error al crear la sesión: #{@sesion.errors.full_messages.join(', ')}"
    end
  rescue StandardError => e
    Rails.logger.error("Error inesperado en create: #{e.message}")
    Rails.logger.error(e.backtrace.join("\n"))
    redirect_to laboratorios_path, alert: 'Error inesperado al crear la sesión'
  end
  
  

  def pausar
    if @sesion.update(estado: 'pausada')
      LaboratorioService.pausar_sesion(@sesion)
      redirect_to @sesion, notice: 'Sesión pausada correctamente'
    else
      redirect_to @sesion, alert: 'No se pudo pausar la sesión'
    end
  end

  def completar
    if @sesion.update(estado: 'completada', tiempo_fin: Time.current)
      LaboratorioService.finalizar_sesion(@sesion)
      redirect_to dashboard_path, notice: 'Laboratorio completado exitosamente'
    else
      redirect_to @sesion, alert: 'Error al completar el laboratorio'
    end
  end

  def destroy
    if LaboratorioService.finalizar_sesion(@sesion)
      @sesion.update(estado: 'abandonada', tiempo_fin: Time.current)
      redirect_to dashboard_path, notice: 'Sesión finalizada correctamente'
    else
      redirect_to @sesion, alert: 'Error al finalizar la sesión'
    end
  rescue StandardError => e
    Rails.logger.error("Error al destruir sesión #{params[:id]}: #{e.message}")
    redirect_to @sesion, alert: 'Error inesperado al finalizar la sesión'
  end

  def reset
    @sesion = SesionLaboratorio.find(params[:id])
    
    # Verificar que el usuario sea el propietario de la sesión
    unless @sesion.usuario == current_usuario
      redirect_to dashboard_path, alert: 'No tienes permisos para reiniciar esta sesión'
      return
    end
    
    # Intentar reiniciar el terminal
    begin
      # Aquí puedes implementar la lógica para reiniciar el terminal
      # Por ejemplo, usando LaboratorioService
      resultado = LaboratorioService.reiniciar_sesion(@sesion)
      
      if resultado
        redirect_to @sesion, notice: 'Terminal reiniciada correctamente'
      else
        redirect_to @sesion, alert: 'Error al reiniciar la terminal'
      end
    rescue StandardError => e
      Rails.logger.error("Error al reiniciar sesión: #{e.message}")
      redirect_to @sesion, alert: 'Error inesperado al reiniciar la sesión'
    end
  end

  def update
    @sesion = SesionLaboratorio.find(params[:id])
    if @sesion.update(sesion_laboratorio_params)
      redirect_to @sesion, notice: 'Sesión actualizada'
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
    unless @sesion
      redirect_to dashboard_path, alert: 'Sesión no encontrada'
    end
  end

  def verificar_sesion_activa
    unless @sesion.activa?
      redirect_to dashboard_path, alert: 'Esta sesión no está activa'
      return false
    end
    true
  end

  def verificar_sesion_modificable
    unless @sesion&.estado.in?(%w[activa pausada])
      redirect_to dashboard_path, alert: 'Esta sesión no puede ser modificada'
    end
  end
end
