class Usuario < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  # Constante para roles disponibles
  ROLES = %w[estudiante profesor admin].freeze

  # Relaciones
  has_many :sesion_laboratorios
  has_many :laboratorios, through: :sesion_laboratorios
  has_many :cursos_como_profesor, class_name: 'Curso', foreign_key: 'profesor_id'
  has_many :curso_estudiantes
  has_many :cursos, through: :curso_estudiantes, source: :curso
  has_many :notificaciones, class_name: 'Notificacion', dependent: :destroy
  has_one :preferencias_notificacion, class_name: 'PreferenciasNotificacion', dependent: :destroy
  has_many :logros, dependent: :destroy
  has_many :ejercicio_completados
  has_many :intentos_quiz, class_name: 'IntentoQuiz', dependent: :destroy
  has_many :quiz_results, dependent: :destroy

  # Validaciones
  validates :nombre_usuario, presence: true, uniqueness: true
  validates :nombre_completo, presence: true
  validates :rol, presence: true, inclusion: { in: ROLES }
  
  # Método de ayuda para verificar roles
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
    if profesor? || admin?
      cursos_como_profesor
    else
      cursos
    end
  end
  
  # Método para obtener el nombre del rol en formato legible
  def rol_nombre
    case rol
    when 'admin'
      'Administrador'
    when 'profesor'
      'Profesor'
    when 'estudiante'
      'Estudiante'
    else
      rol.humanize
    end
  end
  
  # Método para cambiar el rol del usuario
  def cambiar_rol!(nuevo_rol)
    return false unless %w[estudiante profesor admin].include?(nuevo_rol.to_s)
    
    # Registro para auditoría
    old_rol = self.rol
    update(rol: nuevo_rol)
    
    Rails.logger.info("[CAMBIO ROL] Usuario #{nombre_usuario} (#{id}) cambió de #{old_rol} a #{nuevo_rol}")
    true
  end

  private

  def asignar_rol_por_defecto
    self.rol ||= 'estudiante'
  end
end
