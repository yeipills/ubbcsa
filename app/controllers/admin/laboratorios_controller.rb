# app/controllers/admin/laboratorios_controller.rb
class Admin::LaboratoriosController < ApplicationController
  before_action :authenticate_admin!
  before_action :set_laboratorio, only: [:show, :edit, :update, :destroy]

  def index
    @laboratorios = Laboratorio.includes(:metrica_laboratorios)
                              .order(created_at: :desc)
  end

  def show
    @laboratorio = Laboratorio.find(params[:id])
    @sesiones_activas = @laboratorio.sesion_laboratorios.active.includes(:usuario)
    @metricas_recientes = @laboratorio.metrica_laboratorios.last(24.hours)
    @estadisticas = @laboratorio.calcular_estadisticas
  end

  def new
    @laboratorio = Laboratorio.new
  end

  def edit
  end
end