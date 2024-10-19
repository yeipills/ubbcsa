# frozen_string_literal: true

class AddDeviseToUsers < ActiveRecord::Migration[7.1]
  def self.up
    change_table :users do |t|
      ## Database authenticatable
      # La columna 'email' ya existe, no la necesitamos aquí.
      # t.string :email,              null: false, default: ""
      
      t.string :encrypted_password, null: false, default: ""

      ## Recoverable
      t.string   :reset_password_token
      t.datetime :reset_password_sent_at

      ## Rememberable
      t.datetime :remember_created_at

      ## Trackable (puedes habilitar estos campos si los necesitas)
      # t.integer  :sign_in_count, default: 0, null: false
      # t.datetime :current_sign_in_at
      # t.datetime :last_sign_in_at
      # t.string   :current_sign_in_ip
      # t.string   :last_sign_in_ip

      ## Confirmable (habilítalo si usas confirmación de email)
      # t.string   :confirmation_token
      # t.datetime :confirmed_at
      # t.datetime :confirmation_sent_at
      # t.string   :unconfirmed_email # Only if using reconfirmable

      ## Lockable (puedes habilitarlo si necesitas bloqueo de cuentas)
      # t.integer  :failed_attempts, default: 0, null: false # Only if lock strategy is :failed_attempts
      # t.string   :unlock_token # Only if unlock strategy is :email or :both
      # t.datetime :locked_at

      # Si no tienes timestamps en tu tabla original, puedes agregarlos aquí.
      # t.timestamps null: false
    end

    # Quita el índice de 'email' si ya existe uno
    # add_index :users, :email,                unique: true
    add_index :users, :reset_password_token, unique: true
    # add_index :users, :confirmation_token,   unique: true
    # add_index :users, :unlock_token,         unique: true
  end

  def self.down
    # Este código elimina los campos agregados por Devise
    change_table :users do |t|
      t.remove :encrypted_password, :reset_password_token, :reset_password_sent_at, :remember_created_at
    end
  end
end
