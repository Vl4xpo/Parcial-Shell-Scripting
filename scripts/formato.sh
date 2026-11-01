#!/usr/bin/bash
declare -a nueva_linea
declare fecha=$(date +'%d-%m-%Y')
nombre="$(hostname)"
declare salida="disco-$nombre-$fecha.formato"
linea=1
# declare depurador="--"

# Esto lo que realiza es crear el formato para luego analizarlo
# Usa el comando 'df' paraa que lo reciba read y se lea
# Por ahora coloque algunos depuradores para validar
while read -r disco tipo tamanno uso disponible porcentaje montaje; do
    if [[ "$linea" -eq 1 ]]; then
        # printf "linea - %s" "$depurador"
        ((linea ++))
        continue
    fi
    # printf "%s" "$depurador"
    # # printf "%s\n"
    nueva_linea+=("$(hostname) $disco $tipo $tamanno $porcentaje")
done <<< $(df -hT)

for linea in "${nueva_linea[@]}"; do
    printf "%s\n" "$linea" >> ./"$salida"
done
