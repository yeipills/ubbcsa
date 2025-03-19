# app/controllers/notificaciones_controller.rb
class NotificacionesController < ApplicationController
  before_action :authenticate_usuario!
  before_action :set_notificacion, only: %i[mostrar marcar_como_leida marcar_como_no_leida eliminar]

  def index
    # Obtener todas las notificaciones del usuario paginadas con Kaminari
    @notificaciones = current_usuario.notificaciones.recientes.page(params[:page]).per(20)

    # Filtrar por tipo si se especifica
    @notificaciones = @notificaciones.del_tipo(params[:tipo]) if params[:tipo].present?

    # Filtrar solo no leídas si se solicita
    @notificaciones = @notificaciones.no_leidas if params[:no_leidas] == 'true'

    # Contar totales para mostrar en la interfaz
    @total_no_leidas = current_usuario.notificaciones.no_leidas.count
    @total = current_usuario.notificaciones.count

    # Agrupar por tipo para el filtro
    @tipos_disponibles = current_usuario.notificaciones
                                        .group(:tipo)
                                        .count
                                        .transform_keys(&:to_s)

    respond_to do |format|
      format.html
      format.json { render json: @notificaciones }
    end
  end

  def mostrar
    # Marcar automáticamente como leída al ver el detalle
    @notificacion.marcar_como_leida! unless @notificacion.leida

    respond_to do |format|
      format.html
      format.json { render json: @notificacion }
    end
  end

  def no_leidas
    # Devolver solo el conteo y las notificaciones no leídas más recientes
    @notificaciones = current_usuario.notificaciones.no_leidas.recientes.limit(5)
    @total_no_leidas = current_usuario.notificaciones.no_leidas.count

    respond_to do |format|
      format.html { render :_notificaciones_dropdown, layout: false }
      format.json { render json: { count: @total_no_leidas, notificaciones: @notificaciones } }
    end
  end

  def marcar_como_leida
    @notificacion.marcar_como_leida!

    respond_to do |format|
      format.html { redirect_back fallback_location: notificaciones_path, notice: 'Notificación marcada como leída' }
      format.json { render json: { success: true } }
    end
  end

  def marcar_como_no_leida
    @notificacion.marcar_como_no_leida!

    respond_to do |format|
      format.html { redirect_back fallback_location: notificaciones_path, notice: 'Notificación marcada como no leída' }
      format.json { render json: { success: true } }
    end
  end

  def marcar_todas_como_leidas
    NotificacionesService.marcar_como_leidas(current_usuario)

    respond_to do |format|
      format.html do
        redirect_back fallback_location: notificaciones_path, notice: 'Todas las notificaciones marcadas como leídas'
      end
      format.json { render json: { success: true } }
    end
  end

  def eliminar
    @notificacion.destroy

    respond_to do |format|
      format.html { redirect_back fallback_location: notificaciones_path, notice: 'Notificación eliminada' }
      format.json { render json: { success: true } }
    end
  end

  def eliminar_todas
    # Solo eliminar notificaciones ya leídas para evitar pérdida accidental
    current_usuario.notificaciones.where(leida: true).destroy_all

    respond_to do |format|
      format.html { redirect_back fallback_location: notificaciones_path, notice: 'Notificaciones leídas eliminadas' }
      format.json { render json: { success: true } }
    end
  end

  def preferencias
    @preferencias = current_usuario.preferencias_notificacion ||
                    PreferenciasNotificacion.create(usuario: current_usuario)

    return unless request.post?

    if update_preferencias
      redirect_to preferencias_notificaciones_path, notice: 'Preferencias actualizadas exitosamente'
    else
      render :preferencias
    end
  end

  private

  def set_notificacion
    @notificacion = current_usuario.notificaciones.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    respond_to do |format|
      format.html { redirect_to notificaciones_path, alert: 'Notificación no encontrada' }
      format.json { render json: { error: 'Notificación no encontrada' }, status: :not_found }
    end
  end

  def update_preferencias
    @preferencias = current_usuario.preferencias_notificacion

    # Actualizar canales generales
    @preferencias.update(
      email_habilitado: params[:email_habilitado] == '1',
      web_habilitado: params[:web_habilitado] == '1',
      movil_habilitado: params[:movil_habilitado] == '1',
      resumen_diario: params[:resumen_diario] == '1',
      resumen_semanal: params[:resumen_semanal] == '1',
      hora_resumen: params[:hora_resumen]
    )

    # Actualizar preferencias por tipo
    PreferenciasNotificacion::TIPOS_NOTIFICACIONES.each do |tipo|
      config = {}

      PreferenciasNotificacion::CANALES.each do |canal|
        param_name = "#{tipo}_#{canal}"
        config[canal] = params[param_name] == '1'
      end

      @preferencias.actualizar_configuracion(tipo,
                                             web: config['web'],
                                             email: config['email'],
                                             movil: config['movil'])
    end

    @preferencias.save
  end
end
