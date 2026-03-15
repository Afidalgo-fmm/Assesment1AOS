#!/bin/bash
#
# job_scheduler_pro.sh
# Version: 2.0 (HPC Hardened)
# Refactored with: File locking, Signal handling, Atomic I/O, and ANSI styling.

# --- Configuración y Rutas ---
JOB_QUEUE_FILE="job_queue.txt"
COMPLETED_JOBS_FILE="completed_jobs.txt"
SCHEDULER_LOG_FILE="scheduler_log.txt"
LOCK_FILE="/tmp/hpc_scheduler.lock"
TIME_QUANTUM=5

# --- Estilos de Color (ANSI) ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# --- Inicialización de archivos ---
touch "$JOB_QUEUE_FILE" "$COMPLETED_JOBS_FILE" "$SCHEDULER_LOG_FILE"

# ------------------------------------------------------------------------------
# Manejo de Señales (Graceful Shutdown)
# ------------------------------------------------------------------------------
cleanup() {
    echo -e "\n${YELLOW}[!] Interrupción detectada. Limpiando bloqueos...${NC}"
    rm -f "$LOCK_FILE"
    exit 0
}
trap cleanup SIGINT SIGTERM

# ------------------------------------------------------------------------------
# Función: acquire_lock (Evita colisiones entre procesos)
# ------------------------------------------------------------------------------
acquire_lock() {
    if [ -e "$LOCK_FILE" ]; then
        echo -e "${RED}ERROR: El scheduler ya está bloqueado por otro proceso.${NC}"
        return 1
    fi
    touch "$LOCK_FILE"
}

release_lock() {
    rm -f "$LOCK_FILE"
}

# ------------------------------------------------------------------------------
# Función: log_event
# ------------------------------------------------------------------------------
log_event() {
    local message="$1"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $message" >> "$SCHEDULER_LOG_FILE"
}

# ------------------------------------------------------------------------------
# Función: show_menu
# ------------------------------------------------------------------------------
show_menu() {
    clear
    echo -e "${BLUE}==============================================${NC}"
    echo -e "  ${YELLOW}HPC JOB SCHEDULER ${NC}"
    echo -e "${BLUE}==============================================${NC}"
    echo "1) View pending jobs"
    echo "2) Submit new job"
    echo "3) Process queue (Round Robin)"
    echo "4) Process queue (Priority Scheduling)"
    echo "5) View completed jobs"
    echo "6) Exit"
    echo -e "${BLUE}==============================================${NC}"
}

# ------------------------------------------------------------------------------
# Función: view_pending_jobs
# ------------------------------------------------------------------------------
view_pending_jobs() {
    echo -e "${BLUE}=== PENDING JOBS QUEUE ===${NC}"
    if [ ! -s "$JOB_QUEUE_FILE" ]; then
        echo "No pending jobs."
        return
    fi

    printf "${YELLOW}%-4s %-12s %-15s %-10s %s${NC}\n" "ID" "STUDENT_ID" "JOB_NAME" "EST_TIME" "PRIO"
    local counter=1
    while IFS="|" read -r sid name est prio; do
        printf "%-4s %-12s %-15s %-10s %s\n" "$counter" "$sid" "$name" "${est}s" "$prio"
        ((counter++))
    done < "$JOB_QUEUE_FILE"
}

# ------------------------------------------------------------------------------
# Función: submit_job (Con sanitización de entrada)
# ------------------------------------------------------------------------------
submit_job() {
    echo -e "${BLUE}=== SUBMIT NEW JOB ===${NC}"
    read -p "Student ID: " sid
    read -p "Job name: " name
    read -p "Est. Time (s): " est
    read -p "Priority [1-10]: " prio

    # Validación de campos vacíos o caracteres prohibidos (|)
    if [[ -z "$sid" || -z "$name" || "$sid" == *"|"* || "$name" == *"|"* ]]; then
        echo -e "${RED}ERROR: Campos vacíos o uso de carácter prohibido '|'.${NC}"
        return 1
    fi

    if ! [[ "$est" =~ ^[0-9]+$ ]] || ! [[ "$prio" =~ ^[0-9]+$ ]] || [ "$prio" -lt 1 ] || [ "$prio" -gt 10 ]; then
        echo -e "${RED}ERROR: Validación numérica fallida (Time > 0, Prio 1-10).${NC}"
        return 1
    fi

    acquire_lock || return 1
    echo "${sid}|${name}|${est}|${prio}" >> "$JOB_QUEUE_FILE"
    release_lock

    echo -e "${GREEN}✓ Job '$name' submitted.${NC}"
    log_event "SUBMIT: $name by $sid"
}

