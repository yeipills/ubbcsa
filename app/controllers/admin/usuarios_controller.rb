# app/controllers/admin/usuarios_controller.rb
module Admin
  class UsuariosController < Admin::BaseController
    before_action :set_usuario, only: [:show, :edit, :update, :destroy]

    def index
      @usuarios = Usuario.includes(:sesion_laboratorios)
                        .order(created_at: :desc)
                        .page(params[:page])
    end

    def show
      @actividad_reciente = @usuario.sesion_laboratorios
                                   .includes(:laboratorio)
                                   .order(created_at: :desc)
                                   .limit(10)
      @estadisticas = @usuario.estadisticas_detalladas
      @cursos_actuales = @usuario.cursos_actuales
    end

    def edit
    end

    def update
      if @usuario.update(usuario_params)
        redirect_to admin_usuario_path(@usuario), notice: 'Usuario actualizado exitosamente'
      else
        render :edit
      end
    end

    def destroy
      @usuario.destroy
      redirect_to admin_usuarios_path, notice: 'Usuario eliminado exitosamente'
    end

    private

    def set_usuario
      @usuario = Usuario.find(params[:id])
    end

    def usuario_params
      params.require(:usuario).permit(
        :nombre_completo,
        :nombre_usuario,
        :email,
        :rol,
        :activo
      )
    end
  end
end
