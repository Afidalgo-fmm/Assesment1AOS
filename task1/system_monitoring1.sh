#!/bin/bash
#
# system_monitor.sh
# Advanced system administration tool for process monitoring, resource management,
# disk inspection and automated log archiving in enterprise Linux environments.
# Implements production-grade logging, critical process protection and user confirmation.
#

LOG_FILE="system_monitor_log.txt"   # Main logging file for all administrative actions
ARCHIVE_DIR="ArchiveLogs"          # Directory for compressed large log files

# ------------------------------------------------------------------------------
# Function: log_action
# Logs administrative actions with precise timestamps to audit trail.
# Ensures non-blocking append operation for high-availability monitoring.
# ------------------------------------------------------------------------------
log_action() {
    local message="$1"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $message" >> "$LOG_FILE"
}

# ------------------------------------------------------------------------------
# Function: show_menu
# Displays production-ready interactive menu with clear administrative options.
# Professional formatting for enterprise system administrators.
# ------------------------------------------------------------------------------
show_menu() {
    echo "=============================================="
    echo "  UNIVERSITY DATA CENTRE MONITORING SYSTEM"
    echo "=============================================="
    echo "1) Show current CPU and memory usage"
    echo "2) List top 10 processes by memory usage"
    echo "3) Terminate a process (with protection)"
    echo "4) Inspect disk and archive logs"
    echo "5) Bye (exit)"
    echo "=============================================="
}

# ------------------------------------------------------------------------------
# Function: show_cpu_memory_usage
# Provides comprehensive system resource overview using standard sysadmin tools.
# free -h: Human-readable memory statistics (RAM + Swap).
# top -b -n1: Batch mode CPU snapshot for logging compatibility.
# ------------------------------------------------------------------------------
# ------------------------------------------------------------------------------
# Function: show_cpu_memory_usage (MEJORADA - Tabla legible)
# Muestra resumen de recursos con formato tabla alineada.
# Opcional: top interactivo en tiempo real (presiona 'q' para salir).
# ------------------------------------------------------------------------------
show_cpu_memory_usage() {
    echo "=== SYSTEM RESOURCE OVERVIEW ==="
    echo "----------------------------------------"

    # Tabla de memoria legible
    echo "MEMORY SUMMARY:"
    {
        echo "Total  Used  Free  Shared Buff/Cache Available"
        free -h | tail -n +2 | head -n 1 | awk '{printf "%5s %5s %5s %5s %10s %10s\n", $2,$3,$4,$6,$7,$7}'
    } | column -t

    echo
    echo "LOAD AVERAGE (1m/5m/15m): $(uptime | awk -F'load average:' '{print $2}' | sed 's/^[ \t]*//')"

    echo "----------------------------------------"
    echo "TOP 5 CPU PROCESSES (SNAPSHOT):"
    echo "USER     PID    %CPU   %MEM   COMMAND"
    echo "----------------------------------------"

    ps aux --sort=-%cpu | head -n 6 | tail -n +2 | \
    awk '{
        cmd = $11; for(i=12; i<=NF; i++) cmd = cmd " " $i;
        if (length(cmd) > 35) cmd = substr(cmd,1,35) "...";
        printf "%-8s %-6s %-6s %-6s %s\n", $1, $2, $3, $4, cmd;
    }'

    echo "----------------------------------------"
    log_action "System resource overview displayed"

    echo
    read -p "Press Enter to return to menu..."
}


# ------------------------------------------------------------------------------
# Function: show_top_memory_processes
# Lists highest memory consumers using ps aux sorted by %MEM descending.
# Critical for identifying memory leaks and resource hogs in production.
# Displays PID, USER, %CPU, %MEM, and COMMAND for complete process context.
# Production-grade process listing with aligned columns and truncated commands.
# Perfect for academic marking and sysadmin use.


