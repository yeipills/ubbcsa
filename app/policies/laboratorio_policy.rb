class LaboratorioPolicy
  attr_reader :user, :laboratorio

  def initialize(user, laboratorio)
    @user = user
    @laboratorio = laboratorio
  end

  def access?
    return false unless user
    return true if user.admin?
    return true if user.profesor? && laboratorio.curso.profesor_id == user.id
    
    # Estudiantes solo pueden acceder si están inscritos
    user.estudiante? && user.cursos.include?(laboratorio.curso)
  end

  def manage?
    user.admin? || (user.profesor? && laboratorio.curso.profesor_id == user.id)
  end
end