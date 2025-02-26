# app/helpers/usuarios_helper.rb
module UsuariosHelper
  def actividad_status_color(status, type = :bg)
    base_color = case status
                when 'completed'
                  'green'
                when 'in_progress'
                  'blue'
                when 'failed'
                  'red'
                else
                  'gray'
                end
    
    type == :bg ? "bg-#{base_color}-500" : "text-#{base_color}-500"
  end
end