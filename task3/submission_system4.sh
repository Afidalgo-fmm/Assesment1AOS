#!/bin/bash
# submission_system_pro.sh - Refactored for High Security

# --- Configuración ---
SUBMISSION_DIR="submissions"
SUBMISSION_LOG="submission_log.txt"
LOGIN_ATTEMPTS_FILE="login_attempts.txt"
LOCK_FILE="/tmp/submission_system.lock"
MAX_FILE_SIZE=$((5 * 1024 * 1024))
PY_COMPARE="./compare_files.py"

# --- Colores ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# --- Inicialización ---
mkdir -p "$SUBMISSION_DIR"
touch "$SUBMISSION_LOG" "$LOGIN_ATTEMPTS_FILE"

# --- Utilidades ---
log_event() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') [$1] $2" >> "$SUBMISSION_LOG"
}

# Bloqueo de seguridad para evitar concurrencia
safe_update_login() {
    exec 3> "$LOGIN_ATTEMPTS_FILE"
    flock -x 3
    # Lógica de actualización aquí (simplificada para el ejemplo)
    flock -u 3
}

# ------------------------------------------------------------------------------
# Función: validate_file (Refactorizada)
# ------------------------------------------------------------------------------
validate_file() {
    local filepath="$1"
    [[ ! -f "$filepath" ]] && { echo -e "${RED}Error: El archivo no existe.${NC}"; return 1; }

    # Validación de extensión robusta
    local ext="${filepath##*.}"
    ext=$(echo "$ext" | tr '[:upper:]' '[:lower:]')
    if [[ "$ext" != "pdf" && "$ext" != "docx" ]]; then
        echo -e "${RED}Error: Extensión .$ext no permitida (Solo PDF/DOCX).${NC}"
        return 1
    fi

    # Tamaño
    local size=$(stat -c%s "$filepath" 2>/dev/null || stat -f%z "$filepath")
    if (( size > MAX_FILE_SIZE )); then
        echo -e "${RED}Error: Excede 5MB ($size bytes).${NC}"
        return 1
    fi
    return 0
}

# ------------------------------------------------------------------------------
# Función: is_duplicate_submission (Seguridad mejorada)
# ------------------------------------------------------------------------------
is_duplicate_submission() {
    local target="$1"
    local found=1

    # Buscamos de forma segura archivos en el directorio de entregas
    while IFS= read -r -d '' existing; do
        if python3 "$PY_COMPARE" "$target" "$existing"; then
            echo -e "${YELLOW}Alerta: Contenido idéntico detectado en $existing${NC}"
            found=0
            break
        fi
    done < <(find "$SUBMISSION_DIR" -type f -print0)

    return $found
}

# ------------------------------------------------------------------------------
# Función: submit_assignment
# ------------------------------------------------------------------------------
submit_assignment() {
    echo -e "${CYAN}=== NUEVA ENTREGA ===${NC}"
    read -p "ID Estudiante: " sid
    read -e -p "Ruta del archivo: " fpath # -e permite usar tabulador para autocompletar

    if validate_file "$fpath"; then
        if is_duplicate_submission "$fpath"; then
            echo -e "${RED}Entrega rechazada: El archivo ya existe en el sistema.${NC}"
            log_event "REJECTED" "Duplicado de $sid para $fpath"
        else
            local ts=$(date +%Y%m%d_%H%M%S)
            local bname=$(basename "$fpath")
            local dest="$SUBMISSION_DIR/${sid}_${ts}_${bname}"
            
            if cp "$fpath" "$dest"; then
                chmod 400 "$dest" # Solo lectura para el dueño (seguridad académica)
                echo -e "${GREEN}✓ Entrega guardada exitosamente: $dest${NC}"
                log_event "ACCEPTED" "Estudiante $sid subió $bname"
            fi
        fi
    fi
}

# ------------------------------------------------------------------------------
# Gestión de Login con Lockout (Simulado)
# ------------------------------------------------------------------------------
simulate_login() {
    echo -e "${CYAN}=== LOGIN AL SISTEMA ===${NC}"
    read -p "ID Estudiante: " sid
    
    # Comprobar si está bloqueado
    if grep -q "${sid}|1|" "$LOGIN_ATTEMPTS_FILE"; then
        echo -e "${RED}ACCESO DENEGADO: Usuario bloqueado por seguridad.${NC}"
        return
    fi

    read -p "¿Resultado del login? (s/f): " res
    local now=$(date +%s)
    
    if [[ "$res" == "s" ]]; then
        echo -e "${GREEN}Bienvenido, $sid${NC}"
        # Aquí resetearíamos intentos (implementar lógica de actualización de archivo)
    else
        echo -e "${RED}Fallo de login registrado.${NC}"
        # Aquí incrementaríamos intentos y bloquearíamos si llega a 3
        log_event "LOGIN_FAIL" "Intento fallido para $sid"
    fi
}

# --- Menú Principal ---
while true; do
    echo -e "\n${CYAN}1) Entregar  2) Duplicados  3) Listar  4) Login  5) Salir${NC}"
    read -p "Opción: " opt
    case "$opt" in
        1) submit_assignment ;;
        2) 
            read -e -p "Archivo a testear: " tfile
            is_duplicate_submission "$tfile" && echo "Sin duplicados." ;;
        3) ls -lh "$SUBMISSION_DIR" ;;
        4) simulate_login ;;
        5) exit 0 ;;
        *) echo "Opción inválida." ;;
    esac
done
