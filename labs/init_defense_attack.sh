#!/bin/bash
# Script para inicializar escenarios de defensa/ataque

MODE=$1  # "defensor" o "atacante"
SESSION_ID=$2
USER_ID=$3

if [ -z "$MODE" ] || [ -z "$SESSION_ID" ] || [ -z "$USER_ID" ]; then
  echo "Uso: $0 [defensor|atacante] SESSION_ID USER_ID"
  exit 1
fi

echo "Iniciando entorno $MODE para sesión $SESSION_ID"

# Configurar entorno según el modo
case "$MODE" in
  "defensor")
    # Instalar herramientas de defensa
    apt-get update
    apt-get install -y fail2ban iptables-persistent snort
    
    # Configurar firewall básico
    iptables -F
    iptables -P INPUT DROP
    iptables -P FORWARD DROP
    iptables -P OUTPUT ACCEPT
    iptables -A INPUT -i lo -j ACCEPT
    iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
    iptables -A INPUT -p tcp --dport 22 -j ACCEPT  # SSH
    iptables -A INPUT -p tcp --dport 80 -j ACCEPT  # HTTP
    iptables -A INPUT -p tcp --dport 443 -j ACCEPT # HTTPS
    
    # Configurar logs
    touch /var/log/security.log
    echo "* * * * * /usr/bin/env bash -c 'tail -n 20 /var/log/auth.log > /home/kali/data/auth_log.txt'" > /etc/cron.d/security_logs
    
    echo "Entorno defensor configurado"
    ;;
    
  "atacante")
    # Instalar herramientas de penetración
    apt-get update
    apt-get install -y nmap hydra metasploit-framework sqlmap
    
    # Configurar objetivos en /etc/hosts
    echo "172.20.0.10 target-host vulnerable-server" >> /etc/hosts
    
    # Crear directorio para herramientas
    mkdir -p /home/kali/tools
    cd /home/kali/tools
    
    # Descargar scripts y herramientas comunes
    git clone https://github.com/danielmiessler/SecLists.git
    
    echo "Entorno atacante configurado"
    ;;
    
  *)
    echo "Modo no válido: $MODE"
    exit 1
    ;;
esac

# Configurar entorno común
mkdir -p /home/kali/data/scenarios
echo "Escenario $MODE iniciado" > /home/kali/data/scenarios/info.txt
echo "SESSION_ID=$SESSION_ID" >> /home/kali/data/scenarios/info.txt
echo "USER_ID=$USER_ID" >> /home/kali/data/scenarios/info.txt
echo "TIMESTAMP=$(date)" >> /home/kali/data/scenarios/info.txt

# Configurar metas según escenario
if [ "$MODE" = "defensor" ]; then
  cat > /home/kali/data/scenarios/objetivos.txt << EOF
1. Configurar correctamente el firewall para bloquear ataques
2. Implementar sistema de detección de intrusiones
3. Configurar fail2ban para detener ataques de fuerza bruta
4. Mantener los servicios web operativos
5. Detectar e informar intentos de ataque
EOF
else
  cat > /home/kali/data/scenarios/objetivos.txt << EOF
1. Realizar reconocimiento completo del servidor objetivo
2. Identificar servicios vulnerables
3. Explotar una vulnerabilidad de acceso
4. Elevar privilegios
5. Mantener acceso persistente
EOF
fi

echo "Inicialización completa para $MODE"
exit 0