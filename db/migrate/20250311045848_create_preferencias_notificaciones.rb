class CreatePreferenciasNotificaciones < ActiveRecord::Migration[7.1]
  def change
    create_table :preferencias_notificaciones do |t|
      t.references :usuario, null: false, foreign_key: true
      t.boolean :email_habilitado, default: true
      t.boolean :web_habilitado, default: true
      t.boolean :movil_habilitado, default: true
      
      # Configuración por tipo de notificación
      t.jsonb :configuracion_tipos, default: {
        sistema: { web: true, email: true, movil: true },
        laboratorio: { web: true, email: false, movil: true },
        curso: { web: true, email: true, movil: true },
        quiz: { web: true, email: true, movil: true },
        logro: { web: true, email: false, movil: true },
        ejercicio: { web: true, email: false, movil: true },
        mensaje: { web: true, email: true, movil: true },
        alerta_seguridad: { web: true, email: true, movil: true }
      }
      
      # Programación de resúmenes
      t.boolean :resumen_diario, default: false
      t.boolean :resumen_semanal, default: true
      t.string :hora_resumen, default: '08:00'
      
      t.timestamps
    end
    
    add_index :preferencias_notificaciones, :usuario_id, unique: true
  end
end