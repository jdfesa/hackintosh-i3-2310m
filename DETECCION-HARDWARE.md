# Deteccion de hardware

Este documento explica como generar y actualizar `hardware-info.txt` desde
Mavericks usando [`detectar-hardware.sh`](detectar-hardware.sh).

## Objetivo

El archivo [`hardware-info.txt`](hardware-info.txt) es una captura del hardware
real visto por macOS. Sirve para decidir que kexts activar, que IDs PCI usar y
que componentes dejar pendientes.

Los datos mas importantes son:

* CPU exacto
* GPU y framebuffer
* Ethernet y PCI ID
* Wi-Fi y PCI ID
* Codec de audio
* USB
* Bateria / EC
* Kexts cargados
* Logs relevantes de kernel

## Como ejecutarlo en Mavericks

1. Arrancar Mavericks con la EFI actual.
2. Abrir Terminal:

   ```text
   Finder > Aplicaciones > Utilidades > Terminal
   ```

3. Verificar que el script exista en el pendrive:

   ```bash
   ls /Volumes/EFI/detectar-hardware.sh
   ```

   Si no existe, montar la EFI en la Mac de trabajo y copiar
   `detectar-hardware.sh` a la raiz del pendrive.

4. Ejecutar el script desde el pendrive:

   ```bash
   bash /Volumes/EFI/detectar-hardware.sh
   ```

5. El script genera este archivo en el Escritorio:

   ```text
   ~/Desktop/hardware-info.txt
   ```

6. Copiar el resultado al pendrive:

   ```bash
   cp ~/Desktop/hardware-info.txt /Volumes/EFI/
   ```

7. Volver a la Mac de trabajo y copiar ese archivo al repo, reemplazando el
   [`hardware-info.txt`](hardware-info.txt) anterior.

## Que devuelve detectar-hardware.sh

El script escribe un reporte unico con estas secciones:

* `CPU`
* `RAM`
* `GPU y PCI`
* `AUDIO CODEC`
* `Kexts de audio cargados`
* `ETHERNET`
* `WIFI`
* `USB`
* `ALMACENAMIENTO`
* `ACPI y nombres de dispositivos`
* `PCI DEVICE IDs`
* `BATERIA`
* `BACKLIGHT / BRILLO`
* `BLUETOOTH`
* `KEXTS CARGADOS EN SISTEMA`
* `LOG DEL KERNEL`
* `IOREG AUDIO COMPLETO`
* `IOREG ETHERNET COMPLETO`

## Si el script no funciona

Ejecutar estos comandos manualmente y guardar la salida en un archivo de texto:

```bash
sysctl -n machdep.cpu.brand_string
system_profiler SPPCIDataType
system_profiler SPAudioDataType
system_profiler SPNetworkDataType
system_profiler SPUSBDataType
system_profiler SPPowerDataType
ioreg -l | grep -i -E "vendor-id|device-id|codec|hda|alc|ethernet|rtl|wifi|battery"
```

## Datos que necesitamos revisar primero

1. Ethernet: modelo y PCI ID.
2. Audio: codec y `layout-id`.
3. GPU: confirmacion de Intel HD 3000 y framebuffer.
4. Entrada: teclado/trackpad PS/2 y tipo de touchpad.
5. Bateria/EC: si macOS ve bateria o requiere parche ACPI.

## Estado del informe actual

El `hardware-info.txt` actual ya confirma:

* CPU: Intel Core i3-2310M
* GPU: Intel HD Graphics 3000
* Ethernet: Realtek `10ec:8168`
* Wi-Fi: Realtek `10ec:8176`
* SMBIOS visible en macOS como `MacBookPro8,1`

Cada vez que se cambie la EFI y el sistema arranque, conviene regenerar el
informe para comparar que kexts cargaron y que dispositivos quedaron visibles.
