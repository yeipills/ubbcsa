class MetricsChannel < ApplicationCable::Channel
  def subscribed
    stream_from "metrics_#{params[:sesion_id]}"
  end

  def unsubscribed
    # Limpieza cuando se desconecta
  end
end