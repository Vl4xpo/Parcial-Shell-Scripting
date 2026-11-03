#!/usr/bin/bash

# validar si tiene cron isntalado
if [[ -e  /usr/bin/crontab ]] || [[ -e /etc/cron.d/ ]] ; then
    printf "Cron esta instalado\n"
else
    printf "Cron no esta instalado - busca cron o cronie\n"
    exit 1
fi

while true;do
    printf "Acciones\n"
    printf "Aclaraacion : 'usuario' = usuario ejecutor\n"
    printf "1 ) Crear una tarea programada\n"
    printf "2 ) Ver tareas programadas actuales del usuario\n"
    printf "3 ) Eliminar una tarea programada\n"
    printf "4 ) Eliminar todas las tareas del usuario\n"
    printf "5 ) Salir\n"
    read -p "Selecciona una opcion : " opcion

    case $opcion in
        1) ;;
        2) ;;
        3) ;;
        4) ;;
        5) printf "Saliendo" ; exit 0 ;;
        *) printf "Opcion invalida\n"
    esac
done
