# app/controllers/laboratorios_controller.rb
class LaboratoriosController < ApplicationController
  before_action :authenticate_usuario!
  before_action :set_laboratorio, only: %i[show edit update destroy]
  before_action :verify_access, only: %i[edit update destroy]

  def index
    # Filtrar laboratorios según el rol del usuario
    if current_usuario.admin?
      # Administradores ven todos los laboratorios activos
      @laboratorios = Laboratorio.activos
                                .includes(:curso)
                                .order(created_at: :desc)
    elsif current_usuario.profesor?
      # Profesores solo ven sus propios laboratorios
      @laboratorios = Laboratorio.activos
                                .includes(:curso)
                                .joins(:curso)
                                .where(cursos: { profesor_id: current_usuario.id })
                                .order(created_at: :desc)
    else
      # Estudiantes ven laboratorios de cursos en los que están inscritos
      cursos_ids = current_usuario.cursos.pluck(:id)
      @laboratorios = Laboratorio.activos
                                .includes(:curso)
                                .where(curso_id: cursos_ids)
                                .order(created_at: :desc)
    end
  end

  def show
    # Verificar que el usuario tenga acceso a este laboratorio
    authorize_laboratorio_access
    
    # Buscar sesión activa del usuario para este laboratorio
    @sesion_activa = current_usuario.sesion_laboratorios
                                    .activas
                                    .find_by(laboratorio: @laboratorio)
  end

  def new
    @curso = Curso.find(params[:curso_id])
    @laboratorio = @curso.laboratorios.build
  end

  def create
    @curso = Curso.find(params[:curso_id])
    @laboratorio = Laboratorio.new(laboratorio_params)
    @laboratorio.curso_id = params[:curso_id]
    
    if @laboratorio.save
      flash_created('Laboratorio')
      redirect_to @laboratorio
    else
      render :new
    end
  end

  def edit
  end

  def update
    if @laboratorio.update(laboratorio_params)
      flash_updated('Laboratorio')
      redirect_to @laboratorio
    else
      render :edit
    end
  end

  def destroy
    @laboratorio.destroy
    flash_destroyed('Laboratorio')
    redirect_to laboratorios_url
  end

  private

  def set_laboratorio
    @laboratorio = Laboratorio.find(params[:id])
  end

  def laboratorio_params
    params.require(:laboratorio).permit(
      :nombre,
      :descripcion,
      :curso_id,
      :tipo,
      :duracion_estimada,
      :nivel_dificultad,
      :objetivos,
      :requisitos,
      :activo,
      :fecha
    )
  end

  # Verificar acceso para acciones de modificación
  def verify_access
    return if current_usuario.admin?
    
    if current_usuario.profesor?
      # Verificar que el profesor sea dueño del laboratorio
      unless @laboratorio.curso.profesor_id == current_usuario.id
        flash_error('No tienes permiso para editar este laboratorio')
        redirect_to laboratorio_path(@laboratorio)
        return
      end
    else
      # Si no es ni admin ni profesor, no tiene acceso
      flash_error('No tienes permiso para realizar esta acción')
      redirect_to laboratorios_path
    end
  end
  
  # Verificar acceso para visualización de laboratorio
  def authorize_laboratorio_access
    return if current_usuario.admin?
    
    if current_usuario.profesor?
      # Profesores pueden ver laboratorios que les pertenecen
      return if @laboratorio.curso.profesor_id == current_usuario.id
    else
      # Estudiantes pueden ver laboratorios de cursos en los que están inscritos
      cursos_ids = current_usuario.cursos.pluck(:id)
      return if cursos_ids.include?(@laboratorio.curso_id)
    end
    
    # Si llega aquí, el usuario no tiene acceso
    flash_error('No tienes acceso a este laboratorio')
    redirect_to laboratorios_path
  end
end
