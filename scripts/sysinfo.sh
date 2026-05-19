#!/bin/bash
# ============================================================================
# sysinfo.sh - Hardware info display para Hackintosh (compatible Mavericks+)
# ============================================================================
# Uso: bash sysinfo.sh
#
# Muestra informacion del hardware en formato visual similar a fastfetch/
# neofetch. No muestra datos personales (IP, serial, UUID, MAC address).
# Funciona con bash puro y comandos del sistema, sin dependencias externas.
# ============================================================================

# --- Colores ANSI ---
RST='\033[0m'
BOLD='\033[1m'
# Colores del logo Apple clasico (versiones oscuras para fondo claro)
C1='\033[38;5;22m'  # Verde oscuro
C2='\033[38;5;130m' # Amarillo/marron oscuro
C3='\033[38;5;166m' # Naranja oscuro
C4='\033[38;5;124m' # Rojo oscuro
C5='\033[38;5;90m'  # Violeta oscuro
C6='\033[38;5;25m'  # Azul oscuro
# Info
LBL='\033[38;5;25m' # Azul oscuro (etiquetas)
VAL='\033[38;5;236m' # Gris muy oscuro (valores - legible en fondo blanco)
DIM='\033[38;5;245m' # Gris medio (separadores)

# --- Recopilar datos ---

# OS
os_name=$(sw_vers -productName 2>/dev/null || echo "macOS")
os_ver=$(sw_vers -productVersion 2>/dev/null || echo "?")
os_build=$(sw_vers -buildVersion 2>/dev/null || echo "?")

# Kernel
kernel=$(uname -sr 2>/dev/null || echo "?")

# Hostname (sin dominio, seguro)
hostname_short=$(scutil --get ComputerName 2>/dev/null || hostname -s 2>/dev/null || echo "Mac")

# CPU
cpu_brand=$(sysctl -n machdep.cpu.brand_string 2>/dev/null || echo "?")
cpu_cores=$(sysctl -n hw.physicalcpu 2>/dev/null || echo "?")
cpu_threads=$(sysctl -n hw.logicalcpu 2>/dev/null || echo "?")

# RAM
ram_bytes=$(sysctl -n hw.memsize 2>/dev/null || echo "0")
ram_gb=$(echo "scale=0; $ram_bytes / 1073741824" | bc 2>/dev/null || echo "?")

# GPU
gpu_info=$(system_profiler SPDisplaysDataType 2>/dev/null | grep "Chipset Model\|Chip Model" | head -1 | sed 's/.*: //')
if [ -z "$gpu_info" ]; then
    gpu_info="?"
fi

# VRAM
vram_info=$(system_profiler SPDisplaysDataType 2>/dev/null | grep -i "VRAM\|Total Number of Cores" | head -1 | sed 's/.*: //')

# Resolucion
resolution=$(system_profiler SPDisplaysDataType 2>/dev/null | grep "Resolution" | head -1 | sed 's/.*: //' | sed 's/ Retina//')

# Disco principal
disk_total=""
disk_used=""
disk_info=$(df -H / 2>/dev/null | tail -1)
if [ -n "$disk_info" ]; then
    disk_total=$(echo "$disk_info" | awk '{print $2}')
    disk_used=$(echo "$disk_info" | awk '{print $3}')
    disk_pct=$(echo "$disk_info" | awk '{print $5}')
fi

# Modelo (SMBIOS / real)
model_id=$(sysctl -n hw.model 2>/dev/null || echo "?")

# Bootloader (intentar detectar OpenCore)
bootloader="?"
if [ -f /Volumes/EFI/EFI/OC/OpenCore.efi ] 2>/dev/null; then
    bootloader="OpenCore"
elif ioreg -l 2>/dev/null | grep -q "acidanthera\|OpenCore"; then
    bootloader="OpenCore"
fi

# Uptime
uptime_str="?"
raw_uptime=$(uptime 2>/dev/null)
if echo "$raw_uptime" | grep -q "days\|day"; then
    uptime_str=$(echo "$raw_uptime" | sed 's/.*up \([^,]*,[^,]*\),.*/\1/' | sed 's/  */ /g' | xargs)
elif echo "$raw_uptime" | grep -q "up"; then
    uptime_str=$(echo "$raw_uptime" | sed 's/.*up \([^,]*\),.*/\1/' | xargs)
fi

# Shell
shell_name=$(basename "$SHELL" 2>/dev/null || echo "?")

