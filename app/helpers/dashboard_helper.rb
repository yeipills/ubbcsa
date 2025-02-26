module DashboardHelper
  def sesion_status_color(estado)
    case estado
    when 'activa'
      'text-green-400'
    when 'completada'
      'text-blue-400'
    when 'pausada'
      'text-yellow-400'
    else
      'text-gray-400'
    end
  end

  def difficulty_badge_color(nivel)
    case nivel
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
end