# ------------------------------------------------------------------------------
# Función: process_round_robin (Atómica y Segura)
# ------------------------------------------------------------------------------
process_round_robin() {
    echo -e "${BLUE}=== ROUND ROBIN PROCESSING (Q=${TIME_QUANTUM}s) ===${NC}"
    if [ ! -s "$JOB_QUEUE_FILE" ]; then echo "Empty queue."; return; fi

    acquire_lock || return 1
    TEMP_FILE="queue.tmp"
    > "$TEMP_FILE"

    while IFS="|" read -r sid name est prio; do
        if [ "$est" -le "$TIME_QUANTUM" ]; then
            echo -e "${GREEN}  ✓ COMPLETED: $name${NC}"
            echo "$sid|$name|0|$prio" >> "$COMPLETED_JOBS_FILE"
            log_event "COMPLETED (RR): $name"
        else
            local remaining=$((est - TIME_QUANTUM))
            echo -e "${YELLOW}  ▶ PARTIAL: $name (-${TIME_QUANTUM}s, Rem: ${remaining}s)${NC}"
            echo "$sid|$name|$remaining|$prio" >> "$TEMP_FILE"
            log_event "PARTIAL (RR): $name, Rem: $remaining"
        fi
    done < "$JOB_QUEUE_FILE"

    mv "$TEMP_FILE" "$JOB_QUEUE_FILE"
    release_lock
    echo "Cycle finished."
}

# ------------------------------------------------------------------------------
# Función: process_priority
# ------------------------------------------------------------------------------
process_priority() {
    echo -e "${BLUE}=== PRIORITY SCHEDULING ===${NC}"
    if [ ! -s "$JOB_QUEUE_FILE" ]; then echo "Empty queue."; return; fi

    acquire_lock || return 1
    # Ordenar por prioridad DESC (columna 4) y guardar en temporal
    sort -t"|" -k4,4nr "$JOB_QUEUE_FILE" -o "$JOB_QUEUE_FILE"

    while IFS="|" read -r sid name est prio; do
        echo -e "${GREEN}  ✓ EXECUTED (Prio $prio): $name${NC}"
        echo "$sid|$name|0|$prio" >> "$COMPLETED_JOBS_FILE"
        log_event "COMPLETED (PRIO): $name"
    done < "$JOB_QUEUE_FILE"

    > "$JOB_QUEUE_FILE"
    release_lock
    echo "All priority jobs processed."
}

# ------------------------------------------------------------------------------
# Función: view_completed_jobs
# ------------------------------------------------------------------------------
view_completed_jobs() {
    echo -e "${BLUE}=== COMPLETED HISTORY ===${NC}"
    [ ! -s "$COMPLETED_JOBS_FILE" ] && echo "No history found." && return

    # Mostrar últimos 10 para no saturar
    tail -n 10 "$COMPLETED_JOBS_FILE" | awk -F"|" '{printf "Student: %-10s | Job: %-15s | Status: OK\n", $1, $2}'
}

# --- Bucle Principal ---
while true; do
    show_menu
    read -p "Option [1-6]: " opt
    case "$opt" in
        1) view_pending_jobs ;;
        2) submit_job ;;
        3) process_round_robin ;;
        4) process_priority ;;
        5) view_completed_jobs ;;
        6) 
            echo "Exiting..."
            log_event "SHUTDOWN"
            rm -f "$LOCK_FILE"
            exit 0 ;;
        *) echo -e "${RED}Invalid option.${NC}" ;;
    esac
    read -p "Press Enter..." dummy
done
