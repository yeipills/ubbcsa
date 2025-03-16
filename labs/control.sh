#!/bin/bash

# Script de control principal para los laboratorios y wetty

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

function check_ttyd_container() {
    echo "Verificando contenedor ttyd..."
    TTYD_ID=$(docker ps -qf "name=ttyd")
    
    if [ -z "$TTYD_ID" ]; then
        echo "Contenedor ttyd no encontrado o no está en ejecución"
        return 1
    else
        echo "Contenedor ttyd activo: $TTYD_ID"
        
        # Verificar si el servicio está respondiendo dentro del contenedor
        HEALTH=$(docker exec $TTYD_ID curl -s --head --fail http://localhost:3000/ || echo "FAIL")
        
        if [[ $HEALTH == *"FAIL"* ]]; then
            echo "ttyd no está respondiendo dentro del contenedor"
            return 2
        else
            echo "ttyd está activo y respondiendo correctamente"
            return 0
        fi
    fi
}

function restart_ttyd() {
    echo "Reiniciando servicio ttyd..."
    TTYD_ID=$(docker ps -qf "name=ttyd")
    
    if [ -n "$TTYD_ID" ]; then
        echo "Reiniciando contenedor ttyd..."
        docker restart $TTYD_ID
        sleep 5
        check_ttyd_container
        return $?
    else
        echo "Contenedor ttyd no encontrado, intentando iniciar el servicio..."
        cd /home/yeipi/Escritorio/proyecto/ubbcsa
        docker-compose up -d ttyd
        sleep 10
        check_ttyd_container
        return $?
    fi
}

function check_network() {
    echo "Verificando red entre contenedores..."
    
    TTYD_ID=$(docker ps -qf "name=ttyd")
    WEB_ID=$(docker ps -qf "name=web")
    
    if [ -z "$TTYD_ID" ] || [ -z "$WEB_ID" ]; then
        echo "No se encontraron los contenedores necesarios"
        return 1
    fi
    
    # Verificar conectividad desde ttyd a web
    PING_RESULT=$(docker exec $TTYD_ID ping -c 2 web 2>/dev/null || echo "FAIL")
    
    if [[ $PING_RESULT == *"FAIL"* ]]; then
        echo "No hay conectividad de red entre ttyd y web"
        return 1
    else
        echo "Red entre contenedores funciona correctamente"
        return 0
    fi
}

function check_api_connection() {
    echo "Verificando conexión a la API de Rails..."
    
    TTYD_ID=$(docker ps -qf "name=ttyd")
    
    if [ -z "$TTYD_ID" ]; then
        echo "Contenedor ttyd no encontrado"
        return 1
    fi
    
    # Probar conexión a la API
    API_CHECK=$(docker exec $TTYD_ID curl -s http://web:3001/api/terminal/ping || echo "FAIL")
    
    if [[ $API_CHECK == *"FAIL"* ]]; then
        echo "No se puede conectar a la API de Rails"
        return 1
    else
        echo "Conexión a la API correcta"
        return 0
    fi
}

function fix_environment() {
    echo "Corrigiendo entorno de laboratorio..."
    
    # Verificar y reparar servicio ttyd
    check_ttyd_container
    if [ $? -ne 0 ]; then
        restart_ttyd
    fi
    
    # Verificar y reparar red
    check_network
    if [ $? -ne 0 ]; then
        echo "Recreando redes..."
        cd /home/yeipi/Escritorio/proyecto/ubbcsa
        docker-compose down
        docker-compose up -d
    fi
    
    # Verificar API
    check_api_connection
    
    echo "Proceso de reparación completado"
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
    "check-ttyd")
        check_ttyd_container
        check_network
        check_api_connection
        ;;
    "restart-ttyd")
        restart_ttyd
        ;;
    "fix")
        fix_environment
        ;;
    *)
        echo "Uso: $0 {start|stop|reset|check-ttyd|restart-ttyd|fix} [tipo_lab]"
        echo "  start: Iniciar laboratorio específico"
        echo "  stop: Detener laboratorio"
        echo "  reset: Reiniciar laboratorio"
        echo "  check-ttyd: Verificar estado de ttyd"
        echo "  restart-ttyd: Reiniciar servicio ttyd"
        echo "  fix: Intentar reparar problemas detectados"
        exit 1
        ;;
esac

exit 0