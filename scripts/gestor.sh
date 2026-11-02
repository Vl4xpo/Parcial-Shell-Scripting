#!/usr/bin/bash

fecha=$(date +'%d-%m-%Y:%H:%M:%S')
declare salida="gestor.log"
# ESTAS VARIABLES son para lograr targetear el lugar para logs
# Se usa dirname para capturar con el pwd y BASH_SOURCE array
# La ubicación para mandar los mensajes tipo ver cuando se ejecutaron esta en logs
declare directorio_script="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
declare proyecto="$(dirname "$directorio_script")"
declare ubicacion="$proyecto/logs"
declare ruta="$ubicacion/$salida"
declare conteo_errores=0
# Ojito camibe el o la redireccion >> hacia la var ruta por tee para que se pueda ver los logs ademas de annadir con su parametro -a
# Función de crear un file

validar_directoriosalida(){
    # Valida y crea si es enecesario para ver si esta logs
    # Osea ve si existe el directorio o no si exsite lo crea sino lo guarda
    if [[ ! -d "$ubicacion" ]]; then
        mkdir -p "$ubicacion"
        touch "$ruta"
        printf "%s - ERROR - No se encontro Directorio 'logs' para guardar eventos por ello ha creado en %s\n" "$fecha" "$ubicacion" 2>&1 | tee -a "$ruta"
        ((conteo_errores++))
        return 1
    else
        touch "$ruta"
        printf "MOnitoreo de eventos esta en: %s\nArchivo: %s\n" "$ubicacion" "$salida"
        return 0
    fi
}

crear_archivo(){
    if [[ ! -f "$1" ]]; then
        touch "$1"
        printf "%s - OK - El archivo '%s' fue creado exitosamente\n" "$fecha" "$1" | tee -a "$ruta"
        return 0
    else
        printf "%s - CUIDADO - El archvio '%s' ya existe\n" "$fecha" "$1" 2>&1 | tee -a "$ruta"
        ((conteo_errores++))
        return 1
    fi
}

# Funcion para copiar archivo
copiar_archivo(){
    # Verifica que el archivo fuese copiado
    cp "$1" "$2"
    if [[ -f "$2" ]]; then
        printf "%s - OK - El archivo '%s' fue copiado exitosamente\n" "$fecha" "$1" | tee -a "$ruta"
        printf "Ubicación de la copia : '%s'\n" "$(find "$2")"
        return 0
    else
        printf "%s - ERROR - El archivo '%s' no pudo copiarse\n" "$fecha" "$2" 2>&1 | tee -a "$ruta"
        ((conteo_errores++))
        return 1
    fi

}

cambiar_permisos(){
    # En si usa los argumentos para verificar los permisos
    # Uso el 'ls' para targetear el file cambiado con los permisos y ver como se cambio
    # Ademas de ver el antes
    # Y luego valida
    chmod "$1" "$2"
    if [[ -f "$2" ]]; then
        printf "%s - OK - El archivo '%s'  Se les ha campiado de permisos a: (%s) \n" "$fecha" "$2" "$1" | tee -a "$ruta"
        ls -lah "$2"
        return 0
    else
        printf "%s - ERROR - El archivo '%s' no se puede cambiar de permisos\n" "$fecha" "$2" 2>&1 | tee -a "$ruta"
        ((conteo_errores++))
        return 1
    fi
}

eliminar_archivos(){
    # Usa el parametro -i para eliminar de forma interactiva
    # Y luego valida
    rm -i "$1"
    if [[ -f "$1" ]]; then
        printf "%s - OK - El archivo '%s' fue eliminado exitosamente\n" "$fecha" "$1" | tee -a "$ruta"
        return 0
    else
        printf "%s - ERROR - El archivo '%s' no fue eliminado exitosamente\n" "$fecha" "$1" 2>&1 | tee -a "$ruta"
        ((conteo_errores++))
        return 1
    fi
}

validar_directoriosalida # para verificar antes del while para validar carpetae
# bucle infinito del menu interactivvvo
while true; do
    printf " \n"
    printf "\-- Gestor interactivo Archivos -- \n"
    printf "1. Crear archivo \n"
    printf "2. Copiar archivo \n"
    printf "3. Cambiar permisos \n"
    printf "4. Eliminar archivo \n"
    printf "5. Salir \n"
    read -p "Ingrese una opcion: " opcion

    # Lectuura de la opcion y llama a las funciones con los argumentos necesarios
    case $opcion in
        1)
            read -p "Ingrese el archivo a crear: " archivo
            crear_archivo "$archivo"
            ;;
        2)
            read -p "Ingrese el archivo a copiar: " archivo
            read -p "Ingrese el archivo a copiar: " archivo2
            copiar_archivo "$archivo" "$archivo2"
            ;;
        3)
            read -p "Ingrese el archivo: " archivo
            printf "Permisos del archivo: ' %s '\n" "$(ls -lah "$archivo")"
            # A y imprime salidas pero tiene un print de el valor en octal a rwx
            printf "[NOTA] Leer(r): 4  | Escribir(w) : 2 | Ejecutar(x): 1 \n"
            read -p "Ingrese los permisos a cambiar: " permisos
            cambiar_permisos "$permisos" "$archivo"
            ;;
        4)
            read -p "Ingrese el archivo a eliminar: " archivo
            eliminar_archivos "$archivo"
            ;;
        5)
            printf "Observaron un total de ( %d )errores\n" "$conteo_errores"
            printf "Saliendo del programa...\n"
            exit 0
            ;;
        *)
            printf "Opcion invalida, por favor ingrese una opcion valida \n"  1>&2
            ;;
    esac
done
