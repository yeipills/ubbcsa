#!/bin/bash

# Script de control principal para los laboratorios

function start_lab() {
    lab_type=$1
    case $lab_type in
        "pentesting")
            bash /home/kali/labs/pentesting/init.sh
            ;;
        "forense")
            bash /home/kali/labs/forense/init.sh
            ;;
        "redes")
            bash /home/kali/labs/redes/init.sh
            ;;
        *)
            echo "Laboratorio no válido"
            exit 1
            ;;
    esac
}

function stop_lab() {
    lab_type=$1
    # Detener contenedores y limpiar recursos
    docker stop $(docker ps -a -q)
    docker rm $(docker ps -a -q)
    docker network prune -f
}

function reset_lab() {
    lab_type=$1
    stop_lab $lab_type
    start_lab $lab_type
}

# Manejo de argumentos
case $1 in
    "start")
        start_lab $2
        ;;
    "stop")
        stop_lab $2
        ;;
    "reset")
        reset_lab $2
        ;;
    *)
        echo "Uso: $0 {start|stop|reset} {pentesting|forense|redes}"
        exit 1
        ;;
esac