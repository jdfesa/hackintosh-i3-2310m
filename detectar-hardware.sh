#!/bin/bash
# =============================================================
# SCRIPT COMPLETO DE DETECCION DE HARDWARE PARA HACKINTOSH
# Mavericks 10.9 - Positivo BGH A470
# Ejecutar: bash /Volumes/EFI/detectar-hardware.sh
# Resultado: ~/Desktop/hardware-info.txt
# =============================================================

OUT=~/Desktop/hardware-info.txt

echo "============================================" > $OUT
echo "  HARDWARE INFO - Positivo BGH A470" >> $OUT
echo "  Fecha: $(date)" >> $OUT
echo "============================================" >> $OUT

# --- CPU ---
echo "" >> $OUT
echo "=== CPU ===" >> $OUT
sysctl -n machdep.cpu.brand_string >> $OUT 2>&1
sysctl -a | grep -E "cpu\.(family|model|extmodel|stepping|vendor)" >> $OUT 2>&1
echo "Cores fisicos: $(sysctl -n hw.physicalcpu)" >> $OUT
echo "Cores logicos: $(sysctl -n hw.logicalcpu)" >> $OUT

# --- RAM ---
echo "" >> $OUT
echo "=== RAM ===" >> $OUT
system_profiler SPMemoryDataType 2>/dev/null >> $OUT

# --- GPU / PCI COMPLETO ---
echo "" >> $OUT
echo "=== GPU y PCI (todos los dispositivos) ===" >> $OUT
system_profiler SPPCIDataType 2>/dev/null >> $OUT

# --- AUDIO CODEC (esto es lo critico) ---
echo "" >> $OUT
echo "=== AUDIO CODEC (raw) ===" >> $OUT
ioreg -l | grep -i -E "codec|hda|alc|realtek|audio|hdaudio" >> $OUT 2>&1
system_profiler SPAudioDataType 2>/dev/null >> $OUT

# --- AUDIO CODEC via kextstat ---
echo "" >> $OUT
echo "=== Kexts de audio cargados ===" >> $OUT
kextstat | grep -i -E "audio|hda|alc" >> $OUT 2>&1

# --- ETHERNET exacto ---
echo "" >> $OUT
echo "=== ETHERNET (chipset exacto) ===" >> $OUT
system_profiler SPEthernetDataType 2>/dev/null >> $OUT
ioreg -l | grep -i -A5 -B2 "ethernet\|rtl\|atheros\|intel.*mausi\|8111\|8168\|8100\|8136" >> $OUT 2>&1

# --- WIFI ---
echo "" >> $OUT
echo "=== WIFI ===" >> $OUT
system_profiler SPAirPortDataType 2>/dev/null >> $OUT
ioreg -l | grep -i -A5 "airport\|wifi\|wlan\|wireless\|8176\|8188" >> $OUT 2>&1

# --- USB completo ---
echo "" >> $OUT
echo "=== USB ===" >> $OUT
system_profiler SPUSBDataType 2>/dev/null >> $OUT

# --- ALMACENAMIENTO ---
echo "" >> $OUT
echo "=== ALMACENAMIENTO ===" >> $OUT
system_profiler SPStorageDataType 2>/dev/null >> $OUT
diskutil list >> $OUT 2>&1

# --- ACPI / DSDT (para SSDT) ---
echo "" >> $OUT
echo "=== ACPI y nombres de dispositivos ===" >> $OUT
ioreg -l | grep -i -E "ACPI|acpi-path|IOACPIPlane|IONameMatched" | head -80 >> $OUT 2>&1

# --- TODOS LOS IDs PCI en formato limpio ---
echo "" >> $OUT
echo "=== PCI DEVICE IDs (formato limpio) ===" >> $OUT
ioreg -l -p IOService | grep -E "vendor-id|device-id|subsystem-vendor-id|subsystem-id|IOName" | \
  sed 's/.*"\(.*\)".*/\1/' | grep -v "^$" | sort -u >> $OUT 2>&1

# --- BATTERIA / EC ---
echo "" >> $OUT
echo "=== BATERIA ===" >> $OUT
system_profiler SPPowerDataType 2>/dev/null >> $OUT
ioreg -l | grep -i -E "battery|smartbattery|capacity|fullyCharged|isCharging" | head -20 >> $OUT 2>&1

# --- BACKLIGHT ---
echo "" >> $OUT
echo "=== BACKLIGHT / BRILLO ===" >> $OUT
ioreg -l | grep -i -E "backlight|brightness|display\|PNLF\|lcd" | head -20 >> $OUT 2>&1

# --- BLUETOOTH ---
echo "" >> $OUT
echo "=== BLUETOOTH ===" >> $OUT
system_profiler SPBluetoothDataType 2>/dev/null >> $OUT

# --- KEXTS ACTUALMENTE CARGADOS ---
echo "" >> $OUT
echo "=== KEXTS CARGADOS EN SISTEMA ===" >> $OUT
kextstat | grep -v "com.apple" >> $OUT 2>&1

# --- DMESG / LOG DEL KERNEL ---
echo "" >> $OUT
echo "=== LOG DEL KERNEL (ultimas 100 lineas relevantes) ===" >> $OUT
dmesg | grep -i -E "error|fail|warn|panic|ps2|trackpad|keyboard|ethernet|audio|hda|alc|rtl|atheros|usb" | tail -100 >> $OUT 2>&1

# --- IOREG COMPLETO DE AUDIO (critico para alcid) ---
echo "" >> $OUT
echo "=== IOREG AUDIO COMPLETO (para alcid) ===" >> $OUT
ioreg -l -p IOService | grep -i -A20 "HDEF\|hdaudio\|AppleHDA" >> $OUT 2>&1

# --- IOREG COMPLETO ETHERNET ---
echo "" >> $OUT
echo "=== IOREG ETHERNET COMPLETO ===" >> $OUT
ioreg -l -p IOService | grep -i -A20 "ethernet\|RTL\|Atheros\|Mausi" >> $OUT 2>&1

echo "" >> $OUT
echo "============================================" >> $OUT
echo "  FIN DEL INFORME" >> $OUT
echo "============================================" >> $OUT

echo ""
echo ">>> LISTO. Archivo guardado en: $OUT"
echo ">>> Copialo al pendrive con:"
echo "    cp ~/Desktop/hardware-info.txt /Volumes/EFI/"
