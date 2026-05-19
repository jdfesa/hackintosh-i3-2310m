#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
OUT="${SCRIPT_DIR}/red-diagnostico-$(date +%Y%m%d-%H%M%S).txt"

if ! touch "${OUT}" >/dev/null 2>&1; then
  OUT="${HOME}/Desktop/red-diagnostico-$(date +%Y%m%d-%H%M%S).txt"
fi

exec > "${OUT}" 2>&1

section() {
  echo
  echo "===== $1 ====="
}

section "Fecha"
date

section "Sistema"
sw_vers
uname -a

section "Kexts de red cargados"
kextstat | grep -i -E "realtek|rtl|asix|ethernet|ionetwork" || true

section "Interfaces ifconfig"
ifconfig -a

section "Servicios de red"
networksetup -listallhardwareports || true

section "Detectar nuevo hardware de red"
networksetup -detectnewhardware || true

section "IORegistry red / Realtek / USB Ethernet"
ioreg -l | grep -i -E "realtek|rtl|8168|8111|ethernet|ionetworkinterface|ioethernetinterface|asix|ax887|8152|8153" | head -200 || true

section "System log red"
grep -i -E "realtek|rtl|ethernet|en0|en1|dhcp|network|asix|ax887|8152|8153" /var/log/system.log | tail -200 || true

echo
echo "Reporte guardado en: ${OUT}"
