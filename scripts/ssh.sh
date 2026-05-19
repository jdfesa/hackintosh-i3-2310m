#!/bin/bash

echo "Activando SSH / Remote Login..."
sudo systemsetup -setremotelogin on
sudo launchctl load -w /System/Library/LaunchDaemons/ssh.plist >/dev/null 2>&1 || true

echo
echo "Usuario:"
whoami

echo
echo "IPs disponibles:"
ifconfig | awk '/inet / && $2 != "127.0.0.1" {print $2}'

echo
echo "Desde otra Mac/Linux, conectar con:"
echo "  ssh $(whoami)@IP"
