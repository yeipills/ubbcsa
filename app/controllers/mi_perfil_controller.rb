# app/controllers/mi_perfil_controller.rb
class MiPerfilController < ApplicationController
  before_action :authenticate_usuario!
  before_action :set_usuario

  def show
    @sesiones_recientes = @usuario.sesion_laboratorios
                                  .includes(:laboratorio)
                                  .order(created_at: :desc)
                                  .limit(5)
    @estadisticas = {
      sesiones_activas: @usuario.sesion_laboratorios.activas.count,
      laboratorios_completados: @usuario.laboratorios_completados || 0,
      cursos_inscritos: @usuario.todos_cursos.count || 0
    }
  end

  def edit
  end

  def update
    if @usuario.update(perfil_params)
      redirect_to mi_perfil_path, notice: 'Perfil actualizado exitosamente'
    else
      render :edit
    end
  end

  private

  def set_usuario
    @usuario = current_usuario
  end

  def perfil_params
    params.require(:usuario).permit(
      :nombre_completo,
      :nombre_usuario,
      :email
    )
  end
end
