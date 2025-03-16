#!/bin/bash

# Variables básicas
TTYD_PORT=3000

# Crear mensaje de bienvenida
cat > /etc/motd << EOF
 _    _ ______ ____     _____ _______  _____            _____  
| |  | |  ____|  _ \   / ____|__   __||  __ \     /\   |  __ \ 
| |  | | |__  | |_) | | |       | |   | |  | |   /  \  | |__) |
| |  | |  __| |  _ <  | |       | |   | |  | |  / /\ \ |  _  / 
| |__| | |____| |_) | | |____   | |   | |__| | / ____ \| | \ \ 
 \____/|______|____/   \_____|  |_|   |_____/ /_/    \_\_|  \_\
                                                               
          Laboratorio de Ciberseguridad UBB - v3.0            
                                                               
EOF

# Verificar instalación
if ! command -v ttyd &> /dev/null; then
  echo "Error: ttyd no está instalado"
  exit 1
fi

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

# Mostrar mensaje
echo "Iniciando ttyd en puerto $TTYD_PORT..."

# Iniciar ttyd con opciones mejoradas
exec ttyd -p $TTYD_PORT \
  -t backgroundColor=#1a1a1a \
  -t theme=monokai \
  -t fontSize=14 \
  -t titleFixed='UBB Cybersecurity Lab' \
  -W \
  bash -c "cd /home/kali && cat /etc/motd && bash --rcfile /etc/bash.bashrc"