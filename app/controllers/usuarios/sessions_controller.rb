
# app/controllers/usuarios/sessions_controller.rb
class Usuarios::SessionsController < Devise::SessionsController
  layout 'devise'
  before_action :configure_sign_in_params, only: [:create]

  protected

  def configure_sign_in_params
    devise_parameter_sanitizer.permit(:sign_in, keys: [:nombre_usuario])
  end

  def after_sign_in_path_for(resource)
    dashboard_path
  end

  def after_sign_out_path_for(resource_or_scope)
    new_usuario_session_path
  end
end