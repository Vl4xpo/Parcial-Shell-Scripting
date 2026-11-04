#!/usr/bin/bash
declare usuario="$(whoami)"
declare fecha_logs=$(date +'%Y-%m-%d-%H:%M:%S')
declare salida="tareas_programador.log"
declare directorio_script="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
declare proyecto="$(dirname "$directorio_script")"
declare ubicacion_logs="$proyecto/logs"
declare ruta="$ubicacion_logs/$salida"
# validar si tiene cron isntalado
if [[ -e  /usr/bin/crontab ]] || [[ -e /etc/cron.d/ ]] ; then
    printf "%s - OK - Cron esta instalado\n"
else
    printf "Cron no esta instalado - busca cron o cronie\n"
    exit 1
fi

crear_tarea(){

    agregar=""$2" "$3" "$4" "$5" "$6" "$1" > /dev/null 2>&1"
    ubicacion="/var/spool/cron/"$7""
    crontab - <<< "$(crontab -l 2>/dev/null; printf "$agregar\n")"
    printf "Verificando: \n"
    grep "$1" "$ubicacion"
    if [[ "$?" -eq 0 ]]; then
        printf "%s - OK - Tarea agregada\n" "$fecha_logs" 2>&1 | tee -a "$ruta"
        return 0
    else
        printf "%s - ERROR - Tarea no agregada verifica\n" "$fecha_logs" 2>&1 | tee -a "$ruta"
        return 1
    fi
}

eliminar_todo(){
    printf "\n\n = Eliminando todas las tareas de =  %s\n" "$usuario"
    printf "Vistazo anteriorr: \n"
    crontab -l 2>/dev/null
    crontab -r
    printf "%s - CUIDADO - Se elimino todas las tareas\n" "$fecha_logs" 2>&1 | tee -a "$ruta"
    return 0
}

# ESto es el gestor
while true;do
    printf "Acciones\n"
    printf "Aclaraacion : 'usuario' = usuario ejecutor\n"
    printf "No te olvides de tener el servicio levantado : cron.service - cronie.service\n"
    printf "1 ) Crear tarea programada para usuario\n"
    printf "2 ) Ver tareas programadas actuales del usuario\n"
    printf "3 ) Editar manualmente\n"
    printf "4 ) Eliminar todas las tareas del usuario\n"
    printf "5 ) Salir\n"
    read -p "Selecciona una opcion : " opcion

    case $opcion in
        1)  printf "\n\n = Valores: =\n(*)-cualquiera | (,)-separar valor | (-)-rango de valores | (/) valor paso\n"
            read -e -p "Que comando deseas ejecutar (ruta-absolua): " tarea
            read -p "Minutos: " minuto
            read -p "Hora   : " hora
            read -p "Dia del mes: " dia
            read -p "Mes     : " mes
            read -p "Dia de la semana: " dia_semana
            printf "Usuario :  %s\n" "$(whoami)"
            crear_tarea "$tarea" "$minuto" "$hora" "$dia" "$mes" "$dia_semana" "$usuario"
            ;;
        2)  printf "\n\n = Verificando tareas programadas para usuario = '%s'\n" "$usuario"
            printf "Recuerda:\n[minuto] [hora] [dia] [mes] [dia semana] [tarea]\n"
            crontab -l
            printf "\n\n"
            ;;
        3)  crontab -e
            printf "%s - ATENCION - se ha modificado las tareas\n" "$fecha_logs" 2>&1 | tee -a "$ruta"
            ;;
        4)  eliminar_todo
            printf "Todas las tareas programadas para el usuario '%s' han sido eliminadas\n\n" "$usuario"
            ;;
        5) printf "\n\nSaliendo" ; exit 0 ;;
        *) printf " = Opcion no valida vuelve a intrdocir un valor adecuado = \n\n"
           printf "%s - ATENCION - Opciono no valida ingresadaa\n" "$fecha_logs" 2>&1 | tee -a "$ruta"
    esac
done
