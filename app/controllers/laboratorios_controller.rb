# app/controllers/laboratorios_controller.rb
class LaboratoriosController < ApplicationController
  before_action :authenticate_usuario!
  before_action :set_laboratorio, only: [:show, :edit, :update, :destroy]
  before_action :verify_access, only: [:edit, :update, :destroy]

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
      redirect_to @laboratorio, notice: 'Laboratorio creado exitosamente.'
    else
      render :new
    end
  end

  def edit
  end

  def update
    if @laboratorio.update(laboratorio_params)
      redirect_to @laboratorio, notice: 'Laboratorio actualizado exitosamente.'
    else
      render :edit
    end
  end

  def destroy
    @laboratorio.destroy
    redirect_to laboratorios_url, notice: 'Laboratorio eliminado exitosamente.'
  end

  private

  def set_laboratorio
    @laboratorio = Laboratorio.find(params[:id])
  end

  def laboratorio_params
    params.require(:laboratorio).permit(:nombre, :descripcion, :estado, :curso_id)
  end

  def verify_access
    verify_role_access(['profesor', 'admin'])
  end
end
