# app/channels/laboratorio_channel.rb
class LaboratorioChannel < ApplicationCable::Channel
  def subscribed
    stream_from "laboratorio_#{params[:session_id]}"
  end

  def unsubscribed
    stop_streaming_from "laboratorio_#{params[:session_id]}"
  end
end