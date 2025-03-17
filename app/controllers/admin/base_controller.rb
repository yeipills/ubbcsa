# app/controllers/admin/base_controller.rb
module Admin
  class BaseController < ApplicationController
    before_action :authenticate_admin!
    
    private
    
    # Verifica que el usuario actualmente logueado sea un administrador
    # Esto asegura que todas las acciones en el espacio Admin requieran privilegios de administrador
    def authenticate_admin!
      unless current_usuario&.admin?
        flash[:error] = "Acceso restringido a administradores"
        redirect_to root_path and return
      end
      
      # Registrar acceso administrativo para auditoría
      Rails.logger.info("[ADMIN ACCESS] Usuario #{current_usuario.nombre_usuario} (#{current_usuario.id}) accedió a #{controller_name}##{action_name}")
    end
  end
end