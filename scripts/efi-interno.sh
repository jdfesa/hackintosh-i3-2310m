#!/bin/bash
set -e

if [ "$(id -u)" != "0" ]; then
  exec sudo bash "$0"
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SOURCE_EFI="${SCRIPT_DIR}/EFI"
LEGACY_DIR="${SCRIPT_DIR}/LegacyBoot"

echo "Instalador de EFI interna / OpenDuet Legacy"
echo
diskutil list
echo
if [ -n "$1" ]; then
  DISK_NUM="$1"
else
  echo "Escribi SOLO el numero del disco interno."
  echo "Ejemplo: si es /dev/disk0, escribi 0"
  read -r DISK_NUM
fi

case "${DISK_NUM}" in
  ''|*[!0-9]*)
    echo "Numero de disco invalido."
    exit 1
    ;;
esac

DISK="disk${DISK_NUM}"
EFI_PART="${DISK}s1"

echo
diskutil info "${DISK}"
echo
echo "Voy a instalar OpenDuet en /dev/${DISK}"
echo "y copiar la carpeta EFI a /dev/${EFI_PART}."
echo
if [ -n "$2" ]; then
  CONFIRM="$2"
else
  echo "Para confirmar escribi SI:"
  read -r CONFIRM
fi

if [ "${CONFIRM}" != "SI" ]; then
  echo "Cancelado."
  exit 1
fi

if [ ! -d "${SOURCE_EFI}" ]; then
  echo "Error: no encontre ${SOURCE_EFI}"
  exit 1
fi

if [ ! -f "${LEGACY_DIR}/BootInstall_X64.tool" ]; then
  echo "Error: no encontre ${LEGACY_DIR}/BootInstall_X64.tool"
  exit 1
fi

if ! diskutil info "${EFI_PART}" | grep -q -e FAT_32 -e EFI; then
  echo "Error: ${EFI_PART} no parece ser una particion EFI/FAT32."
  echo "No toque nada. Copia el resultado de diskutil list para revisarlo."
  exit 1
fi

echo
echo "Instalando OpenDuet Legacy..."
printf "%s\n" "${DISK_NUM}" | bash "${LEGACY_DIR}/BootInstall_X64.tool"

echo
echo "Montando particion EFI interna..."
diskutil mount "${EFI_PART}" >/dev/null 2>&1 || true

MOUNT_POINT="$(diskutil info "${EFI_PART}" | awk -F': *' '/Mount Point/ {print $2}')"

if [ -z "${MOUNT_POINT}" ] || [ ! -d "${MOUNT_POINT}" ]; then
  echo "No pude detectar el punto de montaje de ${EFI_PART}."
  exit 1
fi

if [ -d "${MOUNT_POINT}/EFI" ]; then
  BACKUP="${MOUNT_POINT}/EFI.backup.$(date +%Y%m%d-%H%M%S)"
  echo "Ya existe una carpeta EFI. Backup:"
  echo "  ${BACKUP}"
  mv "${MOUNT_POINT}/EFI" "${BACKUP}"
fi

echo "Copiando EFI funcional..."
cp -R "${SOURCE_EFI}" "${MOUNT_POINT}/"

echo
echo "Validando archivos clave:"
ls -l "${MOUNT_POINT}/boot" \
  "${MOUNT_POINT}/EFI/BOOT/BOOTx64.efi" \
  "${MOUNT_POINT}/EFI/OC/OpenCore.efi" \
  "${MOUNT_POINT}/EFI/OC/config.plist"

echo
echo "Listo. Apaga, saca el pendrive y prueba arrancar desde el disco interno."
