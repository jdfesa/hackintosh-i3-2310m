# Troubleshooting - Positivo BGH A470 / Mavericks

Este archivo concentra sintomas, causas probables, fixes aplicados y pruebas
pendientes. El README queda como indice limpio del proyecto.

## Estado de diagnostico actual

Fecha: 2026-05-19

Sintoma actual:

* OpenCore llega al picker.
* El menu es basico, con opciones como instalar Mavericks, iniciar desde disco
  y recovery.
* Al seleccionar el sistema, el equipo queda congelado.

Hallazgos:

* El pendrive montado en `/Volumes/EFI` tenia el mismo `config.plist` que el
  repo, pero `EFI/OC/Kexts` estaba incompleto.
* El `config.plist` intentaba cargar kexts ausentes en el pendrive, como
  `FakeSMC.kext`, `VoodooPS2Controller.kext` y `WhateverGreen.kext`.
* La carpeta `/Volumes/EFI/NVRAM` estaba vacia, pero no se considera la causa
  principal del cuelgue.
* `Lilu.kext` habia sido bajado a 1.2.6 para Mavericks, pero todavia habia
  plugins modernos activos o presentes. Esto puede provocar fallos silenciosos
  por mezcla de versiones.

Fix aplicado:

* Se resincronizo `EFI/` al pendrive preservando `/Volumes/EFI/boot`.
* Se dejo el arranque en modo minimo:
  * `FakeSMC.kext` activado.
  * `VoodooPS2Controller.kext` y plugins PS/2 activados.
  * `Lilu.kext`, `AppleALC.kext`, `ECEnabler.kext`, `WhateverGreen.kext`,
    red, bateria y brillo desactivados temporalmente.
* Se agregaron `-v -f debug=0x100 keepsyms=1 watchdog=0` a `boot-args` para
  obtener una falla mas visible si vuelve a congelar.

Proxima prueba:

1. Arrancar desde el pendrive corregido.
2. Elegir iniciar desde el disco instalado.
3. Si congela, sacar foto de la ultima linea verbose.
4. Al volver a montar el pendrive, buscar si existe `opencore-*.txt` en la raiz
   de la EFI.

## Problemas conocidos y fixes aplicados

### Arranque Legacy con cursor titilando

Problema:

La BIOS de la laptop no soporta UEFI. Si la particion booteable queda solo con
la carpeta `EFI/`, la BIOS no tiene primera etapa Legacy para cargar.

Fix:

Usar OpenDuet y ejecutar `BootInstall_X64.tool` sobre el pendrive o disco
interno. La raiz de la particion debe contener:

```text
/boot
/EFI/BOOT/BOOTx64.efi
/EFI/OC/OpenCore.efi
/EFI/OC/config.plist
```

### Kernel panic por SMBIOS incorrecto

Problema:

SMBIOS modernos como `MacBookPro16,2` causan cuelgue inmediato en esta
plataforma.

Fix:

Usar estrictamente `MacBookPro8,1`, que corresponde a Sandy Bridge.

### Producto incompatible o detecta POSITIVO BGH

Problema:

El instalador mostraba `This version of Mac OS X is not supported on this
platform`, usando como motivo la identidad real del equipo.

Fix:

Mantener esta combinacion:

```text
PlatformInfo -> Generic -> SystemProductName = MacBookPro8,1
PlatformInfo -> UpdateSMBIOSMode = Create
PlatformInfo -> Generic -> SpoofVendor = True
PlatformInfo -> Generic -> AdviseFeatures = False
Kernel -> Quirks -> CustomSMBIOSGuid = False
Kernel -> Emulate -> DummyPowerManagement = True
```

### X64 Exception Type 0E / Page Fault

Problema:

El driver `HfsPlus.efi` puede fallar en CPUs antiguos por falta de RDRAND.
Tambien se vio `OCB Loading Image failed - Volume Corrupt` con alternativas
modernas.

Fix:

Usar `HfsPlusLegacy.efi` y mantener `FixupAppleEfiImages = True`.

### Kexts incompatibles con Mavericks

Problema:

Varios kexts modernos declaran minimos superiores a OS X 10.9.5 o dependen de
versiones modernas de Lilu.

Ejemplos ya detectados:

| Kext | Motivo |
| --- | --- |
| `AtherosE2200Ethernet.kext` | no corresponde al hardware y/o requiere sistema mas nuevo |
| `RealtekRTL8111.kext` moderno | versiones nuevas declaran minimo posterior |
| `USBInjectAll.kext` | no usar hasta validar compatibilidad con 10.9 |
| `BrightnessKeys.kext` | minimo superior a Mavericks |
| `ECEnabler.kext` 1.0.6 | requiere Lilu 1.4.9 |
| `WhateverGreen.kext` 1.7.1 | desactivado hasta estabilizar HD3000 |

Regla actual:

No reactivar kexts de soporte extra hasta confirmar arranque estable con la EFI
minima.

### Picker sin teclado

Problema:

El teclado no respondia en el menu de OpenCore.

Fix:

* `PollAppleHotKeys = False`
* `KeySupport = False`
* `OpenUsbKbDxe.efi` habilitado para teclado USB en Legacy BIOS

### Cuelgue silencioso tras seleccionar Mavericks

Problema:

El sistema quedaba congelado tras mostrar un simple `ok`.

Fix:

`EnableVectorAcceleration = False`, porque el i3-2310M Sandy Bridge no soporta
AVX.

### Firmas caducadas del instalador

Problema:

El instalador de Mavericks puede fallar por certificados caducados.

Fix:

* `Misc -> Security -> DmgLoading = Any`
* En el instalador, abrir Terminal y ejecutar:

```bash
date 1010101014
```

### Kernel cache antiguo

Problema:

Mavericks maneja el prelinkedkernel de forma distinta a macOS modernos.

Fix:

`Kernel -> Scheme -> FuzzyMatch = True`

### Parche XCPM no encontrado

Problema:

El log mostraba `OCAK: Failed to apply dbg _xcpm_cst_control_evaluate patches
- Not Found`.

Fix:

`AppleXcpmCfgLock = False`. Se mantiene `AppleCpuPmCfgLock = True`.

### BIOS vuelve a valores por defecto

Problema:

Despues del reinicio, la BIOS podia perder prioridad de arranque o volver a
valores por defecto.

Fix aplicado:

* `NVRAM -> WriteFlash = False`
* `ResetNvramEntry.efi` desactivado

Pendiente:

Si sigue pasando, revisar fix RTC/AppleRTC especifico.

## Hardware confirmado desde hardware-info.txt

El informe actual confirma:

* CPU: Intel Core i3-2310M
* GPU: Intel HD Graphics 3000
* Ethernet: Realtek `10ec:8168`
* Wi-Fi: Realtek `10ec:8176`
* SMBIOS inyectado visible como `MacBookPro8,1`

Para regenerar el informe, seguir [`DETECCION-HARDWARE.md`](DETECCION-HARDWARE.md).

## Referencias de hardware similar

No se encontro una guia publica exacta para la Positivo BGH A470, pero hay
equipos cercanos con Sandy Bridge, Intel HD 3000 y BIOS Legacy:

* HP 630 con Intel Core i3-2310M
* HP ProBook 4530s con plataforma Intel 6 Series
* Commodore A24a con Intel Core i3-2310M
* Dell Latitude E5520 con Intel Core i3-2310M
* Dell Vostro 3450 con Intel Core i3-2310M e Intel HD 3000

La plataforma es viable para Mavericks. Lo delicado es Legacy boot, ACPI,
kexts compatibles con 10.9 y orden de activacion de componentes.
