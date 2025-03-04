# app/controllers/application_controller.rb
class ApplicationController < ActionController::Base
  before_action :configure_permitted_parameters, if: :devise_controller?
  include RoleVerifiable

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: %i[nombre_completo nombre_usuario rol])
  end

  def after_sign_in_path_for(resource)
    dashboard_path
  end

  def after_sign_up_path_for(resource)
    dashboard_path
  end

  def authenticate_admin!
    return if current_usuario&.admin?

    flash_error('Acceso restringido a administradores')
    redirect_to root_path
  end

  def authenticate_profesor!
    return if current_usuario&.profesor?

    flash_error('Acceso restringido a profesores')
    redirect_to root_path
  end

  def authenticate_estudiante!
    return if current_usuario&.estudiante?

    flash_error('Acceso restringido a estudiantes')
    redirect_to root_path
  end

  def verify_role_access(roles = [])
    return if roles.include?(current_usuario&.rol)

    flash_error('No tienes permisos para acceder a esta sección')
    redirect_to root_path
  end

  # Helpers para mensajes flash (ahora con mensajes estándar en español)
  def flash_success(message = nil)
    message ||= 'Operación realizada con éxito'
    flash[:notice] = message.is_a?(Symbol) ? t(message) : translate_flash_message(message)
  end

  def flash_error(message = nil)
    message ||= 'Ha ocurrido un error'
    flash[:error] = message.is_a?(Symbol) ? t(message) : translate_flash_message(message)
  end

  def flash_alert(message = nil)
    message ||= 'Atención requerida'
    flash[:alert] = message.is_a?(Symbol) ? t(message) : translate_flash_message(message)
  end

  def flash_now_success(message = nil)
    message ||= 'Operación realizada con éxito'
    flash.now[:notice] = message.is_a?(Symbol) ? t(message) : translate_flash_message(message)
  end

  def flash_now_error(message = nil)
    message ||= 'Ha ocurrido un error'
    flash.now[:error] = message.is_a?(Symbol) ? t(message) : translate_flash_message(message)
  end

  def flash_now_alert(message = nil)
    message ||= 'Atención requerida'
    flash.now[:alert] = message.is_a?(Symbol) ? t(message) : translate_flash_message(message)
  end

  # Métodos específicos para acciones comunes (en español)
  def flash_created(resource = 'Elemento')
    flash_success("#{resource} creado exitosamente")
  end

  def flash_updated(resource = 'Elemento')
    flash_success("#{resource} actualizado exitosamente")
  end

  def flash_destroyed(resource = 'Elemento')
    flash_success("#{resource} eliminado exitosamente")
  end

  private

  def translate_flash_message(message)
    return message if message.blank?

    # Llamar al helper de traducción si es necesario, pero primero buscar en nuestro diccionario
    translations = {
      # Mensajes en inglés -> español
      'Successfully created' => 'Creado exitosamente',
      'Successfully updated' => 'Actualizado exitosamente',
      'Successfully destroyed' => 'Eliminado exitosamente',
      'Error' => 'Error',
      'not authorized' => 'No autorizado',
      'signed in successfully' => 'Sesión iniciada exitosamente',
      'signed out successfully' => 'Sesión cerrada exitosamente',
      'Invalid email or password' => 'Email o contraseña inválidos',
      'You need to sign in before continuing' => 'Debes iniciar sesión para continuar',
      'Your account has been locked' => 'Tu cuenta ha sido bloqueada',
      'Your password has been changed successfully' => 'Tu contraseña ha sido cambiada exitosamente',
      'Your account has been updated successfully' => 'Tu cuenta ha sido actualizada exitosamente',

      # Mensajes estandarizados para nuestros métodos específicos
      'Elemento creado exitosamente' => 'Elemento creado exitosamente',
      'Elemento actualizado exitosamente' => 'Elemento actualizado exitosamente',
      'Elemento eliminado exitosamente' => 'Elemento eliminado exitosamente',

      # Para casos de controladores específicos
      'Curso' => 'Curso',
      'Laboratorio' => 'Laboratorio',
      'Quiz' => 'Quiz',
      'Usuario' => 'Usuario',
      'Sesión' => 'Sesión'
    }

    translations[message] || message
  end
end
