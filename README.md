# OpenCore EFI - Positivo BGH A470 (Intel i3-2310M)

Este repositorio contiene la configuración de OpenCore y la carpeta `EFI` necesaria para instalar y ejecutar **macOS Mavericks (10.9.5)** en una notebook Positivo BGH A470 (arquitectura Sandy Bridge) usando arranque Legacy.

## 💻 Especificaciones del Hardware

*   **Modelo:** Positivo BGH A470
*   **Procesador:** Intel Core i3-2310M (Sandy Bridge)
*   **Gráficos:** Intel HD Graphics 3000
*   **Tipo de BIOS:** Legacy BIOS (NO soporta UEFI)
*   **Sistema Operativo Objetivo:** macOS Mavericks 10.9.5

## ✅ Estado Actual

La EFI ya logró arrancar el instalador de **macOS Mavericks 10.9.5** en la Positivo BGH A470 y completar la instalación.

La combinación que destrabó el error de producto incompatible fue:

*   `PlatformInfo -> Generic -> SystemProductName = MacBookPro8,1`
*   `PlatformInfo -> UpdateSMBIOSMode = Create`
*   `PlatformInfo -> Generic -> SpoofVendor = True`
*   `PlatformInfo -> Generic -> AdviseFeatures = False`
*   `Kernel -> Quirks -> CustomSMBIOSGuid = False`
*   `Kernel -> Emulate -> DummyPowerManagement = True`

No cambiar estos valores mientras se resuelven los siguientes problemas post-instalación.

La etapa siguiente esta documentada en [`POST-INSTALACION.md`](POST-INSTALACION.md): teclado/trackpad PS/2, red, audio, gráficos, batería y arranque desde disco interno. Para red se agrego `RealtekRTL8100.kext` 2.0.1 como candidato para Ethernet Realtek 10/100 RTL810x.

## ⚠️ Problemas Conocidos y Soluciones Aplicadas

Instalar un sistema moderno como OpenCore en hardware de 2011 para arrancar un sistema operativo de 2013 presenta varios desafíos. Esta EFI ya tiene solucionados los siguientes problemas:

1.  **Arranque Legacy (Blinking Cursor):**
    *   *Problema:* La BIOS de la laptop no soporta UEFI, por lo que ignora la partición EFI por defecto.
    *   *Causa habitual:* si la raíz de la partición booteable quedó solamente con la carpeta `EFI/`, la BIOS no tiene una primera etapa Legacy que cargar y queda en una pantalla negra con cursor titilando.
    *   *Solución:* Se requiere el uso de **OpenDuet**. Es necesario flashear el MBR/PBR del pendrive usando `BootInstall_X64.tool` (incluido en las utilidades de OpenCorePkg) para que la BIOS Legacy pueda leer el archivo raíz `boot` y redirigir a OpenCore.
    *   *Verificación:* la raíz de la partición booteable debe contener algo equivalente a:
        ```text
        /boot
        /EFI/BOOT/BOOTx64.efi
        /EFI/OC/OpenCore.efi
        /EFI/OC/config.plist
        ```
        No confundir `/boot` con `/EFI/BOOT/BOOTx64.efi`: son etapas distintas del arranque Legacy.
2.  **Kernel Panic por SMBIOS Incorrecto:**
    *   *Problema:* Usar modelos modernos como `MacBookPro16,2` causa un cuelgue inmediato.
    *   *Solución:* El SMBIOS está estrictamente configurado como **`MacBookPro8,1`**, el cual corresponde a la generación Sandy Bridge.
3.  **X64 Exception Type - 0E (Page Fault):**
    *   *Problema:* El driver estándar `HfsPlus.efi` causa un *Page Fault* en CPUs antiguos debido a la falta de la instrucción RDRAND. Además, usar alternativas modernas causaba el error `OCB Loading Image failed - Volume Corrupt`.
    *   *Solución:* Se reemplazó por el driver oficial de Apple compilado sin RDRAND: **`HfsPlusLegacy.efi`**. También se habilitó el Quirk **`FixupAppleEfiImages`** para que OpenCore moderno no rechace los permisos del `boot.efi` de Mavericks.
