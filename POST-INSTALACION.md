# Post-instalacion - Positivo BGH A470 / Mavericks 10.9.5

Este documento registra los pasos posteriores a la primera instalacion exitosa de macOS Mavericks 10.9.5 en la Positivo BGH A470 con Intel Core i3-2310M.

Documentos relacionados:

* [`TROUBLESHOOTING.md`](TROUBLESHOOTING.md): errores historicos, fixes aplicados y pendientes actuales.
* [`DETECCION-HARDWARE.md`](DETECCION-HARDWARE.md): como generar y actualizar `hardware-info.txt`.
* [`SSH-MAVERICKS.md`](SSH-MAVERICKS.md): conexion remota, compatibilidad SSH y tunel reverso.
* [`ARRANQUE-DISCO-INTERNO.md`](ARRANQUE-DISCO-INTERNO.md): instalacion de EFI interna y repeticion del proceso en SSD.

## Estado inicial

La instalacion ya finalizo y la EFI actual permite arrancar Mavericks con
OpenCore en modo Legacy desde el disco interno.

Actualizacion 2026-05-19:

* El pendrive tenia `config.plist` sincronizado con el repo, pero no todos los
  kexts presentes. Esto dejaba entradas activas apuntando a bundles ausentes.
* Se resincronizo `EFI/` al pendrive preservando el archivo legacy `/boot`.
* Para la siguiente prueba de arranque, la EFI queda en modo minimo:
  `FakeSMC.kext` + `VoodooPS2Controller.kext`.
* `Lilu.kext`, `AppleALC.kext`, `ECEnabler.kext` y `WhateverGreen.kext`
  quedan desactivados hasta confirmar Ethernet.
* `RealtekRTL8111.kext` queda presente en `EFI/OC/Kexts`, pero no se inyecta
  desde OpenCore porque el log reporta `Invalid Parameter`.
* Teclado y trackpad internos funcionan.
* La red funciona por adaptador USB Ethernet.
* El equipo ya no depende del pendrive para arrancar.

Valores criticos que no conviene tocar por ahora:

* `PlatformInfo -> Generic -> SystemProductName = MacBookPro8,1`
* `PlatformInfo -> UpdateSMBIOSMode = Create`
* `PlatformInfo -> Generic -> SpoofVendor = True`
* `PlatformInfo -> Generic -> AdviseFeatures = False`
* `Kernel -> Quirks -> CustomSMBIOSGuid = False`
* `Kernel -> Emulate -> DummyPowerManagement = True`

## Prioridad 1 - Entrada PS/2

Estado actual: resuelto. Teclado y trackpad internos funcionan.

Referencia historica:

La EFI original tenia `VoodooPS2Controller.kext` 2.3.8, pero ese kext y sus
plugins declaraban `LSMinimumSystemVersion = 10.10`. Mavericks es 10.9.5, por
lo que podia no cargar.

Fix aplicado:

* Se uso `VoodooPS2Controller.kext` compatible con Mavericks.
* Se habilitaron sus plugins PS/2 en `Kernel -> Add`.

Verificacion:

```bash
kextstat | grep -i voodoo
```

Notas:

* Si el teclado funciona pero el trackpad no, revisar si el trackpad es Synaptics/Elan y probar una variante antigua compatible con 10.9.
* No mezclar varias familias PS/2 al mismo tiempo.

## Prioridad 2 - Red Ethernet

Problema actual: hay red por adaptador USB Ethernet, pero el puerto Ethernet
interno no funciona todavia.

Estado de la EFI actualizado:

* `AtherosE2200Ethernet.kext` esta desactivado y pide minimo 10.13.
* `RealtekRTL8111.kext` moderno esta descartado porque pide minimo 10.14.
* `IntelMausi.kext` fue desactivado porque probablemente no corresponde al hardware de esta notebook.
* `RealtekRTL8100.kext` 2.0.1 fue desactivado: apunta a `10ec:8136` pero el chip real es `10ec:8168`.
* El chip Ethernet fue identificado desde el IORegistry como `vendor-id=0x10EC, device-id=0x8168` -> **Realtek RTL8168/RTL8111**.
* Se reemplazo el `.kext` en `EFI/OC/Kexts/` por **`RealtekRTL8111` v2.2.2** (sin `LSMinimumSystemVersion`, compatible con macOS 10.6+).
* El `IOPCIMatch` de la v2.2.2 es `0x816810ec` — coincide exactamente con el hardware.
* Prueba fallida: OpenCore registra `OC: Prelinked injection RealtekRTL8111.kext ... - Invalid Parameter`.
* Estado actual: kext desactivado en `config.plist`. La siguiente prueba es instalarlo dentro de Mavericks y reconstruir cache.

La Positivo BGH A470 no parece tener una limitacion fisica que impida Ethernet
por cable. El hardware detectado (`10ec:8168`) coincide con
`RealtekRTL8111.kext` v2.2.2. El problema actual es el metodo de carga: la
inyeccion por OpenCore falla antes de que Mavericks cree `en0`.

Accion recomendada:

1. Arrancar Mavericks con el pendrive.
2. Ejecutar:
   ```bash
   bash /Volumes/Install*/scripts/red.sh
   ```
3. Reiniciar.
4. Verificar:
   ```bash
   bash /Volumes/Install*/scripts/ver.sh
   ```
