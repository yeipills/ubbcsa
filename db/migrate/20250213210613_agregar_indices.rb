class AgregarIndices < ActiveRecord::Migration[7.1]
  def change
    # Verificar si la tabla laboratorios existe antes de modificar sus índices
    if table_exists?(:laboratorios)
      # Ajustar índices en laboratorios
      remove_index :laboratorios, name: "index_laboratorios_on_curso_id_and_activo" if index_exists?(:laboratorios, [:curso_id, :activo])
      add_index :laboratorios, :curso_id unless index_exists?(:laboratorios, :curso_id)
    end

    # Verificar si la tabla sesion_laboratorios existe antes de modificar sus índices
    if table_exists?(:sesion_laboratorios)
      # Ajustar índices en sesion_laboratorios
      remove_index :sesion_laboratorios, name: "idx_on_laboratorio_id_usuario_id_estado_5a024dbdf7" if index_exists?(:sesion_laboratorios, [:laboratorio_id, :usuario_id, :estado])
      add_index :sesion_laboratorios, [:laboratorio_id, :usuario_id] unless index_exists?(:sesion_laboratorios, [:laboratorio_id, :usuario_id])
    end
  end
end