4.  **Incompatibilidad de Kexts con Mavericks:**
    *   *Problema:* varios kexts incluidos fueron compilados para versiones posteriores a macOS Mavericks 10.9.5. En el log aparecían errores como `OC: Prelinked injection AtherosE2200Ethernet.kext - Invalid Parameter`, `RealtekRTL8111.kext - Invalid Parameter` y `USBInjectAll.kext - Invalid Parameter`.
    *   *Causa:* `AtherosE2200Ethernet.kext` declara soporte mínimo para 10.13, `RealtekRTL8111.kext` para 10.14, `USBInjectAll.kext` para 10.11 y `BrightnessKeys.kext` para 10.11. Mavericks no puede inyectarlos correctamente en el prelinkedkernel.
    *   *Solución:* se desactivaron `CryptexFixup.kext`, `AtherosE2200Ethernet.kext`, `RealtekRTL8111.kext`, `USBInjectAll.kext` y `BrightnessKeys.kext` en `Kernel -> Add`.
    *   *Pendiente:* elegir y reemplazar por un kext de red compatible con 10.9 según el chip ethernet real de la notebook. No conviene cargar Atheros, Realtek e Intel al mismo tiempo.
5.  **Firmas Caducadas (DmgLoading):**
    *   *Problema:* El instalador de Mavericks no tiene firmas modernas, por lo que OpenCore puede rechazar su carga.
    *   *Solución:* `Misc -> Security -> DmgLoading` se configuró en `Any`.
6.  **Caché del Kernel Antiguo:**
    *   *Problema:* Mavericks maneja el prelinkedkernel de manera distinta a los macOS modernos.
    *   *Solución:* `Kernel -> Scheme -> FuzzyMatch` se configuró en `True`.
7.  **Teclado Congelado en el Menú de Arranque (Picker):**
    *   *Problema:* Al llegar al menú de OpenCore, el teclado no respondía (congelado). Esto ocurre por un conflicto entre `PollAppleHotKeys` y el manejo de USB en entornos Legacy (DuetPkg).
    *   *Solución:* Se desactivaron `PollAppleHotKeys` y `KeySupport` en el `config.plist`. Además, se agregó manualmente el driver `OpenUsbKbDxe.efi` para forzar el soporte de teclado USB en Legacy BIOS.
8.  **Cuelgue silencioso al seleccionar el instalador:**
    *   *Problema:* Al elegir Mavericks en el menú, el sistema se colgaba tras mostrar un simple "ok". Esto sucedía porque OpenCore intentaba usar instrucciones AVX para acelerar la carga del kernel.
    *   *Solución:* Se configuró `EnableVectorAcceleration` en `False`, ya que el procesador i3-2310M (Sandy Bridge) no soporta instrucciones AVX.
9.  **Error "This version of Mac OS X is not supported on this platform!":**
    *   *Problema:* A pesar de configurar el SMBIOS correcto, el instalador mostraba este error indicando "Reason: POSITIVO BGH". En BIOS Legacy, el modo estándar de inyección de SMBIOS no oculta correctamente el nombre real del hardware.
    *   *Solución:* Se cambió `PlatformInfo -> UpdateSMBIOSMode` de `Custom` a **`Create`**. Esto fuerza a OpenCore a reemplazar completamente las tablas SMBIOS en lugar de parchearlas, engañando exitosamente al instalador.
10. **Parche XCPM no encontrado:**
    *   *Problema:* el log mostraba `OCAK: Failed to apply dbg _xcpm_cst_control_evaluate patches - Not Found`.
    *   *Causa:* `Kernel -> Quirks -> AppleXcpmCfgLock` intenta aplicar un parche de XCPM que no corresponde bien a Sandy Bridge/Mavericks.
    *   *Solución:* se desactivó `AppleXcpmCfgLock`. Se mantuvo `AppleCpuPmCfgLock`, que es el quirk más relevante para el manejo clásico de energía en Mavericks.
11. **Reinicio con BIOS volviendo a valores por defecto:**
    *   *Problema:* después del reinicio, la BIOS perdía la prioridad de arranque del pendrive y volvía a valores por defecto.
    *   *Causa probable:* reset/corrupción de CMOS o NVRAM al trabajar con OpenCore en entorno Legacy/OpenDuet.
    *   *Solución aplicada:* se configuró `NVRAM -> WriteFlash` en `False` y se desactivó `ResetNvramEntry.efi` para evitar escrituras persistentes innecesarias mientras se diagnostica el arranque.
    *   *Pendiente:* si la BIOS sigue reseteándose, el siguiente paso es aplicar un fix RTC/AppleRTC específico.
12. **Producto incompatible / detecta `POSITIVO BGH`:**
    *   *Problema:* El instalador mostraba producto incompatible o `This version of Mac OS X is not supported on this platform`, usando como motivo la identidad real de la notebook (`POSITIVO BGH` o `SMB-CPT1540,0`) en lugar de `MacBookPro8,1`.
    *   *Causa:* El instalador no estaba recibiendo correctamente el SMBIOS inyectado por OpenCore. En Legacy BIOS, `UpdateSMBIOSMode=Overwrite` puede fallar si la tabla OEM no tiene espacio suficiente o está protegida, dejando visible la identidad real del equipo.
    *   *Solución:* Se usa `PlatformInfo -> UpdateSMBIOSMode = Create`, `Kernel -> Quirks -> CustomSMBIOSGuid = False`, `PlatformInfo -> Generic -> SpoofVendor = True` y `PlatformInfo -> Generic -> AdviseFeatures = False`. Con esta combinación el instalador dejó de detectar `POSITIVO BGH`, arrancó correctamente y comenzó la instalación.

