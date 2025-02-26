#!/bin/bash

# Configuración del laboratorio forense
LAB_DIR="/home/kali/labs/forense"

# Crear estructura de archivos
mkdir -p $LAB_DIR/{evidencia,analisis,reportes}

# Descargar imágenes de disco de ejemplo
cd $LAB_DIR/evidencia
wget https://ejemplo.com/disco-ejemplo.dd

# Crear guía del laboratorio
cat > $LAB_DIR/README.md << EOF
# Laboratorio de Análisis Forense

Objetivos:
1. Analizar la imagen de disco proporcionada
2. Recuperar archivos eliminados
3. Identificar evidencias de actividad maliciosa
4. Generar reporte de hallazgos

Herramientas disponibles:
- Autopsy
- TestDisk
- PhotoRec
- Volatility

Procedimiento:
1. Crear copia de trabajo de la evidencia
2. Calcular hashes de verificación
3. Realizar análisis con herramientas forenses
4. Documentar hallazgos
EOF