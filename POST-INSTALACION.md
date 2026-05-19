# Post-instalacion - Positivo BGH A470 / Mavericks 10.9.5

Este documento registra los pasos posteriores a la primera instalacion exitosa de macOS Mavericks 10.9.5 en la Positivo BGH A470 con Intel Core i3-2310M.

Documentos relacionados:

* [`TROUBLESHOOTING.md`](TROUBLESHOOTING.md): errores historicos, fixes aplicados y diagnostico del cuelgue actual.
* [`DETECCION-HARDWARE.md`](DETECCION-HARDWARE.md): como generar y actualizar `hardware-info.txt`.

## Estado inicial

La instalacion ya finalizo y la EFI actual permite arrancar el instalador/sistema con OpenCore en modo Legacy.

Actualizacion 2026-05-19:

* El pendrive tenia `config.plist` sincronizado con el repo, pero no todos los
  kexts presentes. Esto dejaba entradas activas apuntando a bundles ausentes.
* Se resincronizo `EFI/` al pendrive preservando el archivo legacy `/boot`.
* Para la siguiente prueba de arranque, la EFI queda en modo minimo:
  `FakeSMC.kext` + `VoodooPS2Controller.kext`.
* `Lilu.kext`, `AppleALC.kext`, `ECEnabler.kext`, `WhateverGreen.kext` y red
  quedan desactivados hasta confirmar que el sistema deja de congelarse.

Valores criticos que no conviene tocar por ahora:

* `PlatformInfo -> Generic -> SystemProductName = MacBookPro8,1`
* `PlatformInfo -> UpdateSMBIOSMode = Create`
* `PlatformInfo -> Generic -> SpoofVendor = True`
* `PlatformInfo -> Generic -> AdviseFeatures = False`
* `Kernel -> Quirks -> CustomSMBIOSGuid = False`
* `Kernel -> Emulate -> DummyPowerManagement = True`

## Prioridad 1 - Entrada PS/2

Problema actual: no funcionan teclado ni trackpad internos.

Causa probable: la EFI tiene `VoodooPS2Controller.kext` 2.3.8, pero ese kext y sus plugins declaran `LSMinimumSystemVersion = 10.10`. Mavericks es 10.9.5, por lo que puede no cargar.

Accion recomendada:

1. Usar temporalmente teclado y mouse USB.
2. Reemplazar `EFI/OC/Kexts/VoodooPS2Controller.kext` por una version compatible con Mavericks.
3. Candidatos conocidos:
   * `VoodooPS2Controller` de RehabMan version 1.8.7 o posterior de la rama antigua, porque corrige un bug que impedia cargar en OS X 10.9.
   * `VoodooPS2-10.9 Only` version 1.8.3-10.9, recompilada especificamente para Mavericks.
4. Actualizar `Kernel -> Add` con el nuevo bundle y sus plugins.
5. Verificar en Mavericks:
   ```bash
   kextstat | grep -i voodoo
   grep -i voodoo /var/log/system.log
   ```

Notas:

* Si el teclado funciona pero el trackpad no, revisar si el trackpad es Synaptics/Elan y probar una variante antigua compatible con 10.9.
* No mezclar varias familias PS/2 al mismo tiempo.

## Prioridad 2 - Red Ethernet

Problema actual: no hay red.

Estado de la EFI actualizado:

* `AtherosE2200Ethernet.kext` esta desactivado y pide minimo 10.13.
* `RealtekRTL8111.kext` esta desactivado y pide minimo 10.14.
* `IntelMausi.kext` fue desactivado porque probablemente no corresponde al hardware de esta notebook.
* `RealtekRTL8100.kext` 2.0.1 fue desactivado: apunta a `10ec:8136` pero el chip real es `10ec:8168`.
* `RealtekRTL8111.kext` 2.4.2 está desactivado porque declara mínimo 10.14.
* **SOLUCIÓN APLICADA**: El chip Ethernet fue identificado desde el IORegistry como `vendor-id=0x10EC, device-id=0x8168` -> **Realtek RTL8168/RTL8111**.
* Se reemplazó el `.kext` en `EFI/OC/Kexts/` por **`RealtekRTL8111` v2.2.2** (sin `LSMinimumSystemVersion`, compatible con macOS 10.6+).
* El `IOPCIMatch` de la v2.2.2 es `0x816810ec` — coincide exactamente con el hardware.
* Estado actual: kext presente pero desactivado en `config.plist` hasta confirmar un arranque estable.

