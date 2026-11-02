#!/usr/bin/bash

declare archivo="$1"
declare fecha=$(date +'%Y-%m-%d_%Hhr-%Mmin')
declare -A uso_disco_registro
declare contador=1
declare ruta
declare salida="$fecha-analisis-discos.reporte"
declare argumentos="$@"
declare modo=0


# ESTO en si valida si no hay argumetno para analizar osea el file
# verifica si no colocas y si es file o se puede leer

# Ver que no sea mas de 2 argumentos
read -a argumento <<< "$argumentos" # el array para captar
for i in "${argumento[@]}"; do
    if [[ "$i" == "--auto" ]] || [[ "$i" == "-a" ]]; then
        printf "Modo automatico\n" 1>&2
        ((modo++))
        break
    elif [[ ! -f "$i" ]] && [[ ! -r "$i" ]]; then
        printf "[03] Problema - Verificar estado de los argumenntos\n" 1>&2
        exit 3
    fi
done

if [[ "${#argumento[@]}" -ge 3 ]]; then
    printf "[02] Problema - Muchos argumentos solo se aceptan maximo 2\n" 1>&2
    exit 2
elif [[ "${#argumento[@]}" -eq 0 ]]; then
    printf "[01] Problema - No hay argumentos\n" 1>&2
    exit 1
elif [[ "${#argumento[@]}" -eq 1 ]] ||  [[ "${#argumento[@]}" -eq 2 ]]; then
    printf "Continuando\n"
fi

leer_archivo(){
    # Seria aqui el guardado del texto en variables en un array asociativo
    # [disco]=[uso%] luego en si usamos el disco como uso para targetearlo con grep
    while read -r servidor disco tipo tamanno uso; do
        # Agregar el registro al diccionario
        uso_disco_registro+=(["$disco"]=$(tr -d '%' <<< $uso))
        # printf "%s\n" "${uso_disco_registro["$disco"]}"
    done < "$1"
    return 0
}

# Se soluciono el problema con el tamanno cambiando la palabra por capacidad para que se visualice en el reporte
crear_analisis_archivo(){
    # Aqui en si es para generar un reporte del archivo y colocar mensajes en los discos con colores en ese baclup-reporte
    # En si copi a la carpeta reporte osea el analisis final
    # Pero luego usamos una opcion para ver si desea guardar en otro lugar
    if [[ "$1" -ge 1 ]]; then
        # Para ubiicar dodne se ejecuta y donde guardar la salida osea repote en la carpeta
        directorio_script="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
        proyecto="$(dirname "$directorio_script")"
        ubicacion="$proyecto/reporte"
        ruta="$ubicacion/$salida"
        touch "$ruta"
        return 0
    fi
    ruta="/tmp/$salida.report" # ruta por defecto en la carpta tmp
    read -p "Desea guardar el analisis en un lugar concreto?(si/no) : " opcion
    if [[ "$opcion" == "si" ]] || [[ "$opcion" == "SI" ]] || [[ "$opcion" == "s" ]] || [[ "$opcion" == "S" ]]; then
        printf "Nota coloque solamente la ruta quitando el '/' al final de la ruta\n"
        printf "Y empieza el nombre o salida sin '/'\n"
        printf "Usando '~' al inicio usarlo en ruta - en nombre colocar su ubicacion desde HOME\n"
        read -p "Ingrese la ruta donde desea guardar el archivo: " alterno
        read -p "Nombre del archivo.report: " salida
        if [[ "$alterno" == "~" ]]; then
            touch "$HOME/$salida.report"
            printf "Ruta del archivo : %s\n" "$HOME/$salida.report"
            ruta="$HOME/$salida.report"
            return 0
        else
            touch "$alterno/$salida.report"
            printf "Ruta del archivo : %s\n" "$alterno/$salida.report"
            ruta="$alterno/$salida.report"
            return 0
        fi
    elif [[ "$opcion" == "no" ]] || [[ "$opcion" == "NO" ]] || [[ "$opcion" == "n" ]] || [[ "$opcion" == "N" ]] || [[ "$opcion" == "" ]]; then
        touch "$ruta"
        printf "Ruta del archivo : %s\n" "$ruta"
        return 0
    else
        printf "Opcion no valida \n" 1>&2
        touch "$ruta"
        printf "Ruta del archivo default : %s\n" "$ruta"
        return 1
    fi
}