# Terminal
term_name="${TERM_PROGRAM:-$TERM}"

# Bateria (si es laptop)
batt_info=""
batt_pct=$(pmset -g batt 2>/dev/null | grep -o '[0-9]*%' | head -1)
if [ -n "$batt_pct" ]; then
    batt_state=$(pmset -g batt 2>/dev/null | grep -o "'.*'" | tr -d "'")
    if [ -n "$batt_state" ]; then
        batt_info="$batt_pct ($batt_state)"
    else
        batt_info="$batt_pct"
    fi
fi

# Ethernet / WiFi chip (sin mostrar IP ni MAC, solo el modelo)
eth_chip=$(system_profiler SPEthernetDataType 2>/dev/null | grep "Vendor ID\|Device ID\|Type\|Product" | head -2 | sed 's/.*: //' | tr '\n' ' ')
wifi_chip=$(system_profiler SPAirPortDataType 2>/dev/null | grep "Card Type\|Chipset" | head -1 | sed 's/.*: //')

# Audio
audio_chip=$(system_profiler SPAudioDataType 2>/dev/null | grep "Chip\|Device" | head -1 | sed 's/.*: //')

# --- Armar lineas de info ---
lines=()
add_line() {
    lines+=("${LBL}${BOLD}$1${RST}  ${VAL}$2${RST}")
}

add_line "OS" "$os_name $os_ver ($os_build)"
add_line "Kernel" "$kernel"
add_line "Model" "$model_id"
[ "$bootloader" != "?" ] && add_line "Bootloader" "$bootloader"
add_line "CPU" "$cpu_brand"
add_line "Cores" "${cpu_cores} fisicos / ${cpu_threads} hilos"
add_line "RAM" "${ram_gb} GB"
add_line "GPU" "$gpu_info"
[ -n "$vram_info" ] && add_line "VRAM" "$vram_info"
[ -n "$resolution" ] && add_line "Display" "$resolution"
[ -n "$disk_total" ] && add_line "Disk (/)" "${disk_used} / ${disk_total} (${disk_pct})"
add_line "Uptime" "$uptime_str"
add_line "Shell" "$shell_name"
[ -n "$term_name" ] && add_line "Terminal" "$term_name"
[ -n "$batt_info" ] && add_line "Battery" "$batt_info"
[ -n "$wifi_chip" ] && add_line "WiFi" "$wifi_chip"
[ -n "$audio_chip" ] && add_line "Audio" "$audio_chip"

# --- Logo ASCII (manzana clasica con colores arcoiris) ---
logo=(
"${C1}                 ###          "
"${C1}               ####           "
"${C1}               ###            "
"${C1}       #######    #######     "
"${C2}     ######################   "
"${C2}    #####################     "
"${C3}    ####################      "
"${C3}    ####################      "
"${C4}    #####################     "
"${C4}     ######################   "
"${C5}      ####################    "
"${C5}       ################       "
"${C6}        ####     #####        "
)

# --- Imprimir ---
echo ""

# Titulo
title_line="${C1}${BOLD}  ${hostname_short}${RST}"

total_lines=${#logo[@]}
info_start=1  # dejar una linea para el titulo

for i in $(seq 0 $((total_lines + 2))); do
    # Logo (columna izquierda)
    if [ $i -lt $total_lines ]; then
        logo_part="${logo[$i]}"
    else
        logo_part="                              "
    fi

    # Info (columna derecha)
    if [ $i -eq 0 ]; then
        info_part="$title_line"
    elif [ $i -eq 1 ]; then
        # Separador debajo del titulo
        sep=""
        name_len=${#hostname_short}
        for s in $(seq 1 $((name_len + 2))); do sep="${sep}-"; done
        info_part="${DIM}  ${sep}${RST}"
    else
        idx=$((i - 2))
        if [ $idx -lt ${#lines[@]} ]; then
            info_part="${lines[$idx]}"
        else
            info_part=""
        fi
    fi

    printf "%b  %b\n" "$logo_part" "$info_part"
done

# Paleta de colores
echo ""
printf "  "
for c in 0 1 2 3 4 5 6 7; do
    printf "\033[4%dm   \033[0m" "$c"
done
echo ""
printf "  "
for c in 0 1 2 3 4 5 6 7; do
    printf "\033[10%dm   \033[0m" "$c"
done
echo ""
echo ""
