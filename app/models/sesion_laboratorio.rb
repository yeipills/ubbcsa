class SesionLaboratorio < ApplicationRecord
  belongs_to :laboratorio
  belongs_to :usuario
  has_many :metrica_laboratorios, dependent: :destroy

  ESTADOS = %w[iniciando activa pausada completada abandonada].freeze

  validates :estado, presence: true, inclusion: { in: ESTADOS }
  validates :tiempo_inicio, presence: true

  scope :activas, -> { where(estado: 'activa') }
  scope :completadas, -> { where(estado: 'completada') }
  scope :recientes, -> { order(created_at: :desc) }

  # Métodos de consulta para verificar estado
  def activa?
    estado == 'activa'
  end

  def completada?
    estado == 'completada'
  end

  def pausada?
    estado == 'pausada'
  end

  def abandonada?
    estado == 'abandonada'
  end

  def iniciando?
    estado == 'iniciando'
  end

  def actividad_reciente
    metrica_laboratorios.order(created_at: :desc).limit(10).map do |metrica|
      {
        tipo: 'metrica',
        timestamp: metrica.created_at,
        datos: {
          cpu: metrica.cpu_usage,
          memoria: metrica.memory_usage,
          red: metrica.network_usage
        }
      }
    end
  end
end