salida_reporte_file(){
    if [[ ! -f  "$1" ]] || [[ ! -e "$1" ]] ;then
        printf "%s\n" "$1"
        printf "Ruta no valida o no encontrada\n" 1>&2
        return 1
    fi
    # Genera la salida del reporte a su vez manda todo a la ruta seleccionada
    printf "==============================================\n" >> "$1"
    printf "Número de registros capturados Totales: %s \n"  "$(wc -l $archivo | cut -d " " -f 1)" >> "$1"
    printf "Fecha : %s\n"  "$fecha" >> "$1"
    printf "==============================================\n\n" >> "$1"

    for disco in "${!uso_disco_registro[@]}"; do
        printf "Registros del servidor: %s\n"  "$((contador++))" >> "$1"
        printf "Servidor : %s\n" "$(grep "$disco" ""$archivo | cut -d ' ' -f 1)" >> "$1"
        printf "Nombre en Sistema de ficheros: %s\n" "$(grep "$disco" ""$archivo | cut -d ' ' -f 2)" >> "$1"
        printf "Tipo de disco: %s\n" "$(grep "$disco" ""$archivo | cut -d ' ' -f 3)" >> "$ruta"
        printf "Capacidad del disco total: %s\n" "$(grep "$disco" ""$archivo | cut -d ' ' -f 4)" >> "$ruta"
        printf "Uso del disco: %s %% \n" "${uso_disco_registro[$disco]}" >> "$1"
        printf "Indicadores que se encontraron:\n" >> "$1"
        # Aqui solamente son las condicioens tipo para
        # verificar y dar mensaje sobre el uso del disco
        if [[ "${uso_disco_registro["$disco"]}" -le 50 ]] && [[ "${uso_disco_registro["$disco"]}" -ge 45 ]] ; then
            printf "[OJO] Se vio que el disco esta por la mitad\n" >> "$1"
        elif [[ "${uso_disco_registro["$disco"]}" -ge 56 ]] && [[ "${uso_disco_registro["$disco"]}" -le 75 ]]; then
            printf "[CUIDADO] El disco tiene una capacidad de uso menor a 75%%\n" >> "$1"
        elif [[ "${uso_disco_registro["$disco"]}" -ge 76 ]] && [[ "${uso_disco_registro["$disco"]}" -le 95 ]]; then
            printf "[PELIGRO] El disco esta casi lleno\n" >> "$1"
        elif [[ "${uso_disco_registro["$disco"]}" -ge 96 ]] && [[ "${uso_disco_registro["$disco"]}" -le 100 ]]; then
            printf "[CRITICO] El disco esta lleno - se recomienda realizar un backup y urgente limpieza\n" >> "$1"
        else
            printf "[OK] El disco esta en buen estado de uso por ahora\n" >> "$1"
        fi
        printf "\n\n" >> "$1"
    done
    printf "Se ha Guardado el reporte de salida en la ubicacion: %s\n\n" "$1"
    # Leerlo
    # Ahora se lee de acuerdo al modo del argumentoo
    if [[ "$2" -ge 1 ]]; then
        return 0
    else
        read -p "Desea leer el archivo? (si/no): " opcion
        if [[ "$opcion" == "si" ]] || [[ "$opcion" == "SI" ]] || [[ "$opcion" == "s" ]] || [[ "$opcion" == "S" ]] ; then
            cat "$1"
            return 0
        fi
        return 0
    fi
}

leer_archivo $archivo
crear_analisis_archivo $modo
salida_reporte_file $ruta $modo
exit 0
