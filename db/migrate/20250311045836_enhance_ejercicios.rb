class EnhanceEjercicios < ActiveRecord::Migration[7.1]
  def change
    change_column :ejercicios, :parametros, :jsonb, default: {}, null: false
    add_column :ejercicios, :puntos, :integer, default: 10
    add_column :ejercicios, :obligatorio, :boolean, default: true
    add_column :ejercicios, :orden, :integer
    add_column :ejercicios, :pista, :text
  end
end