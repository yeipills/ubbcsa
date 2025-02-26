class Usuarios::RegistrationsController < Devise::RegistrationsController
  layout 'devise'
  before_action :configure_sign_up_params, only: [:create]
  before_action :configure_account_update_params, only: [:update]

  protected

  def configure_sign_up_params
    devise_parameter_sanitizer.permit(:sign_up, keys: [
      :nombre_completo,
      :nombre_usuario,
      :rol
    ])
  end

  def configure_account_update_params
    devise_parameter_sanitizer.permit(:account_update, keys: [
      :nombre_completo,
      :nombre_usuario
    ])
  end

  def after_sign_up_path_for(resource)
    dashboard_path
  end

  def after_update_path_for(resource)
    dashboard_path
  end
end