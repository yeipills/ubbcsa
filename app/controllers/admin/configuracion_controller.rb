# app/controllers/admin/configuracion_controller.rb
module Admin
  class ConfiguracionController < Admin::BaseController
    before_action :set_configuracion, only: [:show, :update]

    def show
      @configuracion = SystemConfig.current
      @limites_sistema = SystemLimits.current
      @notificaciones = NotificationSettings.current
      @backups = BackupConfig.all
    end

    def update
      if @configuracion.update(configuracion_params)
        redirect_to admin_configuracion_path, notice: 'Configuración actualizada exitosamente'
      else
        render :show
      end
    end

    private

    def set_configuracion
      @configuracion = SystemConfig.current
    end

    def configuracion_params
      params.require(:system_config).permit(
        :max_sesiones_simultaneas,
        :tiempo_maximo_sesion,
        :intervalo_backup,
        notification_settings: [],
        system_limits: {}
      )
    end
  end
end