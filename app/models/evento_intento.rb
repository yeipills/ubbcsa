class EventoIntento < ApplicationRecord
  self.table_name = 'eventos_intento_quiz'
  
  belongs_to :intento_quiz
  belongs_to :usuario
  
  validates :tipo, presence: true
  validates :timestamp, presence: true
  
  # Tipos de eventos comunes
  TIPOS_EVENTO = {
    inicio: 'inicio',
    respuesta: 'respuesta',
    completado: 'completado',
    expirado: 'expirado',
    anulacion: 'anulacion',
    revision: 'revision',
    vista_pregunta: 'vista_pregunta',
    navegacion: 'navegacion'
  }
  
  # Scopes útiles
  scope :cronologico, -> { order(timestamp: :asc) }
  scope :tipo, ->(tipo) { where(tipo: tipo) }
  scope :del_usuario, ->(usuario_id) { where(usuario_id: usuario_id) }
  scope :del_periodo, ->(inicio, fin) { where('timestamp BETWEEN ? AND ?', inicio, fin) }
  
  def self.registrar(intento, tipo, usuario, detalles = {})
    create(
      intento_quiz: intento,
      usuario: usuario,
      tipo: tipo,
      detalles: detalles,
      timestamp: Time.current
    )
  end
  
  def self.registrar_vista_pregunta(intento, pregunta, usuario, tiempo_vista = nil)
    registrar(
      intento,
      TIPOS_EVENTO[:vista_pregunta],
      usuario,
      {
        pregunta_id: pregunta.id,
        orden: pregunta.orden,
        tipo_pregunta: pregunta.tipo,
        tiempo_vista: tiempo_vista || Time.current.to_i
      }
    )
  end
  
  def datos_formateados
    case tipo
    when TIPOS_EVENTO[:inicio]
      "Inicio del intento ##{detalles['numero_intento']}"
    when TIPOS_EVENTO[:completado]
      "Finalizado con #{detalles['puntaje']}% (#{detalles['preguntas_respondidas']} de #{detalles['preguntas_totales']} preguntas)"
    when TIPOS_EVENTO[:respuesta]
      "Respondió pregunta #{detalles['pregunta_orden']} (#{detalles['tiempo_respuesta']} segundos)"
    when TIPOS_EVENTO[:expirado]
      "Tiempo expirado (#{detalles['preguntas_respondidas']} de #{detalles['preguntas_totales']} preguntas)"
    when TIPOS_EVENTO[:anulacion]
      "Intento anulado: #{detalles['motivo']}"
    else
      "Evento: #{tipo}"
    end
  end
end