class CreateLogros < ActiveRecord::Migration[7.1]
  def change
    create_table :logros do |t|
      t.references :usuario, null: false, foreign_key: true
      t.string :tipo, null: false
      t.string :titulo, null: false
      t.text :descripcion
      t.jsonb :metadatos, default: {}
      t.datetime :otorgado_en, null: false, default: -> { 'CURRENT_TIMESTAMP' }
      t.boolean :visible, default: true

      t.timestamps
    end
    
    add_index :logros, [:usuario_id, :tipo, :titulo], unique: true
  end
end