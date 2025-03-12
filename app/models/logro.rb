# app/models/logro.rb
class Logro < ApplicationRecord
  belongs_to :usuario

  validates :tipo, :titulo, presence: true
  validates :tipo, :titulo, uniqueness: { scope: :usuario_id }

  scope :visibles, -> { where(visible: true) }
  scope :recientes, -> { order(otorgado_en: :desc) }

  TIPOS = {
    laboratorio_completado: 'laboratorio_completado',
    ejercicio_completado: 'ejercicio_completado',
    curso_completado: 'curso_completado',
    ejercicios_consecutivos: 'ejercicios_consecutivos',
    nivel_alcanzado: 'nivel_alcanzado'
  }

  # Crear logro por completar un laboratorio
  def self.create_for_completion(usuario, laboratorio)
    create!(
      usuario: usuario,
      tipo: TIPOS[:laboratorio_completado],
      titulo: "Laboratorio #{laboratorio.nombre} completado",
      descripcion: "Has completado exitosamente el laboratorio #{laboratorio.nombre}",
      metadatos: {
        laboratorio_id: laboratorio.id,
        nivel_dificultad: laboratorio.nivel_dificultad,
        tipo_laboratorio: laboratorio.tipo
      }
    )

    # Verificar logros adicionales
    check_consecutive_labs(usuario)
    check_difficulty_achievements(usuario)
    check_course_completion(usuario, laboratorio.curso)
  end

  private

  # Verificar logros por laboratorios consecutivos
  def self.check_consecutive_labs(usuario)
    count = usuario.sesion_laboratorios.completadas.where('created_at >= ?', 7.days.ago).count

    # Logros por completar varios laboratorios en una semana
    case count
    when 3
      create_if_not_exists(
        usuario: usuario,
        tipo: TIPOS[:ejercicios_consecutivos],
        titulo: 'Estudiante Dedicado',
        descripcion: 'Has completado 3 laboratorios en una semana'
      )
    when 5
      create_if_not_exists(
        usuario: usuario,
        tipo: TIPOS[:ejercicios_consecutivos],
        titulo: 'Experto en Formación',
        descripcion: 'Has completado 5 laboratorios en una semana'
      )
    when 10
      create_if_not_exists(
        usuario: usuario,
        tipo: TIPOS[:ejercicios_consecutivos],
        titulo: 'Maestro de Ciberseguridad',
        descripcion: 'Has completado 10 laboratorios en una semana. ¡Impresionante!'
      )
    end
  end

  # Verificar logros por nivel de dificultad
  def self.check_difficulty_achievements(usuario)
    # Contar laboratorios de nivel avanzado completados
    avanzados_count = usuario.sesion_laboratorios.completadas
                             .joins(:laboratorio)
                             .where(laboratorios: { nivel_dificultad: 'avanzado' })
                             .count

    # Logros por completar laboratorios avanzados
    case avanzados_count
    when 1
      create_if_not_exists(
        usuario: usuario,
        tipo: TIPOS[:nivel_alcanzado],
        titulo: 'Primer Desafío Avanzado',
        descripcion: 'Has completado tu primer laboratorio de nivel avanzado'
      )
    when 5
      create_if_not_exists(
        usuario: usuario,
        tipo: TIPOS[:nivel_alcanzado],
        titulo: 'Especialista Avanzado',
        descripcion: 'Has completado 5 laboratorios de nivel avanzado'
      )
    when 10
      create_if_not_exists(
        usuario: usuario,
        tipo: TIPOS[:nivel_alcanzado],
        titulo: 'Élite de Ciberseguridad',
        descripcion: 'Has completado 10 laboratorios de nivel avanzado'
      )
    end
  end

  # Verificar logro por completar un curso
  def self.check_course_completion(usuario, curso)
    # Verificar si todos los laboratorios del curso están completados
    total_labs = curso.laboratorios.count
    return if total_labs == 0

    completed_labs = usuario.sesion_laboratorios.completadas
                            .joins(:laboratorio)
                            .where(laboratorios: { curso_id: curso.id })
                            .select(:laboratorio_id)
                            .distinct
                            .count

    return unless completed_labs >= total_labs

    create_if_not_exists(
      usuario: usuario,
      tipo: TIPOS[:curso_completado],
      titulo: "Curso #{curso.nombre} Completado",
      descripcion: "Has completado todos los laboratorios del curso #{curso.nombre}",
      metadatos: { curso_id: curso.id }
    )
  end

  # Crear logro si no existe
  def self.create_if_not_exists(attributes)
    logro = find_by(
      usuario_id: attributes[:usuario].id,
      tipo: attributes[:tipo],
      titulo: attributes[:titulo]
    )

    return if logro

    create!(
      usuario: attributes[:usuario],
      tipo: attributes[:tipo],
      titulo: attributes[:titulo],
      descripcion: attributes[:descripcion],
      metadatos: attributes[:metadatos] || {}
    )
  end
end
