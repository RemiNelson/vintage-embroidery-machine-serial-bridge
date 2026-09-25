#!/bin/bash
# Bridges the Windows.utm VM's COM1 (QEMU serial, TCP server on localhost:4555)
# to the Prolific PL2303G USB-serial adapter, for Janome Customizer 2000.
#
# Runs forever: reconnects automatically when the VM reboots or the
# adapter is replugged. Safe to leave running in the background.

DEVICE=/dev/cu.PL2303G-USBtoUART840
PORT=4555
BAUD=9600

while true; do
  if [ -e "$DEVICE" ]; then
    socat "TCP:127.0.0.1:${PORT}" \
      "${DEVICE},raw,echo=0,ispeed=${BAUD},ospeed=${BAUD},cs8,clocal=1,crtscts=0" \
      2>/dev/null
  fi
  sleep 3
done
