#!/bin/bash

# Script para iniciar ttyd con configuración para el laboratorio UBB de ciberseguridad

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
  echo "Error: ttyd no está instalado correctamente"
  exit 1
fi

ttyd_version=$(ttyd --version 2>&1 | head -n 1)
echo "ttyd version: $ttyd_version"

# Asegurarse de que los directorios existen
mkdir -p /home/kali/lab_data /home/kali/logs
chown -R kali:kali /home/kali/lab_data /home/kali/logs

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
  TARGET_USER="$USERNAME"
else
  # Usar el usuario por defecto
  TARGET_USER="$DEFAULT_USER"
fi

# Configurar el entorno bash para todos los usuarios
cat > /etc/bash.bashrc.ttyd << EOF
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
cp /etc/bash.bashrc.ttyd /etc/bash.bashrc

# Personalizar la configuración de tmux para una mejor experiencia de terminal
cat > /etc/tmux.conf << EOF
# Mejorar colores
set -g default-terminal "screen-256color"

# Aumentar historia de comandos
set -g history-limit 10000

# Configuración para ratón
set -g mouse on

# Mejorar interfaz de usuario
set -g status-bg black
set -g status-fg white
set -g status-left-length 30
set -g status-left '#[fg=green](#S) '
set -g status-right '#[fg=yellow]#(cut -d " " -f 1-3 /proc/loadavg)#[default] #[fg=white]%H:%M#[default]'
EOF

# Crear script de inicialización de tmux
cat > /usr/local/bin/init-tmux.sh << 'EOF'
#!/bin/bash
# Script más simple para inicializar bash con mensaje de bienvenida

cat /etc/motd
echo ""
echo "Terminal interactiva activada. Bienvenido a UBB CyberSec Labs."
echo ""

# Simplemente ejecutar bash para una experiencia más directa
exec bash
EOF
chmod +x /usr/local/bin/init-tmux.sh

# Información sobre inicio de ttyd
echo "============================================="
echo "Iniciando ttyd en puerto $TTYD_PORT"
echo "Usuario: $TARGET_USER"
echo "============================================="

# Opciones para ttyd
OPTIONS="-p $TTYD_PORT"
OPTIONS="$OPTIONS -t backgroundColor=#1a1a1a"
OPTIONS="$OPTIONS -t theme=monokai"
OPTIONS="$OPTIONS -t fontSize=16"
OPTIONS="$OPTIONS -t titleFixed='UBB Cybersecurity Lab'"
OPTIONS="$OPTIONS -S"  # Enable SSL, using auto-generated cert
OPTIONS="$OPTIONS -m 1" # Max clients per browser
OPTIONS="$OPTIONS --writable"   # Habilitar escritura (importante para terminal interactiva)

# Iniciar ttyd con tmux para persistencia de sesiones
echo "Ejecutando: ttyd $OPTIONS sudo -u $TARGET_USER /usr/local/bin/init-tmux.sh"
cd /home/$TARGET_USER
# Iniciar ttyd con opciones mínimas para asegurar que funcione
exec ttyd -p $TTYD_PORT -w bash