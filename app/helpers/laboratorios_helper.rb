# app/helpers/laboratorios_helper.rb
module LaboratoriosHelper
  def laboratorio_icon(categoria)
    case categoria.to_s.downcase
    when 'pentesting'
      'fas fa-shield-alt'
    when 'forense'
      'fas fa-search'
    when 'redes'
      'fas fa-network-wired'
    else
      'fas fa-laptop-code'
    end
  end

  def dificultad_color(dificultad)
    case dificultad.to_s.downcase
    when 'principiante'
      'bg-green-100 text-green-800'
    when 'intermedio'
      'bg-yellow-100 text-yellow-800'
    when 'avanzado'
      'bg-red-100 text-red-800'
    else
      'bg-gray-100 text-gray-800'
    end
  end

  def laboratorio_action_text(laboratorio, usuario)
    sesion = usuario.sesion_laboratorios.find_by(laboratorio: laboratorio)
    
    if sesion&.completed?
      'Volver a Intentar'
    elsif sesion&.in_progress?
      'Continuar'
    else
      'Comenzar'
    end
  end
end