# app/channels/notificaciones_channel.rb
class NotificacionesChannel < ApplicationCable::Channel
  def subscribed
    # Solo permitir suscripción a las notificaciones del usuario actual
    if current_usuario && params[:usuario_id] == current_usuario.id
      stream_from "notificaciones_#{current_usuario.id}"
    else
      reject
    end
  end

  def unsubscribed
    stop_all_streams
  end

  # Método llamado desde el cliente para marcar como leída
  def marcar_como_leida(data)
    return unless current_usuario

    if data['id'].present?
      # Marcar una notificación específica
      notificacion = current_usuario.notificaciones.find_by(id: data['id'])
      notificacion&.marcar_como_leida!
    elsif data['todas']
      # Marcar todas las notificaciones
      NotificacionesService.marcar_como_leidas(current_usuario)
    end
  end
end
