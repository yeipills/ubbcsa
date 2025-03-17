#!/bin/bash

# Variables básicas
TTYD_PORT=3000

# Crear archivo de bienvenida personalizado
cat > /etc/ubbcsa_banner << EOF
  
 ██╗   ██╗██████╗ ██████╗      ██████╗███████╗ █████╗ 
 ██║   ██║██╔══██╗██╔══██╗    ██╔════╝██╔════╝██╔══██╗
 ██║   ██║██████╔╝██████╔╝    ██║     ███████╗███████║
 ██║   ██║██╔══██╗██╔══██╗    ██║     ╚════██║██╔══██║
 ╚██████╔╝██████╔╝██████╔╝    ╚██████╗███████║██║  ██║
  ╚═════╝ ╚═════╝ ╚═════╝      ╚═════╝╚══════╝╚═╝  ╚═╝
                                                      
  █▀▀ █ █▄▄ █▀▀ █▀█ █▀ █▀▀ █▀▀ █░█ █▀█ █ ▀█▀ █▄█   █░░ ▄▀█ █▄▄ █▀
  █▄▄ █ █▄█ ██▄ █▀▄ ▄█ ██▄ █▄█ █▄█ █▀▄ █ ░█░ ░█░   █▄▄ █▀█ █▄█ ▄█
  
                 Universidad del Bío-Bío - v3.0
  
=========================================================================
[+] Bienvenido al Laboratorio de Ciberseguridad UBB
[+] Escribe 'help' para ver los comandos disponibles
[+] IP de la máquina: \$(hostname -I | awk '{print \$1}')
=========================================================================

EOF

# Desactivar motd estándar
touch /etc/motd

# Verificar instalación
if ! command -v ttyd &> /dev/null; then
  echo "Error: ttyd no está instalado"
  exit 1
fi

# Configurar alias útiles para ciberseguridad
cat > /etc/bash.bashrc.local << EOF
# Configuración personalizada para UBB CyberSec Labs
export PS1='\[\033[38;5;75m\]┌──[\[\033[38;5;213m\]\u\[\033[38;5;75m\]@\[\033[38;5;77m\]UBBCSA\[\033[38;5;75m\]]\[\033[38;5;75m\]-[\[\033[38;5;214m\]\w\[\033[38;5;75m\]]\n\[\033[38;5;75m\]└─\[\033[38;5;83m\]$ \[\033[0m\]'
export TERM=xterm-256color
export PATH=\$PATH:/usr/local/bin
export HISTTIMEFORMAT="%F %T "

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
alias exploits='searchsploit'
alias help='echo -e "\n\033[1;97mComandos disponibles:\033[0m\n\033[1;92mscan [ip]\033[0m - Escaneo básico de puertos con nmap\n\033[1;92mportscan [ip]\033[0m - Escaneo completo de puertos\n\033[1;92mchecksec\033[0m - Buscar binarios con permisos SUID\n\033[1;92msniff\033[0m - Iniciar captura de paquetes\n\033[1;92mwebcheck [url]\033[0m - Verificar encabezados HTTP\n\033[1;92mexploits [término]\033[0m - Buscar exploits"'
EOF

# Usar nuestra configuración personalizada
cp /etc/bash.bashrc.local /etc/bash.bashrc

# Mostrar mensaje
echo "Iniciando ttyd en puerto $TTYD_PORT..."

# Crear un script de inicio simple que mostrará el banner una sola vez
cat > /tmp/start-terminal.sh << EOF
#!/bin/bash
cd /home/kali
cat /etc/ubbcsa_banner
bash --rcfile /etc/bash.bashrc
EOF

chmod +x /tmp/start-terminal.sh

# Iniciar ttyd con opciones mejoradas
exec ttyd -p $TTYD_PORT \
  -t backgroundColor=#1a1a1a \
  -t theme=monokai \
  -t fontSize=14 \
  -t titleFixed='UBBCSA Terminal | Cybersecurity Lab' \
  -t fontFamily='Fira Code, monospace' \
  -W \
  /tmp/start-terminal.sh