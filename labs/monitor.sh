#!/bin/bash

# Script para monitorear actividad en el laboratorio
LOG_FILE="/home/kali/logs/session.log"

# Función para registrar comando
log_command() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> $LOG_FILE
}

# Configurar el hook para registrar comandos
echo 'export PROMPT_COMMAND="log_command \$(history 1)"' >> /home/kali/.bashrc