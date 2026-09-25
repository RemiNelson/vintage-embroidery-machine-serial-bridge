# janome-serial-bridge

Bridges a Windows VM's virtual COM1 (QEMU serial, exposed as a TCP server on
`localhost:4555`) to a Prolific PL2303G USB-serial adapter on macOS, using
`socat`. Written for running the Janome Customizer 2000 software in a Win98
VM against real serial hardware.

Runs forever in a loop: reconnects automatically when the VM reboots or the
USB adapter is replugged. Safe to leave running in the background.

## Usage

```sh
nohup ./janome-serial-bridge.sh > /tmp/janome-serial-bridge.log 2>&1 & disown
```

Check it's running:

```sh
ps aux | grep janome-serial-bridge
```

Safe to relaunch even if already running (each instance manages its own
`socat` connection attempt).

## Requirements

- `socat`
- A Prolific PL2303G (or compatible) USB-serial adapter
- Edit the `DEVICE`, `PORT`, and `BAUD` variables at the top of the script
  to match your setup.
