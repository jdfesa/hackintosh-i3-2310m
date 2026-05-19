# Troubleshooting - Positivo BGH A470 / Mavericks

Este archivo concentra sintomas, causas probables, fixes aplicados y pruebas
pendientes. El README queda como indice limpio del proyecto.

## Estado de diagnostico actual

Fecha: 2026-05-19

Sintoma actual:

* OpenCore llega al picker.
* El menu es basico, con opciones como instalar Mavericks, iniciar desde disco
  y recovery.
* El sistema instalado ya arranca.
* El equipo ya arranca desde disco interno sin pendrive.
* Teclado y trackpad internos funcionan.
* Ethernet interno no aparece en red; `ifconfig en0` reporta que `en0` no
  existe.
* Un adaptador USB Ethernet ya permite conexion de red.
* SSH remoto funciona mediante tunel reverso cuando SSH directo no tiene ruta.

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
* El hardware Ethernet interno fue confirmado como Realtek `10ec:8168`.
* `RealtekRTL8111.kext` v2.2.2 coincide con ese PCI ID, pero OpenCore reporta:
  `Prelinked injection RealtekRTL8111.kext ... - Invalid Parameter`.
* Por ese fallo de inyeccion, Mavericks no llega a crear `en0`.

Fix aplicado:

* Se resincronizo `EFI/` al pendrive preservando `/Volumes/EFI/boot`.
* Se dejo el arranque base en modo minimo:
  * `FakeSMC.kext` activado.
  * `VoodooPS2Controller.kext` y plugins PS/2 activados.
  * `RealtekRTL8111.kext` v2.2.2 presente, pero desactivado en OpenCore.
  * `Lilu.kext`, `AppleALC.kext`, `ECEnabler.kext`, `WhateverGreen.kext`,
    bateria y brillo desactivados temporalmente.
* Se agregaron `-v -f debug=0x100 keepsyms=1 watchdog=0` a `boot-args` para
  obtener una falla mas visible si vuelve a congelar.
* Se agrego `scripts/red.sh` para instalar el kext en
  `/System/Library/Extensions` y reconstruir caches desde Mavericks.
* Se agrego `scripts/diag.sh` para generar reporte de kexts, interfaces,
  IORegistry y logs.
* Se documento la conexion remota en [`SSH-MAVERICKS.md`](SSH-MAVERICKS.md).
* Se instalo OpenDuet/EFI en el disco interno; procedimiento documentado en
  [`ARRANQUE-DISCO-INTERNO.md`](ARRANQUE-DISCO-INTERNO.md).

Estado siguiente:

1. Mantener red USB Ethernet como acceso de rescate.
2. Investigar Ethernet interno `10ec:8168`.
3. Continuar con audio, graficos, bateria y brillo.
4. Si se cambia HDD por SSD, repetir
   [`ARRANQUE-DISCO-INTERNO.md`](ARRANQUE-DISCO-INTERNO.md).

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

Estado actual:

Resuelto en el disco interno con `scripts/efi-interno.sh`. El equipo ya no
depende del pendrive para arrancar.

### SSH con Mavericks

Problema:

SSH directo desde la Mac de trabajo hacia la BGH podia fallar con `No route to
host`, aunque la BGH si podia hacer `ping` hacia la Mac de trabajo. Ademas,
Mavericks usa OpenSSH 6.2 y puede fallar contra OpenSSH moderno con `no hostkey
alg`.

Fix:

* Activar Remote Login en Mavericks:
  ```bash
  sudo systemsetup -setremotelogin on
  ```
* Habilitar compatibilidad `ssh-rsa` temporalmente en la Mac de trabajo.
* Autorizar una clave RSA temporal en `~/.ssh/authorized_keys` de la BGH.
* Usar tunel reverso:
  ```bash
  ssh -o StrictHostKeyChecking=no -N -R 2222:localhost:22 USUARIO@IP_MAC_TRABAJO
  ```
* Entrar desde la Mac de trabajo por `127.0.0.1:2222` forzando algoritmos
  compatibles con Mavericks.

Procedimiento completo: [`SSH-MAVERICKS.md`](SSH-MAVERICKS.md).

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

### Ethernet interno sin `en0`

Problema:

El arranque muestra mensajes relacionados con Ethernet, pero al entrar en
Mavericks no existe `en0` y red no aparece en Preferencias del Sistema.

Hallazgo:

El log de OpenCore en la raiz de la EFI muestra:

```text
OC: Prelinked injection RealtekRTL8111.kext ... - Invalid Parameter
```

Esto indica que OpenCore intenta cargar el kext, pero la inyeccion prelinked
falla antes de que Mavericks adjunte el driver al dispositivo `10ec:8168`.

Fix/prueba:

No insistir con la inyeccion de este kext desde OpenCore. Instalarlo dentro del
sistema Mavericks:

```bash
bash /Volumes/Install*/scripts/red.sh
```

Despues de reiniciar:

```bash
bash /Volumes/Install*/scripts/ver.sh
```

Si aparece interfaz pero no IP:

```bash
sudo ipconfig set en0 DHCP
```

Cambiar `en0` por la interfaz real si macOS la enumera como `en1` o `en2`.

### USB Ethernet detectado sin IP

Problema:

El adaptador USB Ethernet puede mostrar una MAC, pero no recibir IP.

Estado actual:

Ya se logro conexion por el adaptador USB Ethernet. Se usa como red provisoria
para activar SSH y continuar configurando Mavericks.

Causas probables:

* El servicio de red no fue creado automaticamente.
* DHCP no asigno direccion.
* El adaptador necesita un driver especifico para Mavericks.

Diagnostico:

```bash
bash /Volumes/Install*/scripts/ver.sh
bash /Volumes/Install*/scripts/diag.sh
```

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
