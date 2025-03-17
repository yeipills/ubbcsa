#!/bin/bash

# Script para iniciar ttyd para el laboratorio de ciberseguridad UBB

# Configurar variables de entorno
TTYD_PORT=${TTYD_PORT:-3000}
DEFAULT_USER=${DEFAULT_USER:-kali}
DEFAULT_PASS=${DEFAULT_PASS:-kali}

# Iniciar servicio SSH
echo "Iniciando servicio SSH..."
service ssh start || {
  echo "Error: No se pudo iniciar el servicio SSH"
  exit 1
}

# Verificar la instalación de ttyd
if ! command -v ttyd &> /dev/null; then
  echo "Error: ttyd no está instalado"
  exit 1
fi

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
else
  # Usar el usuario por defecto
  SSH_USER="$DEFAULT_USER"
fi

# Configurar mensaje de bienvenida
cat > /etc/motd << EOF
 _    _ ______ ____     _____ _______  _____            _____  
| |  | |  ____|  _ \   / ____|__   __||  __ \     /\   |  __ \ 
| |  | | |__  | |_) | | |       | |   | |  | |   /  \  | |__) |
| |  | |  __| |  _ <  | |       | |   | |  | |  / /\ \ |  _  / 
| |__| | |____| |_) | | |____   | |   | |__| | / ____ \| | \ \ 
 \____/|______|____/   \_____|  |_|   |_____/ /_/    \_\_|  \_\
                                                               
          Laboratorio de Ciberseguridad UBB - v3.0            
                                                               
EOF

# Configurar alias útiles para ciberseguridad
cat > /etc/bash.bashrc.local << EOF
# Configuración personalizada para UBB CyberSec Labs
export PS1='\[\033[01;32m\]\u@ubbcsa\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
export TERM=xterm-256color
export PATH=\$PATH:/usr/local/bin

# Alias útiles para ciberseguridad
alias ls='ls --color=auto'
alias ll='ls -la'
alias grep='grep --color=auto'
alias scan='nmap -sV -sC'
alias portscan='nmap -p-'
alias checksec='find / -perm -4000 -type f 2>/dev/null'
alias hashid='hash-identifier'
alias sniff='sudo tcpdump -i any -w capture.pcap'
alias webcheck='curl -I'

# Mostrar mensaje de bienvenida
cat /etc/motd
echo ""
echo "Bienvenido al Laboratorio de Ciberseguridad UBB"
echo "Escribe 'help' para ver los comandos disponibles"
echo ""
EOF

# Usar nuestra configuración personalizada
cp /etc/bash.bashrc.local /etc/bash.bashrc

# Información sobre inicio de ttyd
echo "============================================="
echo "Iniciando ttyd en puerto $TTYD_PORT"
echo "Usuario: $SSH_USER"
echo "============================================="

# Iniciar ttyd con opciones mejoradas
exec ttyd -p $TTYD_PORT \
  -t backgroundColor=#1a1a1a \
  -t theme=monokai \
  -t fontSize=14 \
  -t titleFixed='UBB Cybersecurity Lab' \
  -W \
  bash -c "cd /home/kali && cat /etc/motd && bash --rcfile /etc/bash.bashrc"