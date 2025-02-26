# app/controllers/perfil_controller.rb
class PerfilController < ApplicationController
  before_action :authenticate_usuario!

  def show
    @usuario = current_usuario
    @sesiones_recientes = @usuario.sesion_laboratorios
                                 .includes(:laboratorio)
                                 .order(created_at: :desc)
                                 .limit(5)
    @estadisticas = @usuario.estadisticas_generales
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

  def perfil_params
    params.require(:usuario).permit(
      :nombre_completo,
      :nombre_usuario,
      :email,
      :avatar
    )
  end
end