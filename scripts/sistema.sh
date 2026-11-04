#!/usr/bin/bash

declare usuario_actual=$(whoami)
declare -a usuario_grupos
declare usuario_permisos
declare fecha=$(date +'%Y-%m-%d-%Hhr-%Mmin-%Ssec')
declare dia=$(date +'%A')
declare salida="$fecha-sistema.reporte"
# Para ubiicar dodne se ejecuta y donde guardar la salida osea repote
declare directorio_script="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
declare proyecto="$(dirname "$directorio_script")"
declare ubicacion="$proyecto/reporte"
declare ruta="$ubicacion/$salida"

# VALIDAR si existe /reporte
validar_directorio(){
    if [[ -d "$ubicacion" ]]; then
       printf "Se guardara un reporte en : %s\n" "$ruta"
       return 0
    else
       mkdir -p "$ruta"
       printf "No habia carpeta '/reporte' se ha generado en : %s\n" "$ruta"
       return 1
    fi
}


grupos_usuario()
{
    corte=$(groups $usuario_actual)
    grupo=$(cut -d " " -f 3- <<<$corte)
    for i in $grupo; do
        # printf "%s " "$i"
        usuario_grupos+=($i)
    done
    return 0
}

privilegios_elevados(){
    # En si verifcar si tiene el grupo conocido en las distros el famoso wheel
    # Luego validar si usa doas o sudo
    mensaje=""
    for i in "${usuario_grupos[@]}"; do
        if [[ "$i" == "wheel" ]] || [[ "$i" == "root" ]] ; then
            mensaje=$(printf "El usuario (%s) tiene permisos de administrador Total\n" "$usuario_actual")
        fi
    done
    if [[ -z "$mensaje" ]]; then
        mensaje=$(printf "El usuario (%s) no tiene permisos de administrador Total\n" "$usuario_actual")
    fi
    binarios=$(find /usr/bin/doas /usr/bin/sudo)
    if [[ "$binarios" =~ \/usr\/bin\/doas ]]; then
        binarios="doas"
    else
        binarios="sudo"
    fi
    return 0
}

validar_ntp(){
    ntp_estado="$(timedatectl show | grep -E '^NTP')" #
    # elimnando el salto e linea y espacio
    while read -r i;do
        estado+=("$i")
    done <<< "$ntp_estado"

    # printf "\n%s\n" "${estado[@]}
    # En si volvera a leer el NTP yes asi que el OR estara para valdiar
    # y no cambiar el mensaje
    for i in "${estado[@]}"; do
        if [[ "$i" == "NTP=yes" ]] || [[ "$i" == "NTPSynchronized=yes" ]] ; then
            mensaje=$(printf "NTP activado\n")
        else
            mensaje=$(printf "[ERROR] NTP desactivado\n") 1>&2
        fi
        if [[ "$i" == "NTPSynchronized=yes" ]]; then
            mensaje2=$(printf "NTP sincronizado\n")
        else
            mensaje2=$(printf "[ERROR] NTP no sincronizado\n") 1>&2
        fi
    done
    return 0
}

verificar_discotamano(){
    prueba_porcentaje=$(df -h -P | grep -E "^/dev" | awk '{print $5}' | sed 's/%//g' | sort -n | tail)
    while read -r i;do
        uso+=("$i")
    done <<< "$prueba_porcentaje"
    for i in "${uso[@]}"; do
         # printf "%s " "$i"
        if [[ "$i" -ge 80 ]];then
            disco=$(df -h -P | grep -E "^/dev" | grep -E "$i%"| sort -n | head -n 1 | awk '{print $1}')
            printf "[PELIGRO] Disco: %s con poca memoria (USO: %s%%)\n" "$disco" "$i" 1>&2 | tee -a "$ruta"
        elif [[ "$i" -lt 79 ]] && [[ "$i" -gt 51 ]] ;then
            disco=$(df -h | grep -E "^/dev" | grep -E "$i%"| sort -n | head -n 1  | awk '{print $1}')
            printf "[ATENCION] Disco: %s con mucha información (USO: %s%%)\n" "$disco" "$i" | tee -a "$ruta"
        elif [[ "$i" -lt 50 ]] && [[ "$i" -gt 45 ]] ;then
            disco=$(df -h | grep -E "^/dev" | grep -E "$i%"| sort -n | head -n 1  | awk '{print $1}')
            printf "[ATENCION] Disco: %s  a mitad de tamaño o cerca (USO: %s%%)\n" "$disco" "$i" | tee -a "$ruta"
        else
            disco=$(df -h -P | grep -E "^/dev" | grep -E "$i%"| sort -n | head -n 1 | awk '{print $1}') | tee -a "$ruta"
            printf "Disco %s con %s%% de uso\n" "$disco" "$i"
        fi
    done
    unset uso
}

validar_directorio
grupos_usuario
# echo "$usuario_grupos"

printf "\-- Información del usuario (%s - %s)--\ \n" "$fecha" "$dia" | tee -a "$ruta"
printf "Usuario: %s\t\tUID: %s\nGrupos: "  "$usuario_actual" "$(id -u $usuario_actual)" | tee -a "$ruta"
printf "%s "   "${usuario_grupos[@]}" | tee -a "$ruta"
printf "\n" | tee -a "$ruta"
privilegios_elevados
printf "Privilegios administrados por: %s\n[NOTA]: %s\n" "$binarios" "$mensaje" | tee -a "$ruta"
printf "Momento del inicio del equipo: %s\n" "$(uptime -s)" | tee -a "$ruta"
validar_ntp
printf "Time de NTP : %s\tSincronizado: %s\n" "$mensaje" "$mensaje2" | tee -a "$ruta"
printf "\nInformación Maquina Actual\n" | tee -a "$ruta"
printf "Sistema operativo: %s\n" "$(uname -o)" | tee -a "$ruta"
printf "Distribución: %s\n" "$(cat /etc/os-release | grep -E "^NAME" | cut -d '"' -f 2)" | tee -a "$ruta"
printf "Kernel: %s-%s\t-- Versión: %s\t-- Arquitectura: %s\n" "$(uname -s)" "$(uname -r | cut -d '-' -f 2)" "$(uname -r | cut -d '-' -f 1)" "$(uname -m)" | tee -a "$ruta"
printf "Nombre del equipo: %s\n" "$(uname -n)" | tee -a "$ruta"
printf "\nInformación del Disco\n" | tee -a "$ruta"
printf "Tamaño y Ruta de montaje\n" | tee -a "$ruta"
printf "%s" "$(df -h | grep -vE '^Filesystem|tmpfs|cdrom|none|udev|shm')" | tee -a "$ruta"
printf "\nUso de disco\n" | tee -a "$ruta"
verificar_discotamano
