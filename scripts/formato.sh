#!/usr/bin/bash

# Variables
# Para almacenar - fecha - colocar salida al archivo mediante el nombre disco-"host"-"fecha_realizada".formato para identificarlo rapidamente
declare -a nueva_linea
declare fecha=$(date +'%d-%m-%Y')
nombre="$(hostname)"
declare salida="disco-$nombre-$fecha.formato"
linea=1
# declare depurador="--"

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

for linea in "${nueva_linea[@]}"; do
    printf "%s\n" "$linea" >> ./"$salida"
done
