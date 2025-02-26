class ExternoAPI
  def self.iniciar(sesion)
    Rails.logger.info "Simulando inicio de sesión en ExternoAPI para sesión ID: #{sesion.id}"

    # Simular éxito o fallo aleatorio
    if [true, false].sample
      OpenStruct.new(success?: true, error_message: nil)
    else
      OpenStruct.new(success?: false, error_message: "Error simulado en servicio externo")
    end
  end
end
