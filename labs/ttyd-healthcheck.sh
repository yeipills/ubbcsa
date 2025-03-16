#!/bin/bash

# Script de verificación de salud más simple para el contenedor ttyd

# Verificar si el proceso de ttyd está ejecutándose
if ! ps aux | grep -v grep | grep -q "ttyd"; then
  echo "Error: No se encontró proceso ttyd en ejecución"
  exit 1
fi

# Verificar si el puerto está escuchando
PORT="${TTYD_PORT:-3000}"
if ! netcat -z localhost $PORT; then
  echo "Error: Puerto $PORT no está escuchando"
  exit 1
fi

# Todo está bien
echo "ttyd está funcionando correctamente"
exit 0