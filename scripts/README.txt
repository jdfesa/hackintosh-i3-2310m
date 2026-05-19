Scripts para ejecutar desde Mavericks
====================================

No hace falta montar la particion EFI para estos scripts.

Comandos cortos:

1. Activar SSH:

   bash /Volumes/Install*/scripts/ssh.sh

2. Instalar Ethernet Realtek:

   bash /Volumes/Install*/scripts/red.sh

3. Reiniciar.

4. Verificar red:

   bash /Volumes/Install*/scripts/ver.sh

5. Si no funciona, generar reporte:

   bash /Volumes/Install*/scripts/diag.sh

6. Detectar hardware general:

   bash /Volumes/Install*/scripts/detectar-hardware.sh

7. Instalar EFI en disco interno:

   bash /Volumes/Install*/scripts/efi-interno.sh

El kext Realtek necesario esta incluido en:

   /Volumes/Install*/scripts/kexts/RealtekRTL8111.kext

La EFI funcional y OpenDuet Legacy estan incluidos en:

   /Volumes/Install*/scripts/EFI
   /Volumes/Install*/scripts/LegacyBoot

Documentacion relacionada:

   SSH-MAVERICKS.md
   ARRANQUE-DISCO-INTERNO.md
