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
  
  def flash_class(level)
    case level
    when 'notice', 'success'
      'bg-green-100 border-green-400 text-green-700'
    when 'alert', 'error'
      'bg-red-100 border-red-400 text-red-700'
    when 'warning'
      'bg-yellow-100 border-yellow-400 text-yellow-700'
    when 'info'
      'bg-blue-100 border-blue-400 text-blue-700'
    else
      'bg-gray-100 border-gray-400 text-gray-700'
    end
  end

  def pagination_manual(collection)
    current_page = collection.current_page || 1
    total_pages = collection.total_pages || 1
    
    links = []
    
    # First page
    if current_page > 1
      links << link_to('Primera', url_for(params.permit!.merge(page: 1)), class: "px-3 py-2 border border-gray-700 bg-gray-700 text-white hover:bg-gray-600 hover:text-white transition-colors")
    else
      links << content_tag(:span, 'Primera', class: "px-3 py-2 border border-gray-700 bg-gray-800 text-gray-500 cursor-not-allowed")
    end
    
    # Previous page
    if current_page > 1
      links << link_to('Anterior', url_for(params.permit!.merge(page: current_page - 1)), class: "px-3 py-2 border border-gray-700 bg-gray-700 text-white hover:bg-gray-600 hover:text-white transition-colors")
    else
      links << content_tag(:span, 'Anterior', class: "px-3 py-2 border border-gray-700 bg-gray-800 text-gray-500 cursor-not-allowed")
    end
    
    # Page numbers
    window_size = 2
    window_start = [1, current_page - window_size].max
    window_end = [total_pages, current_page + window_size].min
    
    # Show dots before window if needed
    if window_start > 1
      links << content_tag(:span, '...', class: "px-3 py-2 border border-gray-700 bg-gray-800 text-gray-400")
    end
    
    # Page links
    (window_start..window_end).each do |page_num|
      if page_num == current_page
        links << content_tag(:span, page_num, class: "px-3 py-2 border border-blue-500 bg-blue-600 text-white font-bold")
      else
        links << link_to(page_num, url_for(params.permit!.merge(page: page_num)), class: "px-3 py-2 border border-gray-700 bg-gray-700 text-white hover:bg-gray-600 hover:text-white transition-colors")
      end
    end
    
    # Show dots after window if needed
    if window_end < total_pages
      links << content_tag(:span, '...', class: "px-3 py-2 border border-gray-700 bg-gray-800 text-gray-400")
    end
    
    # Next page
    if current_page < total_pages
      links << link_to('Siguiente', url_for(params.permit!.merge(page: current_page + 1)), class: "px-3 py-2 border border-gray-700 bg-gray-700 text-white hover:bg-gray-600 hover:text-white transition-colors")
    else
      links << content_tag(:span, 'Siguiente', class: "px-3 py-2 border border-gray-700 bg-gray-800 text-gray-500 cursor-not-allowed")
    end
    
    # Last page
    if current_page < total_pages
      links << link_to('Última', url_for(params.permit!.merge(page: total_pages)), class: "px-3 py-2 border border-gray-700 bg-gray-700 text-white hover:bg-gray-600 hover:text-white transition-colors")
    else
      links << content_tag(:span, 'Última', class: "px-3 py-2 border border-gray-700 bg-gray-800 text-gray-500 cursor-not-allowed")
    end
    
    safe_join(links)
  end
end
