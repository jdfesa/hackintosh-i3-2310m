#!/bin/bash

echo "Kext Realtek:"
kextstat | grep -i realtek || true

echo
echo "Interfaces:"
ifconfig -a

echo
echo "Servicios de red:"
networksetup -listallhardwareports || true

echo
echo "Detectando hardware nuevo:"
networksetup -detectnewhardware || true
