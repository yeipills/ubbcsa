# app/controllers/admin/usuarios_controller.rb
module Admin
  class UsuariosController < Admin::BaseController
    before_action :set_usuario, only: [:show, :edit, :update, :destroy, :cambiar_rol]

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
      
      # Estadísticas básicas para el usuario
      @sesiones_completadas = @usuario.sesion_laboratorios.completadas.count
      @sesiones_activas = @usuario.sesion_laboratorios.activas.count
      
      # Obtener cursos según rol
      if @usuario.profesor?
        @cursos = @usuario.cursos_como_profesor
      else
        @cursos = @usuario.cursos
      end
    end

    def new
      @usuario = Usuario.new
    end
    
    def create
      @usuario = Usuario.new(usuario_params)
      
      if @usuario.save
        # Registrar acción de creación para auditoría
        Rails.logger.info("[ADMIN] Usuario #{current_usuario.nombre_usuario} creó el usuario #{@usuario.nombre_usuario} con rol #{@usuario.rol}")
        redirect_to admin_usuario_path(@usuario), notice: 'Usuario creado exitosamente'
      else
        render :new
      end
    end

    def edit
    end

    def update
      old_rol = @usuario.rol
      
      if @usuario.update(usuario_params)
        # Registrar cambio de rol para auditoría
        if old_rol != @usuario.rol
          Rails.logger.info("[ADMIN] Usuario #{current_usuario.nombre_usuario} cambió el rol de #{@usuario.nombre_usuario} de #{old_rol} a #{@usuario.rol}")
        end
        
        redirect_to admin_usuario_path(@usuario), notice: 'Usuario actualizado exitosamente'
      else
        render :edit
      end
    end
    
    def cambiar_rol
      if params[:rol].present? && @usuario.cambiar_rol!(params[:rol])
        # Registrar acción para auditoría
        Rails.logger.info("[ADMIN] Usuario #{current_usuario.nombre_usuario} cambió el rol de #{@usuario.nombre_usuario} a #{params[:rol]}")
        redirect_to admin_usuario_path(@usuario), notice: "Rol cambiado exitosamente a #{@usuario.rol_nombre}"
      else
        redirect_to admin_usuario_path(@usuario), alert: 'No se pudo cambiar el rol'
      end
    end

    def destroy
      nombre = @usuario.nombre_usuario
      
      if @usuario.destroy
        # Registrar acción para auditoría
        Rails.logger.info("[ADMIN] Usuario #{current_usuario.nombre_usuario} eliminó al usuario #{nombre}")
        redirect_to admin_usuarios_path, notice: 'Usuario eliminado exitosamente'
      else
        redirect_to admin_usuarios_path, alert: 'No se pudo eliminar el usuario'
      end
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
        :password,
        :password_confirmation
      )
    end
  end
end
