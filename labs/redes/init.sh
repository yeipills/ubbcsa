#!/bin/bash

# Configuración del laboratorio de redes
LAB_DIR="/home/kali/labs/redes"

# Crear estructura de archivos
mkdir -p $LAB_DIR/{captures,analysis,tools}

# Configurar red de pruebas
docker network create lab-network

# Desplegar servicios de red
docker run -d \
  --name web-server \
  --network lab-network \
  nginx

docker run -d \
  --name ftp-server \
  --network lab-network \
  -p 21:21 \
  fauria/vsftpd

# Crear guía del laboratorio
cat > $LAB_DIR/README.md << EOF
# Laboratorio de Análisis de Redes

Objetivos:
1. Capturar y analizar tráfico de red
2. Identificar protocolos y servicios
3. Detectar anomalías en el tráfico
4. Realizar análisis de seguridad de red

Herramientas:
- Wireshark
- tcpdump
- netcat
- iptables

Ejercicios:
1. Capturar tráfico HTTP
2. Analizar conexiones FTP
3. Detectar escaneos de puertos
4. Identificar tráfico malicioso
EOF