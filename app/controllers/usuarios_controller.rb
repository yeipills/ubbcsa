# app/controllers/usuarios_controller.rb
class UsuariosController < ApplicationController
  def show
    @usuario = current_usuario
    @estadisticas = @usuario.estadisticas_generales
    @laboratorios_recientes = @usuario.sesion_laboratorios.recientes
    @logros = @usuario.logros
  end
end