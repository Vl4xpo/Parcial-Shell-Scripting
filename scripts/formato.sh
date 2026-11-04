#!/usr/bin/bash

# Variables
# Para almacenar - fecha - colocar salida al archivo mediante el nombre disco-"host"-"fecha_realizada".formato para identificarlo rapidamente
# Ademmas tiene variables para reporte y logs tanto para la fecha para un mmejor orden
declare -a nueva_linea
declare fecha=$(date +'%d-%m-%Y-%Hhr-%Mmin')
declare fecha_logs=$(date +'%Y-%m-%d-%H:%M:%S')
nombre="$(hostname)"
declare salida="disco-$nombre.formato"
declare salida_reporte="disco-$nombre-$fecha.formato"
linea=1
# declare depurador="--"

# Ruta del script ejecutado
# Aqui seria para obtener con dirname donde se ejecuta el script
# Y luego redirigir a Analizar yy la ruta para redirigir
# Osea que se uso laa variable de BASH que en teoria refleja donde fue invocado un script y eso lo captamos con dirname
declare directorio_script="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# printf "Probando - %s\n" "${BASH_SOURCE[0]}"
declare proyecto="$(dirname "$directorio_script")"
declare ubicacion="$proyecto/Analizar"
declare ubicacion_reporte="$proyecto/reporte"
declare ubicacion_logs="$proyecto/logs"
declare ruta="$ubicacion/$salida"
declare ruta_reporte="$ubicacion_reporte/$salida_reporte"
declare ruta_logs="$ubicacion_logs/formato.log"

# Verificar si el directorio existe, en caso no obviamente lo crea
if [[ ! -d "$ubicacion" ]] && [[ ! -d "$ubicacion_reporte" ]] && [[ ! -d "$ubicacion_logs" ]]; then
    mkdir -p "$ubicacion"
    printf "No se encontro Directorio 'Analizar' - Se ha creado en : %s\n%s\n%s\n" "$ubicacion" "$ubicacion_logs" "$ubicacion_reporte"
    printf "$fecha_logs - ATENCION - No se logro encontrar directorios , se han creado\n" | tee -a "$ruta_logs"
fi

# Esto lo que realiza es crear el formato para luego analizarlo
# Usa el comando 'df' paraa que lo reciba read y se lea
# Por ahora coloque algunos depuradores para validar
# Se agrego un nuevo formato para evitar leer "tmpfs" osea memoria RAM fisica
# Ademas de devtmpfs y efivarfs donde se escribe grub o el boot aprox incluso SquashFS o squashfuse motivo siempre lleno y donde estan los nodos de Linux
while read -r disco tipo tamanno uso disponible porcentaje montaje; do
    if [[ "$linea" -eq 1 ]]; then
        # printf "linea - %s" "$depurador"
        ((linea ++))
        continue
    fi
    # Evitar leer tmpfs
    if [[ "$tipo" == "tmpfs" ]] || [[ "$tipo" == "devtmpfs" ]] || [[ "$tipo" == "efivarfs" ]] || [[ "$tipo" == "fuse.squashfuse" ]] ; then
        continue
    fi
    # printf "%s" "$depurador"
    # # printf "%s\n"
    nueva_linea+=("$(hostname) $disco $tipo $tamanno $porcentaje")
done <<< $(df -hT)

# Aqui hago esto para que pueda analizarse auto
# elimnar el antiguo y luego tirar
# Solo si existe osea par que no nos de error el rm
if [[ -f "$ruta" ]] && [[ -e "$ruta" ]]; then
    rm "$ruta"
    printf "$fecha_logs - NOTA - Generando otro reporte para analizar\n" | tee -a "$ruta_logs"
fi

for linea in "${nueva_linea[@]}"; do
    printf "%s\n" "$linea"  >> "$ruta"
    printf "%s\n" "$linea"  >> "$ruta_reporte"
done
printf "$fecha_logs - OK - Se generaron reporte tanto para analizar como para ver fechas\n" | tee -a "$ruta_logs"
# Un mensaje para ver donde se genero el formato para anlizar y su recomendacion
# Usando ASCII con colores para que se vea mas bonito o se prestea atencion por los ojos
printf "\033[32mAtencion se genero el formato en\033[0m \033[31m%s\033[0m\n\033[33mListo para analizar con\033[0m \033[31m'analizador_disco.sh\033[0m'\n" "$ruta"
exit 0
