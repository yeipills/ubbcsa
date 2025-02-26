# app/controllers/quizzes_controller.rb
class QuizzesController < ApplicationController
  before_action :authenticate_usuario!
  before_action :set_curso, only: [:new, :create]
  before_action :set_quiz, only: [:show, :edit, :update, :destroy]
  before_action :verify_role_access, only: [:new, :create, :edit, :update, :destroy]

  def index
    @quizzes = if current_usuario.profesor?
      Quiz.includes(:curso, :laboratorio)
          .where(curso_id: current_usuario.cursos_como_profesor.pluck(:id))
    else
      Quiz.activos.includes(:curso, :laboratorio)
          .where(curso_id: current_usuario.cursos.pluck(:id))
    end
  end

  def show
    @preguntas = @quiz.preguntas.includes(:opciones)
    @intento = current_usuario.intentos_quiz.find_or_initialize_by(quiz: @quiz) unless current_usuario.profesor?
  end

  def new
    if @curso.nil?
      redirect_to cursos_path, alert: 'Debe seleccionar un curso para crear un quiz'
      return
    end
    @quiz = @curso.quizzes.build
    @laboratorios = @curso.laboratorios
  end

  def create
    @quiz = @curso.quizzes.build(quiz_params)
    @quiz.usuario = current_usuario

    if @quiz.save
      redirect_to quiz_path(@quiz), notice: 'Quiz creado exitosamente.'
    else
      @laboratorios = @curso.laboratorios
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @laboratorios = @quiz.curso.laboratorios
  end

  def update
    if @quiz.update(quiz_params)
      redirect_to quiz_path(@quiz), notice: 'Quiz actualizado exitosamente.'
    else
      @laboratorios = @quiz.curso.laboratorios
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @quiz.destroy
    redirect_to curso_quizzes_path(@quiz.curso), notice: 'Quiz eliminado exitosamente.'
  end

  private

  def set_curso
    @curso = Curso.find(params[:curso_id]) if params[:curso_id]
  end

  def set_quiz
    @quiz = Quiz.find(params[:id])
  end

  def quiz_params
    params.require(:quiz).permit(
      :titulo, 
      :descripcion, 
      :laboratorio_id,
      :estado, 
      :tiempo_limite, 
      :intentos_permitidos,
      :fecha_inicio, 
      :fecha_fin
    )
  end

  def verify_role_access
    unless current_usuario.profesor? || current_usuario.admin?
      redirect_to quizzes_path, alert: 'No tienes permiso para realizar esta acción'
    end
  end
end