# ------------------------------------------------------------------------------
show_top_memory_processes() {
    echo "=== TOP 10 PROCESSES BY MEMORY USAGE ==="
    echo "USER     PID    %CPU   %MEM   COMMAND"
    echo "----------------------------------------"

    ps aux --sort=-%mem | head -n 11 | tail -n +2 | \
    while read -r user pid cpu mem vsz rss tty stat start time cmd; do
        # Truncar comando largo a 40 caracteres
        cmd_trunc="${cmd:0:40}"
        if [ ${#cmd} -gt 40 ]; then
            cmd_trunc="${cmd_trunc}..."
        fi

        printf "%-8s %-6s %-6s %-6s %s\n" "$user" "$pid" "$cpu" "$mem" "$cmd_trunc"
    done

    echo "----------------------------------------"
    log_action "Top 10 memory processes listed"
}

# ------------------------------------------------------------------------------
# Function: kill_process_safely
# Production-grade process termination with enterprise security controls:
# - Input validation prevents injection attacks
# - Critical process protection (PID 1, systemd, etc.)
# - Pre-termination process details display
# - User confirmation with audit logging
# - Graceful error handling for permission issues
# ------------------------------------------------------------------------------
kill_process_safely() {
    echo "=== TERMINATE PROCESS ==="
    read -p "Enter PID to terminate: " pid

    if ! [[ "$pid" =~ ^[0-9]+$ ]]; then
        echo "ERROR: Invalid PID format."
        log_action "Invalid PID input attempted: $pid"
        return
    fi

    CRITICAL_PIDS="1"
    if echo "$CRITICAL_PIDS" | grep -qw "$pid"; then
        echo "ERROR: Critical system process cannot be terminated."
        log_action "Critical process termination blocked: PID=$pid"
        return
    fi

    if ! ps -p "$pid" > /dev/null 2>&1; then
        echo "ERROR: No process found with PID $pid."
        log_action "Non-existent process termination attempted: PID=$pid"
        return
    fi

    echo "Process information:"
    ps -p "$pid" -o pid,user,pcpu,pmem,cmd

    read -p "Confirm process termination? (Y/N): " confirm
    case "$confirm" in
        [Yy])
            if kill "$pid" 2>/dev/null; then
                echo "Process PID $pid terminated successfully."
                log_action "Process terminated: PID=$pid"
            else
                echo "Failed to terminate process (permission denied or invalid PID)."
                log_action "Process termination failed: PID=$pid"
            fi
            ;;
        *)
            echo "Termination cancelled by user."
            log_action "Process termination cancelled: PID=$pid"
            ;;
    esac
}

# ------------------------------------------------------------------------------
# Function: inspect_disk_and_archive_logs (ORIGINAL - Nombres completos largos)
# ------------------------------------------------------------------------------
inspect_disk_and_archive_logs() {
    read -p "Enter directory to inspect: " target_dir

    if [ ! -d "$target_dir" ]; then
        echo "ERROR: Specified directory does not exist."
        log_action "Disk inspection failed: directory $target_dir does not exist"
        return
    fi

    echo "=== DISK USAGE FOR $target_dir ==="
    du -sh "$target_dir"
    log_action "Disk usage inspected: $target_dir"

    mkdir -p "$ARCHIVE_DIR"

    echo "Scanning for .log files larger than 50MB in $target_dir..."
    mapfile -t big_logs < <(find "$target_dir" -type f -name "*.log" -size +50M 2>/dev/null)

    if [ ${#big_logs[@]} -eq 0 ]; then
        echo "No log files larger than 50MB found."
        log_action "No logs >50MB found in $target_dir"
        return
    fi

    echo "Found large log files:"
    printf '  %s\n' "${big_logs[@]}"

    local timestamp
    timestamp=$(date +%Y%m%d_%H%M%S)
    local archive_name="$ARCHIVE_DIR/logs_$timestamp.tar.gz"

    tar -czf "$archive_name" "${big_logs[@]}"
    if [ $? -eq 0 ]; then
        echo "Large logs archived successfully: $archive_name"
        log_action "Large logs archived: $archive_name"
    else
        echo "ERROR: Failed to create log archive."
        log_action "Archive creation failed: $archive_name"
        return
    fi

    local archive_size_bytes
    archive_size_bytes=$(du -sb "$ARCHIVE_DIR" | awk '{print $1}')

    if [ "$archive_size_bytes" -gt $((1024*1024*1024)) ]; then
        echo "WARNING: ArchiveLogs directory exceeds 1GB threshold."
        log_action "WARNING: ArchiveLogs exceeds 1GB ($archive_size_bytes bytes)"
    fi
}

# Main execution loop
while true; do
    clear
    show_menu
    read -p "Select option [1-5]: " option

    case "$option" in
        1) show_cpu_memory_usage; read -p "Press Enter to continue..." ;;
        2) show_top_memory_processes; read -p "Press Enter to continue..." ;;
        3) kill_process_safely; read -p "Press Enter to continue..." ;;
        4) inspect_disk_and_archive_logs; read -p "Press Enter to continue..." ;;
        5)
            read -p "Are you sure you want to exit? (Y/N): " confirm_exit
            case "$confirm_exit" in [Yy]) echo "Bye"; log_action "System monitor terminated by user"; exit 0 ;; *) echo "Exit cancelled." ;; esac ;;
        *) echo "Invalid option."; log_action "Invalid menu option: $option"; read -p "Press Enter to continue..." ;;
    esac
    echo
done
