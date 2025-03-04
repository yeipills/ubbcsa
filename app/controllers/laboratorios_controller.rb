# app/controllers/laboratorios_controller.rb
class LaboratoriosController < ApplicationController
  before_action :authenticate_usuario!
  before_action :set_laboratorio, only: %i[show edit update destroy]
  before_action :verify_access, only: %i[edit update destroy]

  def index
    @laboratorios = Laboratorio.activos
                               .includes(:curso)
                               .order(created_at: :desc)
  end

  def show
    @sesion_activa = current_usuario.sesion_laboratorios
                                    .activas
                                    .find_by(laboratorio: @laboratorio)
  end

  def new
    @curso = Curso.find(params[:curso_id])
    @laboratorio = @curso.laboratorios.build
  end

  def create
    @laboratorio = Laboratorio.new(laboratorio_params)
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
    params.require(:laboratorio).permit(:nombre, :descripcion, :estado, :curso_id)
  end

  def verify_access
    verify_role_access(%w[profesor admin])
  end
end
