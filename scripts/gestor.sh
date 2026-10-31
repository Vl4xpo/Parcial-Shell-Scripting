#!/usr/bin/bash

fecha=$(date +'%d-%m-%Y:%H:%M:%S')
# Función de crear un file
#
crear_archivo(){
    if [[ ! -f "$1" ]]; then
        touch "$1"
        printf "[LIsto] El archivo '%s' fue creado exitosamente\n" "$1"
        return 0
    else
        printf "[%s]-[CUIDADO]-[El archvio '%s' ya existe]\n" "$fecha" "$1" >> gestor_errors.log 2>&1
        return 1
    fi
}

# Funcion para copiar archivo
copiar_archivo(){
    # Verifica que el archivo fuese copiado
    cp "$1" "$2"
    if [[ -f "$2" ]]; then
        printf "[OK] El archivo '%s' fue copiado exitosamente\n" "$1"
        printf "Ubicación de la copia : '%s'\n" "$(find "$2")"
        return 0
    else
        printf "[%s]-[ERROR]-[El archivo '%s' no pudo copiarse]\n" "$fecha" "$2" > gestor_errors.log 2>&1
        return 1
    fi

}

cambiar_permisos(){
    # En si usa los argumentos para verificar los permisos
    # Uso el 'ls' para targetear el file cambiado con los permisos y ver como se cambio
    # Y luego valida
    chmod "$1" "$2"
    ls -lah "$2"
    if [[ -f "$2" ]]; then
        printf "[OK] El archivo '%s' - Se les ha campiado de permisos a: (%s) \n" "$2" "$1"
        return 0
    else
        printf "[%s]-[ERROR]-[El archivo '%s' no se puede cambiar de permisos]\n" "$fecha" "$2" > gestor_errors.log 2>&1
        return 1
    fi
}

eliminar_archivos(){
    # Usa el parametro -i para eliminar de forma interactiva
    # Y luego valida
    rm -i "$1"
    if [[ -f "$1" ]]; then
        printf "[OK] El archivo '%s' fue eliminado exitosamente\n" "$1"
        return 0
    else
        printf "[%s]-[ERROR]-[El archivo '%s' no fue eliminado exitosamente]\n" "$fecha" "$1" > gestor_errors.log 2>&1
        return 1
    fi
}

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
            printf "Saliendo del programa...\n"
            exit 0
            ;;
        *)
            printf "Opcion invalida, por favor ingrese una opcion valida \n"  1>&2
            ;;
    esac
done
