# Arranque desde disco interno

Guia para dejar Mavericks arrancando sin pendrive en la Positivo BGH A470.
Tambien sirve para repetir el proceso si se cambia el HDD por un SSD.

## Estado confirmado

El equipo ya arranca sin depender del pendrive.

Discos vistos durante la configuracion:

```text
/dev/disk0
   0: GUID_partition_scheme    *160.0 GB
   1: EFI EFI                   209.7 MB   disk0s1
   2: Apple_HFS Mavericks       159.2 GB   disk0s2
   3: Apple_Boot Recovery HD    650.0 MB   disk0s3

/dev/disk1
   0: GUID_partition_scheme    *8.1 GB
   1: EFI EFI                   209.7 MB   disk1s1
   2: Apple_HFS Install OS X Mavericks
```

El disco interno era `disk0`; el pendrive era `disk1`.

## Comando usado

Desde Mavericks:

```bash
sudo bash /Volumes/Install*/scripts/efi-interno.sh 0 SI
```

El `0` significa `/dev/disk0`. Si en otra instalacion el disco interno aparece
con otro numero, cambiar ese valor.

## Que hace el script

`scripts/efi-interno.sh`:

* muestra `diskutil list`;
* valida que `disk0s1` sea una particion EFI/FAT32;
* ejecuta OpenDuet Legacy con `BootInstall_X64.tool`;
* monta la EFI interna;
* si ya existe una carpeta `EFI`, la mueve a `EFI.backup.FECHA`;
* copia la EFI funcional desde `scripts/EFI`;
* verifica estos archivos:

```text
/boot
/EFI/BOOT/BOOTx64.efi
/EFI/OC/OpenCore.efi
/EFI/OC/config.plist
```

## Repetirlo al cambiar HDD por SSD

1. Instalar Mavericks en el SSD.
2. Arrancar con el pendrive/instalador.
3. Confirmar discos:
   ```bash
   diskutil list
   ```
4. Identificar el disco interno. Normalmente sera `disk0`.
5. Ejecutar:
   ```bash
   sudo bash /Volumes/Install*/scripts/efi-interno.sh 0 SI
   ```
6. Apagar, retirar pendrive y probar arranque desde el SSD.

## SMBIOS

El repo publico usa valores placeholder para `SystemSerialNumber`, `MLB`,
`SystemUUID` y `ROM`. Antes de copiar la EFI a un disco real, generar valores
propios y mantenerlos fuera de commits publicos.

## Precaucion

No ejecutar el script contra el numero de disco del pendrive. En la instalacion
actual el pendrive era `disk1`, por lo que el comando correcto fue con `0`, no
con `1`.
