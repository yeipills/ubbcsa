# app/controllers/application_controller.rb
class ApplicationController < ActionController::Base
  before_action :configure_permitted_parameters, if: :devise_controller?
  include RoleVerifiable
  
  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:nombre_completo, :nombre_usuario, :rol])
  end

  def after_sign_in_path_for(resource)
    dashboard_path
  end

  def after_sign_up_path_for(resource)
    dashboard_path
  end

  def authenticate_admin!
    unless current_usuario&.admin?
      flash[:error] = "Acceso restringido a administradores"
      redirect_to root_path
    end
  end

  def authenticate_profesor!
    unless current_usuario&.profesor?
      flash[:error] = "Acceso restringido a profesores"
      redirect_to root_path
    end
  end

  def authenticate_estudiante!
    unless current_usuario&.estudiante?
      flash[:error] = "Acceso restringido a estudiantes"
      redirect_to root_path
    end
  end

  def verify_role_access(roles = [])
    unless roles.include?(current_usuario&.rol)
      flash[:error] = "No tienes permisos para acceder a esta sección"
      redirect_to root_path
    end
  end
end