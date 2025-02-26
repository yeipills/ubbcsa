class AjustarEstructuraTablas < ActiveRecord::Migration[7.1]
  def change
    # Verificar si la tabla laboratorios existe antes de intentar modificarla
    if table_exists?(:laboratorios)
      # Ajustes para laboratorios
      add_column :laboratorios, :duracion_estimada, :integer unless column_exists?(:laboratorios, :duracion_estimada)
      add_column :laboratorios, :objetivos, :text unless column_exists?(:laboratorios, :objetivos)
      add_column :laboratorios, :requisitos, :text unless column_exists?(:laboratorios, :requisitos)
      add_column :laboratorios, :activo, :boolean unless column_exists?(:laboratorios, :activo)
    end

    # Verificar si la tabla sesion_laboratorios existe antes de intentar modificarla
    if table_exists?(:sesion_laboratorios)
      # Asegurar tipos de datos correctos
      change_column :sesion_laboratorios, :resultados, :json if column_exists?(:sesion_laboratorios, :resultados)
      change_column :sesion_laboratorios, :puntuacion, :integer if column_exists?(:sesion_laboratorios, :puntuacion)
    end
  end
end