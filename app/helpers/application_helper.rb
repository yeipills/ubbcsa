# app/helpers/application_helper.rb
module ApplicationHelper
  def translate_flash_message(message)
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
      'Your account has been updated successfully' => 'Tu cuenta ha sido actualizada exitosamente'

    }

    translations[message] || message
  end
end
