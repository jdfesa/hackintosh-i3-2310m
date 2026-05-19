#!/bin/bash
set -e

KEXT_NAME="RealtekRTL8111.kext"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SOURCE_KEXT="${SCRIPT_DIR}/kexts/${KEXT_NAME}"
EXTENSIONS_DIR="/System/Library/Extensions"
TARGET_KEXT="${EXTENSIONS_DIR}/${KEXT_NAME}"

echo "Instalador de Ethernet Realtek para OS X Mavericks"

if [ "$(id -u)" != "0" ]; then
  exec sudo bash "$0"
fi

if [ ! -d "${SOURCE_KEXT}" ]; then
  echo "Error: no encontre el kext:"
  echo "  ${SOURCE_KEXT}"
  echo
  echo "Ejecuta este script desde la carpeta scripts del instalador."
  exit 1
fi

if [ ! -f "${SOURCE_KEXT}/Contents/Info.plist" ]; then
  echo "Error: ${SOURCE_KEXT} no parece ser un kext valido."
  exit 1
fi

if [ -d "${TARGET_KEXT}" ]; then
  BACKUP_KEXT="${TARGET_KEXT}.backup.$(date +%Y%m%d-%H%M%S)"
  echo "Ya existe ${TARGET_KEXT}; backup:"
  echo "  ${BACKUP_KEXT}"
  mv "${TARGET_KEXT}" "${BACKUP_KEXT}"
fi

echo "Copiando ${KEXT_NAME}..."
cp -R "${SOURCE_KEXT}" "${EXTENSIONS_DIR}/"

echo "Ajustando permisos..."
chown -R root:wheel "${TARGET_KEXT}"
chmod -R 755 "${TARGET_KEXT}"

if command -v xattr >/dev/null 2>&1; then
  xattr -dr com.apple.quarantine "${TARGET_KEXT}" >/dev/null 2>&1 || true
fi

echo "Reconstruyendo caches..."
touch "${EXTENSIONS_DIR}"

kextcache -system-prelinked-kernel || true
kextcache -system-caches || true

echo
echo "Listo. Reinicia y despues ejecuta:"
echo "  bash /Volumes/Install*/scripts/ver.sh"
