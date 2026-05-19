# OpenCore EFI - Positivo BGH A470

EFI para instalar y arrancar **macOS Mavericks 10.9.5** en una notebook
**Positivo BGH A470** con Intel Sandy Bridge y BIOS Legacy.

## Hardware objetivo

* Modelo: Positivo BGH A470
* CPU: Intel Core i3-2310M, Sandy Bridge
* GPU: Intel HD Graphics 3000
* BIOS: Legacy, sin soporte UEFI nativo
* Sistema objetivo: macOS Mavericks 10.9.5

El hardware detallado se recopila con [`detectar-hardware.sh`](detectar-hardware.sh)
y queda guardado en [`hardware-info.txt`](hardware-info.txt). El procedimiento
esta documentado en [`DETECCION-HARDWARE.md`](DETECCION-HARDWARE.md).

## Estado actual

La EFI ya logro arrancar el instalador de Mavericks y completar la instalacion.
Actualmente se esta trabajando en una fase de recuperacion para resolver un
cuelgue al seleccionar el sistema desde el picker.

Configuracion actual de arranque minimo:

* `FakeSMC.kext` activado.
* `VoodooPS2Controller.kext` y plugins PS/2 activados.
* `Lilu.kext`, `AppleALC.kext`, `ECEnabler.kext`, `WhateverGreen.kext`,
  Ethernet, bateria y brillo desactivados temporalmente.

El objetivo de esta fase es confirmar primero un arranque estable. Despues se
reactivan red, audio, graficos, bateria y brillo de a un componente por vez.

## Documentacion

* [`TROUBLESHOOTING.md`](TROUBLESHOOTING.md): historial de errores, sintomas,
  causas probables, fixes aplicados y pruebas pendientes.
* [`POST-INSTALACION.md`](POST-INSTALACION.md): tareas posteriores a la
  instalacion, prioridades y checklist de componentes.
* [`DETECCION-HARDWARE.md`](DETECCION-HARDWARE.md): como ejecutar
  `detectar-hardware.sh`, que datos recopila y como traer `hardware-info.txt`
  de vuelta al repo.

## Valores criticos

No cambiar estos valores mientras se estabiliza el arranque:

* `PlatformInfo -> Generic -> SystemProductName = MacBookPro8,1`
* `PlatformInfo -> UpdateSMBIOSMode = Create`
* `PlatformInfo -> Generic -> SpoofVendor = True`
* `PlatformInfo -> Generic -> AdviseFeatures = False`
* `Kernel -> Quirks -> CustomSMBIOSGuid = False`
* `Kernel -> Emulate -> DummyPowerManagement = True`

Esta combinacion evita que el instalador detecte la identidad real del equipo
como `POSITIVO BGH` y permite que Mavericks acepte la plataforma como
`MacBookPro8,1`.

## Estructura del repo

```text
EFI/
  BOOT/
  OC/
    ACPI/
    Drivers/
    Kexts/
    Resources/
    config.plist
detectar-hardware.sh
hardware-info.txt
DETECCION-HARDWARE.md
POST-INSTALACION.md
TROUBLESHOOTING.md
```

## Arranque Legacy

La notebook no arranca OpenCore en modo UEFI puro. El pendrive o disco interno
debe tener OpenDuet instalado y conservar el archivo raiz `boot`.

Layout esperado en la particion booteable:

```text
/boot
/EFI/BOOT/BOOTx64.efi
/EFI/OC/OpenCore.efi
/EFI/OC/config.plist
```

No confundir `/boot` con `/EFI/BOOT/BOOTx64.efi`: son etapas distintas del
arranque Legacy.

## Flujo de trabajo recomendado

1. Probar la EFI en modo minimo.
2. Si congela, tomar foto de la ultima linea verbose y revisar
   [`TROUBLESHOOTING.md`](TROUBLESHOOTING.md).
3. Si arranca, ejecutar [`detectar-hardware.sh`](detectar-hardware.sh) desde
   Mavericks y traer el nuevo `hardware-info.txt`.
4. Seguir las prioridades de [`POST-INSTALACION.md`](POST-INSTALACION.md).
5. Reactivar kexts uno por uno y documentar cada cambio.

## Preparacion rapida del instalador

1. Crear el instalador con `Install OS X Mavericks.app`:

   ```bash
   sudo /Applications/Install\ OS\ X\ Mavericks.app/Contents/Resources/createinstallmedia --volume /Volumes/MyVolume --applicationpath /Applications/Install\ OS\ X\ Mavericks.app
   ```

2. Instalar OpenDuet/Legacy boot en el pendrive:

   ```bash
   sudo bash OpenCorePkg/Utilities/LegacyBoot/BootInstall_X64.tool /dev/diskX
   ```

3. Montar la particion EFI del pendrive y copiar la carpeta `EFI` del repo.
4. Verificar que el archivo `/boot` siga existiendo en la raiz de la particion.
5. En el instalador de Mavericks, antes de instalar, abrir Terminal y fijar una
   fecha anterior al vencimiento de certificados:

   ```bash
   date 1010101014
   ```

## Politica de cambios

No hacer `push` hasta que la EFI vuelva a estar probada y funcional en el
equipo real.
