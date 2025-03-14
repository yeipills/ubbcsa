# app/channels/laboratorio_channel.rb
class LaboratorioChannel < ApplicationCable::Channel
  def subscribed
    session_id = params[:session_id]
    channel_type = params[:type] || 'default'
    
    if session_id.present? && valid_session?(session_id)
      stream_from "laboratorio_#{session_id}_#{channel_type}"
    else
      reject
    end
  end

  def unsubscribed
    # Limpiar recursos cuando se desconecta
  end
  
  def execute_command(data)
    session_id = params[:session_id]
    command = data['command']
    
    if session_id.present? && valid_session?(session_id) && command.present?
      # Ejecutar comando en el contenedor y transmitir resultado
      session = SesionLaboratorio.find(session_id)
      
      # Enviar comando al cliente para el historial
      ActionCable.server.broadcast(
        "laboratorio_#{session_id}_terminal",
        { type: 'command', content: command }
      )
      
      # Ejecutar comando con el servicio
      result = DockerLabService.execute_command(session, command)
      
      # Enviar resultado al cliente
      ActionCable.server.broadcast(
        "laboratorio_#{session_id}_terminal",
        { type: 'output', content: result[:output] }
      )
    end
  end
  
  private
  
  def valid_session?(session_id)
    session = SesionLaboratorio.find_by(id: session_id)
    session.present? && session.usuario_id == current_user.id
  rescue
    false
  end
end