5. Si aparece la interfaz pero no recibe IP:
   ```bash
   sudo ipconfig set en0 DHCP
   ```
   Cambiar `en0` por la interfaz real si aparece como `en1` o `en2`.
6. Si sigue sin funcionar, generar reporte:
   ```bash
   bash /Volumes/Install*/scripts/diag.sh
   ```

Nota sobre el adaptador USB Ethernet:

Que muestre una MAC indica que al menos una parte del
adaptador fue detectada. Si no obtiene IP, puede faltar el servicio de red, el
DHCP puede no estar asignando, o el adaptador puede requerir driver especifico
para Mavericks. Primero identificar la interfaz con `ifconfig -a` y
`networksetup -listallhardwareports`.

Estado actual: la red por USB Ethernet funciona y sirve como puente para
habilitar SSH. El puerto Ethernet interno sigue pendiente. La conexion remota
quedo documentada en [`SSH-MAVERICKS.md`](SSH-MAVERICKS.md).

Para activar SSH:

```bash
bash /Volumes/Install*/scripts/ssh.sh
```

## Prioridad 3 - Arranque desde disco interno

Estado actual: resuelto. El sistema ya arranca sin pendrive.

Comando usado:

```bash
sudo bash /Volumes/Install*/scripts/efi-interno.sh 0 SI
```

El script instala OpenDuet Legacy, monta la particion EFI interna, guarda backup
de una EFI previa si existe y copia la EFI funcional incluida en `scripts/EFI`.
El procedimiento completo queda en
[`ARRANQUE-DISCO-INTERNO.md`](ARRANQUE-DISCO-INTERNO.md).

Recordatorio de layout Legacy:

```text
/boot
/EFI/BOOT/BOOTx64.efi
/EFI/OC/OpenCore.efi
/EFI/OC/config.plist
```

## Prioridad 4 - Audio

Estado actual: `AppleALC.kext` esta presente pero desactivado para la prueba de arranque minimo. `alcid=3` se puede restaurar cuando se reactive audio.

Accion recomendada:

1. Identificar codec de audio.
2. Si no hay audio, probar otros `alcid` compatibles con el codec real.
3. Verificar:
   ```bash
   kextstat | grep -i applealc
   ioreg -l | grep -i "layout-id"
   ```

## Prioridad 5 - Graficos Intel HD 3000

Estado actual: SMBIOS `MacBookPro8,1` y `AAPL,snb-platform-id = 00000100`.

Accion recomendada:

1. Confirmar aceleracion grafica.
2. En "About This Mac" / "System Information", revisar que Intel HD Graphics 3000 tenga memoria asignada y aceleracion.
3. Si no hay QE/CI, revisar framebuffer SNB y propiedades de IGPU.

## Prioridad 6 - Bateria, brillo y energia

Estado actual:

* `SMCBatteryManager.kext` esta desactivado porque depende de `VirtualSMC.kext`, y la EFI de recuperacion usa `FakeSMC.kext`.
* `BrightnessKeys.kext` esta desactivado porque pide minimo 10.11.
* `DummyPowerManagement = True` esta activo para estabilizar la instalacion.

Accion recomendada:

1. Confirmar si macOS muestra porcentaje de bateria.
2. Revisar brillo por teclas y slider.
3. Mas adelante, cuando teclado/red esten resueltos, evaluar quitar `DummyPowerManagement` y construir SSDTs especificos.

## Kexts incompatibles ya detectados

No reactivar estos kexts en Mavericks salvo que se reemplacen por versiones antiguas compatibles:

| Kext | Version actual | Minimo declarado | Estado |
| --- | --- | --- | --- |
| `AtherosE2200Ethernet.kext` | 2.4.0 | 10.13 | Desactivado |
| `RealtekRTL8111.kext` | 2.4.2 | 10.14 | Desactivado |
| `USBInjectAll.kext` | 1.0 | 10.11 | Desactivado |
| `BrightnessKeys.kext` | 1.0.4 | 10.11 | Desactivado |
| `VoodooPS2Controller.kext` | 2.3.8 | 10.10 | Debe reemplazarse |

## Kexts agregados para prueba

| Kext | Version | Motivo | Estado |
| --- | --- | --- | --- |
| `RealtekRTL8111.kext` | 2.2.2 | Ethernet Realtek RTL8168/RTL8111, chip confirmado `10ec:8168` | En EFI, no inyectado por OpenCore; instalar en S/L/E |
| `RealtekRTL8100.kext` | 2.0.1 | Descartado — chip real no es RTL810x sino RTL8168 | Desactivado |

## Checklist inmediato

1. Mantener documentado el arranque interno funcional.
2. Conservar red por USB Ethernet como canal de rescate.
3. Revisar puerto Ethernet interno `10ec:8168`.
4. Continuar con audio.
5. Confirmar aceleracion grafica Intel HD 3000.
6. Revisar bateria, brillo y energia.

## Referencias

* VoodooPS2 10.9 Only: https://www.insanelymac.com/forum/files/file/91-voodoops2-109-only/
* RehabMan VoodooPS2Controller: https://github.com/RehabMan/OS-X-Voodoo-PS2-Controller
* Nota sobre bug corregido en VoodooPS2 1.8.7 para Mavericks: https://www.oldschooldaw.com/forums/index.php?topic=7023.0
* RealtekRTL8100 soporta familias RTL8101E/RTL8102E/RTL8103E/RTL8105E/RTL8106E: https://old.kext.me/
