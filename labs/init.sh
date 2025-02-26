#!/bin/bash

LAB_TYPE=$1

case $LAB_TYPE in
  "pentesting")
    echo "Iniciando laboratorio de pentesting..."
    # Configuración específica para pentesting
    ;;
  "forense")
    echo "Iniciando laboratorio forense..."
    # Configuración específica para forense
    ;;
  "redes")
    echo "Iniciando laboratorio de redes..."
    # Configuración específica para redes
    ;;
  *)
    echo "Tipo de laboratorio no válido"
    exit 1
    ;;
esac

echo "Laboratorio iniciado correctamente"
exit 0