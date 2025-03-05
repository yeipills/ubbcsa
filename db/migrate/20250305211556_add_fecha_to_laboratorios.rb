class AddFechaToLaboratorios < ActiveRecord::Migration[7.1]
  def change
    add_column :laboratorios, :fecha, :datetime
  end
end
