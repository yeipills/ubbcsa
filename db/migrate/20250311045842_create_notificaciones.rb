class CreateNotificaciones < ActiveRecord::Migration[7.1]
  def change
    create_table :notificaciones do |t|
      t.references :usuario, null: false, foreign_key: true
      t.references :actor, foreign_key: { to_table: :usuarios }, null: true
      t.references :notificable, polymorphic: true, null: true
      
      t.integer :tipo, null: false, default: 0
      t.integer :nivel, null: false, default: 0
      t.string :titulo, null: false
      t.text :contenido, null: false
      t.boolean :leida, default: false
      t.datetime :leida_en
      t.jsonb :datos_adicionales, default: {}
      t.boolean :mostrar_web, default: true
      t.boolean :mostrar_email, default: false
      t.boolean :mostrar_movil, default: true
      t.string :accion_url
      t.string :icono

      t.timestamps
    end
    
    add_index :notificaciones, [:usuario_id, :leida]
    add_index :notificaciones, [:notificable_type, :notificable_id]
  end
end