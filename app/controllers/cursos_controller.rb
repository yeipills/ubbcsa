# app/controllers/cursos_controller.rb
class CursosController < ApplicationController
  before_action :authenticate_usuario!
  before_action :set_curso, only: %i[show edit update destroy]
  before_action :verify_profesor_or_admin, only: %i[new create edit update destroy]

  def index
    @cursos = if current_usuario.profesor?
                current_usuario.cursos_como_profesor.includes(:laboratorios)
              else
                current_usuario.cursos.includes(:laboratorios)
              end
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
      :activo
    )
  end

  def verify_profesor_or_admin
    verify_role_access(%w[profesor admin])
  end
end
