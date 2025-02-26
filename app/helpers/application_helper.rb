# app/helpers/application_helper.rb
module ApplicationHelper
  def translate_flash_message(message)
    translations = {
      'Successfully created' => 'Creado exitosamente',
      'Successfully updated' => 'Actualizado exitosamente',
      'Successfully destroyed' => 'Eliminado exitosamente',
      'Error' => 'Error',
      'not authorized' => 'no autorizado',
      'signed in successfully' => 'sesión iniciada exitosamente',
      'signed out successfully' => 'sesión cerrada exitosamente',
      # Agrega más traducciones según necesites
    }

    translations[message] || message
  end
end