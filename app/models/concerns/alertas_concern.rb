# app/models/concerns/alertas_concern.rb
module AlertasConcern
  extend ActiveSupport::Concern

  included do
    def alertas_activas
      alertas.active.includes(:tipo_alerta).limit(5)
    end
  end
end