#!/bin/bash

# Este script crea un usuario dinámico para la sesión de terminal
# Uso: create_dynamic_user.sh username user_id session_id

USERNAME=$1
USER_ID=$2
SESSION_ID=$3

if [ -z "$USERNAME" ] || [ -z "$USER_ID" ] || [ -z "$SESSION_ID" ]; then
  echo "Error: Faltan parámetros. Uso: create_dynamic_user.sh username user_id session_id"
  exit 1
fi

# Verificar si el usuario ya existe
if id "$USERNAME" &>/dev/null; then
  echo "El usuario $USERNAME ya existe"
else
  # Crear usuario
  useradd -m -s /bin/bash "$USERNAME"
  # Establecer contraseña igual al username
  echo "$USERNAME:$USERNAME" | chpasswd
  # Agregar al grupo sudo
  usermod -aG sudo "$USERNAME"
  
  # Crear directorios necesarios
  mkdir -p /home/$USERNAME/lab_data
  mkdir -p /home/$USERNAME/logs
  
  # Configurar perfil
  echo "export PS1='\[\033[01;32m\]\u@lab\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]$ '" >> /home/$USERNAME/.bashrc
  echo "export SESSION_ID=$SESSION_ID" >> /home/$USERNAME/.bashrc
  echo "export USER_ID=$USER_ID" >> /home/$USERNAME/.bashrc
  echo "cd ~/lab_data" >> /home/$USERNAME/.bashrc
  
  # Establecer permisos
  chown -R $USERNAME:$USERNAME /home/$USERNAME
  
  echo "Usuario $USERNAME creado exitosamente"
fi

exit 0