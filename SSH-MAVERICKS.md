# SSH en Mavericks

Guia para conectarse remotamente a la Positivo BGH A470 con OS X Mavericks
10.9.5. Sirve especialmente cuando el equipo tiene red por adaptador USB
Ethernet pero no permite conexion SSH directa desde la Mac de trabajo.

## Estado confirmado

* Mavericks trae SSH instalado de fabrica.
* Remote Login ya funciona con:
  ```bash
  sudo systemsetup -setremotelogin on
  ```
* En la prueba actual se uso:
  * BGH: `IP_BGH`
  * Mac de trabajo: `IP_MAC_TRABAJO`
  * Usuario: `USUARIO`
  * Red funcional: adaptador USB Ethernet `en0`
  * Puerto Ethernet interno: pendiente

## Camino simple

Primero intentar SSH directo desde la Mac de trabajo:

```bash
ssh USUARIO@IP_BGH
```

Si funciona, no hace falta tunel reverso.

## Verificaciones en Mavericks

En la BGH:

```bash
sudo systemsetup -setremotelogin on
whoami
ifconfig | grep "inet " | grep -v 127
```

Para verificar que la BGH llega a la Mac de trabajo:

```bash
ping -c 2 IP_MAC_TRABAJO
```

Si la BGH llega a la Mac de trabajo, pero la Mac de trabajo no llega a la BGH
con SSH directo, usar tunel reverso.

## Compatibilidad con SSH viejo

Mavericks usa OpenSSH 6.2. Las versiones modernas de macOS pueden rechazar sus
algoritmos antiguos. En la Mac de trabajo se habilito compatibilidad temporal
con `ssh-rsa`:

```bash
sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak-codex
printf '\n# Mavericks compatibility\nHostKeyAlgorithms +ssh-rsa\nPubkeyAcceptedAlgorithms +ssh-rsa\n' | sudo tee -a /etc/ssh/sshd_config
sudo launchctl kickstart -k system/com.openssh.sshd
```

Para revertirlo despues:

```bash
sudo cp /etc/ssh/sshd_config.bak-codex /etc/ssh/sshd_config
sudo launchctl kickstart -k system/com.openssh.sshd
```

Para borrar la clave temporal de la Mac de trabajo:

```bash
rm -rf /private/tmp/bgh-ssh /private/tmp/bgh-share
```

## Autorizar clave temporal

En la Mac de trabajo:

```bash
mkdir -p /private/tmp/bgh-share /private/tmp/bgh-ssh
ssh-keygen -t rsa -b 4096 -f /private/tmp/bgh-ssh/id_rsa -N '' -C codex-bgh-temp
cp /private/tmp/bgh-ssh/id_rsa.pub /private/tmp/bgh-share/id_rsa.pub
tar -czf /private/tmp/bgh-share/scripts.tgz scripts
cd /private/tmp/bgh-share
python3 -m http.server 8765 --bind 0.0.0.0
```

En la BGH:

```bash
mkdir -p ~/.ssh; curl -fsSL http://IP_MAC_TRABAJO:8765/id_rsa.pub >> ~/.ssh/authorized_keys; chmod 700 ~/.ssh; chmod 600 ~/.ssh/authorized_keys
curl -fsSL http://IP_MAC_TRABAJO:8765/scripts.tgz | tar -xz -C /Volumes/Install*/
```

## Tunel reverso

En la BGH, dejar esta terminal abierta:

```bash
ssh -o StrictHostKeyChecking=no -N -R 2222:localhost:22 USUARIO@IP_MAC_TRABAJO
```

Desde la Mac de trabajo, entrar por el tunel:

```bash
ssh -p 2222 -i /private/tmp/bgh-ssh/id_rsa \
  -o KexAlgorithms=diffie-hellman-group14-sha1 \
  -o HostKeyAlgorithms=ssh-rsa \
  -o PubkeyAcceptedAlgorithms=+ssh-rsa \
  -o Ciphers=aes128-ctr \
  -o MACs=hmac-sha1 \
  USUARIO@127.0.0.1
```

El tunel quedo funcionando cuando la BGH mostro el prompt de password de la Mac
de trabajo y, luego de ingresar la clave, la terminal quedo sin volver al
prompt.

## Notas

* Si el comando del tunel queda "colgado", eso es correcto.
* El tunel se pierde si la BGH reinicia; hay que ejecutar de nuevo el comando
  `ssh -N -R ...` desde Mavericks.
* Si aparece `no hostkey alg`, falta habilitar compatibilidad `ssh-rsa` en la
  Mac de trabajo.
* Si SSH directo da `No route to host`, pero la BGH puede hacer `ping` a la Mac
  de trabajo, usar tunel reverso.