La Positivo BGH A470 tiene Ethernet 10/100. En equipos de esta epoca es comun encontrar Realtek PCIe Fast Ethernet de la familia RTL810x/RTL8105E. Si ese es el chip real, el kext correcto no es `RealtekRTL8111.kext`, sino `RealtekRTL8100.kext`.

El `RealtekRTL8100.kext` agregado declara `IOPCIMatch = 0x813610ec`, por lo que apunta al dispositivo Realtek `10ec:8136`, comun en controladoras PCIe Fast Ethernet RTL810x/RTL8105E. Como no funciono, hay dos posibilidades principales:

* La A470 no usa `10ec:8136` exactamente.
* El kext carga pero no adjunta al dispositivo por ACPI/PCI, conflicto de driver o inicializacion del chip.

Accion recomendada:

1. No seguir cambiando kexts de red a ciegas.
2. Verificar si el kext cargo:
   ```bash
   kextstat | grep -i realtek
   grep -i RealtekRTL8100 /var/log/system.log
   ifconfig
   ```
3. Identificar el chip real desde Linux live:
   ```bash
   lspci -nn | grep -i ethernet
   lspci -nn | grep -i network
   ```
4. Desde macOS, si aparece en IORegistry:
   ```bash
   ioreg -p IODeviceTree -l | grep -i ethernet
   ioreg -l | grep -i "vendor-id\|device-id\|IOName"
   ```
5. Si el ID no es `10ec:8136`, no insistir con este kext hasta saber el modelo exacto.
5. Si el ID no es `10ec:8136`, no insistir con este kext hasta saber el modelo exacto.
6. **RESUELTO**: ID confirmado como `10ec:8168`. Se instaló `RealtekRTL8111` v2.2.2.
7. Al arrancar con el pendrive actualizado, verificar con:
   ```bash
   kextstat | grep -i realtek
   ifconfig en0
   ```
8. Si aparece `en0` y hay IP asignada, el Ethernet está funcionando.

## Prioridad 3 - Arranque desde disco interno

Mientras el sistema dependa del pendrive, la instalacion no esta completa.

Accion recomendada:

1. Montar la particion EFI del disco interno.
2. Copiar la carpeta `EFI` funcional.
3. Instalar OpenDuet/Legacy boot tambien en el disco interno.
4. Verificar que la raiz de la particion booteable tenga el archivo `boot`, no solo la carpeta `EFI/`.

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
| `RealtekRTL8111.kext` | 2.2.2 | Ethernet Realtek RTL8168/RTL8111, chip confirmado `10ec:8168` | Desactivado hasta confirmar arranque estable |
| `RealtekRTL8100.kext` | 2.0.1 | Descartado — chip real no es RTL810x sino RTL8168 | Desactivado |

## Checklist inmediato

1. Arrancar con teclado/mouse USB.
2. Reemplazar `VoodooPS2Controller.kext` por version Mavericks.
3. Confirmar teclado interno.
4. Confirmar trackpad interno.
5. Identificar Ethernet con `lspci -nn`.
6. Instalar kext de red correcto.
7. Copiar EFI al disco interno e instalar OpenDuet en el disco.
8. Documentar cada cambio en este archivo y en `README.md`.

## Referencias

* VoodooPS2 10.9 Only: https://www.insanelymac.com/forum/files/file/91-voodoops2-109-only/
* RehabMan VoodooPS2Controller: https://github.com/RehabMan/OS-X-Voodoo-PS2-Controller
* Nota sobre bug corregido en VoodooPS2 1.8.7 para Mavericks: https://www.oldschooldaw.com/forums/index.php?topic=7023.0
* RealtekRTL8100 soporta familias RTL8101E/RTL8102E/RTL8103E/RTL8105E/RTL8106E: https://old.kext.me/
