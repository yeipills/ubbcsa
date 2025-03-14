# app/controllers/cursos/estudiantes_controller.rb
class Cursos::EstudiantesController < ApplicationController
  before_action :authenticate_usuario!
  before_action :set_curso
  before_action :verify_profesor_access
  
  # POST /cursos/:curso_id/estudiantes/add
  def add
    @usuario = Usuario.find_by(email: params[:email])
    
    if @usuario.nil?
      redirect_to @curso, alert: 'Usuario no encontrado con ese correo electrónico.'
      return
    end
    
    if @curso.estudiantes.include?(@usuario)
      redirect_to @curso, alert: 'El estudiante ya está inscrito en este curso.'
      return
    end
    
    @curso.estudiantes << @usuario
    redirect_to @curso, notice: 'Estudiante añadido exitosamente al curso.'
  end
  
  # DELETE /cursos/:curso_id/estudiantes/remove
  def remove
    @usuario = Usuario.find(params[:usuario_id])
    @curso.estudiantes.delete(@usuario)
    
    respond_to do |format|
      format.html { redirect_to @curso, notice: 'Estudiante removido exitosamente del curso.' }
      format.js
    end
  end
  
  private
  
  def set_curso
    @curso = Curso.find(params[:curso_id])
  end
  
  def verify_profesor_access
    redirect_to cursos_path, alert: 'No tiene permisos para gestionar este curso.' unless @curso.profesor?(current_usuario) || current_usuario.admin?
  end
end