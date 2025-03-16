#!/bin/bash

# Script para iniciar Wetty con configuración simple y directa
# siguiendo las recomendaciones oficiales de Wetty

# Configurar variables de entorno
WETTY_PORT=${WETTY_PORT:-3000}
SSH_AUTH=${SSH_AUTH:-password}
DEFAULT_USER=${DEFAULT_USER:-kali}
DEFAULT_PASS=${DEFAULT_PASS:-kali}

# Iniciar servicio SSH
echo "Iniciando servicio SSH..."
service ssh start || {
  echo "Error: No se pudo iniciar el servicio SSH"
  exit 1
}

# Verificar la instalación de Wetty
wetty_version=$(wetty --version 2>/dev/null || echo "Wetty no instalado")
echo "Wetty version: $wetty_version"

# Asegurarse de que los directorios existen
mkdir -p /home/kali/lab_data /home/kali/logs

# Comprobar si se especifica un usuario personalizado
if [ -n "$USERNAME" ]; then
  echo "Configurando usuario personalizado: $USERNAME"
  
  # Verificar si el usuario ya existe
  if ! id "$USERNAME" &>/dev/null; then
    echo "Creando usuario: $USERNAME"
    useradd -m -s /bin/bash -G sudo "$USERNAME"
    echo "$USERNAME:$USERNAME" | chpasswd
    mkdir -p /home/$USERNAME/lab_data
    chown -R $USERNAME:$USERNAME /home/$USERNAME
  fi
  
  # Usar el usuario personalizado
  SSH_USER="$USERNAME"
  SSH_PASS="$USERNAME"
else
  # Usar el usuario por defecto
  SSH_USER="$DEFAULT_USER"
  SSH_PASS="$DEFAULT_PASS"
fi

# Configurar mensaje de bienvenida
cat > /etc/motd << EOF
 _    _ ______ ____     _____ _______ _____            _____  
| |  | |  ____|  _ \   / ____|__   __/ ____|     /\   |  __ \ 
| |  | | |__  | |_) | | |       | | | |         /  \  | |__) |
| |  | |  __| |  _ <  | |       | | | |        / /\ \ |  _  / 
| |__| | |____| |_) | | |____   | | | |____   / ____ \| | \ \ 
 \____/|______|____/   \_____|  |_|  \_____| /_/    \_\_|  \_\\

         LABORATORIO DE CIBERSEGURIDAD UBB

         Usuario: $SSH_USER
         Sesión: TMUX
EOF

# Configurar el entorno bash para todos los usuarios
cat > /etc/bash.bashrc.wetty << EOF
# Configuración personalizada para Laboratorios UBB
export PS1='\[\033[01;32m\]\u@ubbcsa\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
export TERM=xterm-256color
export PATH=\$PATH:/usr/local/bin
export HISTTIMEFORMAT="%F %T "
export HISTCONTROL=ignoredups

# Alias útiles
alias ls='ls --color=auto'
alias ll='ls -la'
alias grep='grep --color=auto'
alias clean='clear'

# Mensaje de bienvenida
cat /etc/motd
EOF

# Reemplazar la configuración bash para nuevos usuarios
cp /etc/bash.bashrc.wetty /etc/bash.bashrc

# Información sobre inicio de Wetty
echo "============================================="
echo "Iniciando Wetty en puerto $WETTY_PORT"
echo "Usuario SSH: $SSH_USER"
echo "Autenticación: $SSH_AUTH"
echo "============================================="

# Opciones para Wetty basadas en documentación oficial
OPTIONS="--port $WETTY_PORT"
OPTIONS="$OPTIONS --host 0.0.0.0"
OPTIONS="$OPTIONS --title 'UBB Cybersecurity Lab'"
OPTIONS="$OPTIONS --base /wetty"
OPTIONS="$OPTIONS --ssh-host localhost"
OPTIONS="$OPTIONS --ssh-port 22"
OPTIONS="$OPTIONS --ssh-user $SSH_USER"
OPTIONS="$OPTIONS --ssh-auth $SSH_AUTH"
OPTIONS="$OPTIONS --ssh-pass $SSH_PASS"
OPTIONS="$OPTIONS --allow-iframe"
# Opción para comando personalizado si se requiere
[ -n "$CUSTOM_COMMAND" ] && OPTIONS="$OPTIONS --command '$CUSTOM_COMMAND'"

# Verificar si Wetty está instalado correctamente
if ! command -v wetty &> /dev/null; then
  echo "ERROR: Wetty no está instalado correctamente"
  echo "Intentando reinstalar Wetty..."
  npm install -g wetty@2.7.0
fi

# Iniciar Wetty siguiendo la forma recomendada en la documentación
echo "Ejecutando: wetty $OPTIONS"
exec wetty $OPTIONS