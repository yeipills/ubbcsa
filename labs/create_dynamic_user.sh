#!/bin/bash

# Script para crear un usuario dinámico en el contenedor de laboratorio
# Uso: create_dynamic_user.sh username user_id session_id

# Parámetros
USERNAME=$1
USER_ID=$2
SESSION_ID=$3

# Validación de parámetros
if [ -z "$USERNAME" ] || [ -z "$USER_ID" ] || [ -z "$SESSION_ID" ]; then
  echo "Error: Faltan parámetros. Uso: create_dynamic_user.sh username user_id session_id"
  exit 1
fi

# Normalizar nombre de usuario (solo caracteres alfanuméricos)
USERNAME=$(echo "$USERNAME" | tr -cd '[:alnum:]')

# Verificar si ya existe el usuario
if id "$USERNAME" &>/dev/null; then
  echo "El usuario $USERNAME ya existe"
  
  # Verificar que tenga la configuración correcta aunque exista
  # Configurar perfil si no está actualizado
  if ! grep -q "SESSION_ID=$SESSION_ID" /home/$USERNAME/.bashrc; then
    echo "Actualizando configuración del usuario existente..."
    echo "export SESSION_ID=$SESSION_ID" >> /home/$USERNAME/.bashrc
    echo "export USER_ID=$USER_ID" >> /home/$USERNAME/.bashrc
  fi
  
  # Asegurar que existan los directorios necesarios
  mkdir -p /home/$USERNAME/lab_data /home/$USERNAME/logs
  chown -R $USERNAME:$USERNAME /home/$USERNAME/lab_data /home/$USERNAME/logs
  
  exit 0
fi

# Crear usuario si no existe
echo "Creando nuevo usuario: $USERNAME"
useradd -m -s /bin/bash -G sudo "$USERNAME"

# Establecer contraseña igual al nombre de usuario (para facilitar el acceso)
echo "$USERNAME:$USERNAME" | chpasswd

# Crear directorios de trabajo
mkdir -p /home/$USERNAME/lab_data
mkdir -p /home/$USERNAME/logs

# Configurar perfil y variables de entorno
cat > /home/$USERNAME/.bashrc << EOF
# .bashrc personalizado para laboratorios UBB
export PS1='\[\033[01;32m\]\u@cyberlabs\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]$ '
export PATH=\$PATH:/usr/local/bin
export TERM=xterm-256color
export HISTTIMEFORMAT="%F %T "
export HISTCONTROL=ignoredups
export HISTSIZE=1000
export HISTFILESIZE=2000
export SESSION_ID=$SESSION_ID
export USER_ID=$USER_ID

# Alias útiles
alias ls='ls --color=auto'
alias ll='ls -la'
alias la='ls -A'
alias l='ls -CF'
alias grep='grep --color=auto'
alias cls='clear'

# Mensaje de bienvenida
echo "╔════════════════════════════════════════════════════════╗"
echo "║           Bienvenido al Laboratorio UBB CSA            ║"
echo "║                                                        ║"
echo "║  Usuario: $USERNAME                                    ║"
echo "║  Sesión: $SESSION_ID                                   ║"
echo "║                                                        ║"
echo "║  Usa 'help-lab' para ver comandos disponibles          ║"
echo "╚════════════════════════════════════════════════════════╝"

# Ir al directorio de datos del laboratorio
cd ~/lab_data
EOF

# Crear función de ayuda del laboratorio
cat > /home/$USERNAME/.help-lab << EOF
#!/bin/bash
echo "╔════════════════════════════════════════════════════════╗"
echo "║           Comandos de Ayuda del Laboratorio            ║"
echo "║                                                        ║"
echo "║  check-tools - Verificar herramientas disponibles      ║"
echo "║  lab-status  - Mostrar estado del laboratorio          ║"
echo "║  save-work   - Guardar trabajo actual                  ║"
echo "║  reset-lab   - Reiniciar el entorno del laboratorio    ║"
echo "║                                                        ║"
echo "╚════════════════════════════════════════════════════════╝"
EOF

chmod +x /home/$USERNAME/.help-lab

# Agregar alias para los comandos del laboratorio
cat >> /home/$USERNAME/.bashrc << EOF
# Comandos específicos del laboratorio
alias help-lab='~/.help-lab'
alias check-tools='which nmap wireshark metasploit-framework 2>/dev/null || echo "No disponible"'
alias lab-status='echo "Sesión $SESSION_ID activa para usuario $USER_ID"'
alias save-work='tar -czf ~/lab_data/backup-\$(date +%Y%m%d%H%M%S).tar.gz ~/lab_data'
alias reset-lab='rm -rf ~/lab_data/* && echo "Laboratorio reiniciado"'
EOF

# Configurar permisos
chown -R $USERNAME:$USERNAME /home/$USERNAME
chmod 750 /home/$USERNAME

echo "Usuario $USERNAME creado exitosamente"
exit 0