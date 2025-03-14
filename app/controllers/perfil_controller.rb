# app/controllers/perfil_controller.rb
class PerfilController < ApplicationController
  before_action :authenticate_usuario!
  before_action :set_usuario

  def show
    @usuario = params[:id] ? Usuario.find(params[:id]) : current_usuario
    @sesiones_recientes = @usuario.sesion_laboratorios
                                  .includes(:laboratorio)
                                  .order(created_at: :desc)
                                  .limit(5)
    @estadisticas = {
      sesiones_activas: @usuario.sesion_laboratorios.activas.count,
      laboratorios_completados: @usuario.laboratorios_completados || 0,
      cursos_inscritos: @usuario.todos_cursos.count || 0
    }
    @logros = @usuario.logros
  end

  def edit
    @usuario = current_usuario
  end

  def update
    @usuario = current_usuario
    if @usuario.update(perfil_params)
      redirect_to perfil_path, notice: 'Perfil actualizado exitosamente'
    else
      render :edit
    end
  end

  private

  def set_usuario
    @usuario = params[:id] ? Usuario.find(params[:id]) : current_usuario
  end

  def perfil_params
    params.require(:usuario).permit(
      :nombre_completo,
      :nombre_usuario,
      :email,
      :avatar
    )
  end
end
