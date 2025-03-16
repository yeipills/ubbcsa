#!/bin/bash

# Script de verificación de salud mejorado para el contenedor Wetty
# basado en la documentación oficial de WeTTY

# Verificar si el proceso de Wetty está ejecutándose
if ! ps aux | grep -v grep | grep -q "wetty"; then
  echo "Error: No se encontró proceso Wetty en ejecución"
  exit 1
fi

# Verificar si el puerto está escuchando
PORT="${WETTY_PORT:-3000}"
if ! netcat -z localhost $PORT; then
  echo "Error: Puerto $PORT no está escuchando"
  exit 1
fi

# Verificar si el servidor SSH está ejecutándose
if ! ps aux | grep -v grep | grep -q "sshd"; then
  echo "Error: No se encontró proceso SSH en ejecución"
  exit 1
fi

# Verificar si se puede acceder a la página web de Wetty
if ! curl -s -f "http://localhost:$PORT/wetty" > /dev/null; then
  echo "Error: No se puede acceder a la interfaz web de Wetty en puerto $PORT"
  exit 1
fi

# Verificar la versión de Node.js
NODE_VERSION=$(node --version)
if [[ "${NODE_VERSION:1:2}" -lt 18 ]]; then
  echo "Advertencia: WeTTY requiere Node.js 18 o superior. Versión actual: $NODE_VERSION"
fi

# Todo está bien
echo "Wetty está funcionando correctamente"
exit 0