## 🔎 Referencias de Hardware Similar

No se encontró una guía pública exacta para la Positivo BGH A470, pero sí varias máquinas muy cercanas con Sandy Bridge, Intel HD 3000 y BIOS/Legacy:

*   **HP 630** con Intel Core i3-2310M.
*   **HP ProBook 4530s** con plataforma Intel 6 Series.
*   **Commodore A24a** con Intel Core i3-2310M.
*   **Dell Latitude E5520** con Intel Core i3-2310M e Intel HD 3000.
*   **Dell Vostro 3450** con Intel Core i3-2310M, chipset HM67 e Intel HD 3000.

Estas referencias confirman que la plataforma es viable para OS X Mavericks/era 10.9-10.10. El punto delicado no es el CPU/GPU, sino el arranque Legacy, USB, DSDT/SSDT y kexts compatibles con versiones antiguas de OS X.

### OpenCore vs Clover en esta plataforma

*   **OpenCore es viable**, pero en BIOS Legacy depende de OpenDuet y del archivo raíz `boot`. Si falta ese archivo o el MBR/PBR no fue escrito correctamente, el síntoma esperado es cursor titilando antes de ver el picker.
*   **Clover Legacy** era la ruta más común para equipos 5/6 Series en la época de Mavericks. Paquetes como `Clover_v2.5k_r5102-Legacy.pkg` instalaban automáticamente los sectores Legacy y agregaban fixes clásicos como `FixHPET`, `FixIPIC`, `FixUSB`, `FixHDA` y `AddDTGP`.
*   Esos fixes de Clover no se copian literalmente a OpenCore. En OpenCore se reemplazan por SSDTs y parches ACPI explícitos. Sirven como pista de qué áreas revisar, especialmente HPET/IPIC/USB/HDA.
*   Si OpenCore no llega siquiera al picker, primero hay que corregir OpenDuet/Legacy boot. Recién después tiene sentido comparar Clover como alternativa.

## 🚀 Guía de Instalación

### 1. Preparar el Instalador de macOS
1.  Consigue la aplicación `Install OS X Mavericks.app` (10.9.5) desde Archive.org, ya que Apple la retiró de sus catálogos.
2.  Formatea un pendrive (Mínimo 8GB) como "Mac OS Extended (Journaled)" con "GUID Partition Map" y nómbralo `MyVolume`.
3.  Ejecuta el comando oficial para crear el medio de instalación:
    ```bash
    sudo /Applications/Install\ OS\ X\ Mavericks.app/Contents/Resources/createinstallmedia --volume /Volumes/MyVolume --applicationpath /Applications/Install\ OS\ X\ Mavericks.app
    ```

### 2. Hacer el Pendrive "Legacy Bootable"
Dado que la Positivo BGH solo usa Legacy BIOS, debes inyectar OpenDuet:
1.  Descarga el código fuente o el release de OpenCorePkg.
2.  Ejecuta el script de instalación Legacy apuntando a tu pendrive (reemplaza `X` por tu número de disco):
    ```bash
    sudo bash OpenCorePkg/Utilities/LegacyBoot/BootInstall_X64.tool /dev/diskX
    ```
3.  Verifica que la raíz de la partición booteable tenga el archivo `boot` además de la carpeta `EFI`. Si borraste `boot` y quedó solo `EFI/`, el pendrive no va a arrancar en Legacy y mostrará únicamente un cursor titilando.

### 3. Copiar esta EFI
1.  Monta la partición oculta `EFI` del pendrive: `sudo diskutil mount /dev/diskXs1`.
2.  Copia la carpeta `EFI` de este repositorio en la raíz de esa partición montada.

### 4. 🛑 Truco de la Fecha (¡CRÍTICO!)
Los certificados de Apple para OS X Mavericks caducaron en octubre de 2019. Si intentas instalarlo directamente, dirá que el instalador está dañado.
1.  Inicia la laptop desde el pendrive y entra al instalador gráfico.
2.  **No te conectes a internet.**
3.  Ve a la barra superior: **Utilidades > Terminal**.
4.  Escribe el siguiente comando para engañar al sistema (Año 2014) y presiona Enter:
    ```bash
    date 1010101014
    ```
5.  Cierra la terminal y procede a instalar macOS normalmente formateando el disco con Utilidad de Discos.
