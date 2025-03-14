# app/controllers/cursos_controller.rb
class CursosController < ApplicationController
  before_action :authenticate_usuario!
  before_action :set_curso, only: %i[show edit update destroy]
  before_action :verify_profesor_or_admin, only: %i[new create edit update destroy]

  def index
    # Base query de cursos según rol del usuario
    base_query = if current_usuario.profesor?
                  current_usuario.cursos_como_profesor
                else
                  current_usuario.cursos
                end

    # Aplicar filtros si existen
    filtered_query = apply_filters(base_query)
                      .includes(:laboratorios, :estudiantes)
                      .order(created_at: :desc)
    
    # Paginación manual (10 items por página)
    page = params[:page].to_i > 0 ? params[:page].to_i : 1
    per_page = 10
    offset = (page - 1) * per_page
    
    @total_count = filtered_query.count
    @cursos = filtered_query.offset(offset).limit(per_page)
  end

  def show
    @laboratorios = @curso.laboratorios.includes(:sesion_laboratorios)
    return unless @curso.profesor?(current_usuario)

    @estudiantes = @curso.estudiantes.includes(:sesion_laboratorios)
  end

  def new
    @curso = Curso.new
  end

  def create
    @curso = current_usuario.cursos_como_profesor.build(curso_params)

    if @curso.save
      redirect_to @curso, notice: 'Curso creado exitosamente.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @curso.update(curso_params)
      redirect_to @curso, notice: 'Curso actualizado exitosamente.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @curso.destroy
    redirect_to cursos_url, notice: 'Curso eliminado exitosamente.'
  end

  # Añadir estudiante a curso
  def add_estudiante
    @curso = Curso.find(params[:curso_id])
    authorize! @curso, to: :update?
    
    @usuario = Usuario.find_by(email: params[:email])
    
    if @usuario.nil?
      redirect_to @curso, alert: 'Usuario no encontrado con ese correo electrónico.'
      return
    end
    
    if @curso.estudiantes.include?(@usuario)
      redirect_to @curso, alert: 'El estudiante ya está inscrito en este curso.'
      return
    end
    
    @curso.estudiantes << @usuario
    redirect_to @curso, notice: 'Estudiante añadido exitosamente.'
  end
  
  # Remover estudiante de curso
  def remove_estudiante
    @curso = Curso.find(params[:curso_id])
    authorize! @curso, to: :update?
    
    @usuario = Usuario.find(params[:usuario_id])
    @curso.estudiantes.delete(@usuario)
    
    redirect_to @curso, notice: 'Estudiante removido exitosamente.'
  end

  private

  def set_curso
    @curso = Curso.find(params[:id])
  end

  def curso_params
    params.require(:curso).permit(
      :nombre,
      :descripcion,
      :codigo,
      :categoria,
      :periodo,
      :activo,
      :estado
    )
  end

  def verify_profesor_or_admin
    verify_role_access(%w[profesor admin])
  end
  
  def apply_filters(query)
    filtered_query = query
    
    # Filtrar por término de búsqueda
    if params[:q].present?
      search_term = "%#{params[:q].downcase}%"
      filtered_query = filtered_query.where('LOWER(nombre) LIKE ? OR LOWER(descripcion) LIKE ? OR LOWER(codigo) LIKE ?', 
                                          search_term, search_term, search_term)
    end
    
    # Filtrar por estado (activo/inactivo)
    case params[:estado_filter]
    when 'activos'
      filtered_query = filtered_query.where(activo: true)
    when 'inactivos'
      filtered_query = filtered_query.where(activo: false)
    end
    
    # Filtrar por periodo
    if params[:periodo_filter].present?
      filtered_query = filtered_query.where(periodo: params[:periodo_filter])
    end
    
    filtered_query
  end
end
