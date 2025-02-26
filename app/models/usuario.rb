class Usuario < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  # Relaciones
  has_many :sesion_laboratorios
  has_many :laboratorios, through: :sesion_laboratorios
  has_many :cursos_como_profesor, class_name: 'Curso', foreign_key: 'profesor_id'
  has_many :curso_estudiantes
  has_many :cursos, through: :curso_estudiantes, source: :curso

  # Validaciones
  validates :nombre_usuario, presence: true, uniqueness: true
  validates :nombre_completo, presence: true
  validates :rol, presence: true, inclusion: { in: ['estudiante', 'profesor', 'admin'] }

  # Callback para asignar rol por defecto
  before_validation :asignar_rol_por_defecto, on: :create

  # Métodos
  def profesor?
    rol == 'profesor'
  end

  def estudiante?
    rol == 'estudiante'
  end

  def admin?
    rol == 'admin'
  end

  def laboratorios_completados
    sesion_laboratorios.completadas.distinct.count(:laboratorio_id)
  end

  def todos_cursos
    if profesor?
      cursos_como_profesor
    else
      cursos
    end
  end

  private

  def asignar_rol_por_defecto
    self.rol ||= 'estudiante'
  end
end