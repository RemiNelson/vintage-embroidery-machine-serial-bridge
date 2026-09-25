# janome-serial-bridge

A small helper script that lets old Janome embroidery-machine software
running in a Windows virtual machine talk to a real, physical card
reader/writer plugged into a Mac over USB.

## What this actually is

If you're restoring or still using a **Janome MC5000 / Customizer 2000**
embroidery system, you may know that its "Customizer 2000" software only
runs on old Windows (like Windows 98), and its card reader/writer hardware
only speaks an old-style **serial port** connection — not USB.

The common workaround is to run Windows 98 inside a **virtual machine
(VM)** — a program (in this case [UTM](https://mac.getutm.app/), built on
QEMU) that pretends to be an old PC, running on a modern Mac. That solves
the "old software" problem, but the VM has no way to reach a real,
physical serial device on its own — it only has a *virtual* serial port
inside the simulated PC.

This script is the bridge between those two worlds:

```
Card reader/writer  →  USB-to-serial adapter  →  this script  →  the VM's virtual serial port
   (real hardware)         (plugs into Mac)        (running on Mac)      (inside Windows 98)
```

It does this using a small, well-established Unix tool called `socat`,
which just copies raw data back and forth between two places — in this
case, between the physical USB adapter and a network address the VM is
listening on.

**If you don't have this exact setup — a Janome card reader/writer, a
USB-to-serial adapter, and a Windows VM already configured with a virtual
serial port — this script has nothing to bridge and won't do anything
useful for you as-is.** It's a piece of a specific hobbyist repair/restoration
project, not general-purpose software.

## Important: this only works on a Mac

This script is written specifically for **macOS**. It will not run
as-is on Windows or Linux, because:

- It expects the USB adapter to show up as a device file under `/dev/cu.*`,
  which is how macOS names serial devices. Windows and Linux name serial
  devices differently, so the script would need to be rewritten for either.
- It assumes you're running the Windows 98 environment as a **VM inside
  macOS** (e.g. via UTM), not on a real, separate PC.

If someone gave you this repo and you're on Windows or Linux, this script
is not going to run as given — you'd need someone comfortable with
scripting to rewrite the device-handling part for your operating system.

## What USB hardware this expects

This script does **not** talk to the card reader/writer directly over
USB. It talks to a **USB-to-serial adapter** — specifically, one built
around the **Prolific PL2303G** chipset — that sits in between:

```
[Card reader/writer, plugged into its own cable] → [PL2303G USB-to-serial adapter] → [USB port on your Mac]
```

So: the card reader/writer plugs into the *serial end* of the adapter,
and the *USB end* of the adapter plugs into any regular USB port on your
Mac (using a USB-C or USB-A hub/dongle if your Mac doesn't have the
right port directly).

When plugged in, macOS gives this adapter a device name like:

```
/dev/cu.PL2303G-USBtoUART840
```

**The exact name will likely be slightly different on your Mac** — the
numbers at the end are specific to that individual adapter. Before running
this script, find your adapter's real name by running this in the
Terminal app with the adapter plugged in:

```sh
ls /dev/cu.*
```

Look for an entry that mentions `PL2303`, `usbserial`, or `UART`, and
update the `DEVICE=` line near the top of `janome-serial-bridge.sh` to
match exactly what you see.

## Before you start: things you need already set up

This script is the *last piece* of a larger setup, not a starting point.
Before it will do anything useful, you need:

1. **A Mac**, with the Prolific PL2303G USB-to-serial adapter plugged in
   and its cable connected to the physical Janome card reader/writer.
2. **`socat` installed.** If you have [Homebrew](https://brew.sh/), install
   it with:
   ```sh
   brew install socat
   ```
3. **A Windows 98 virtual machine** (for example, in UTM) already set up
   and configured so its virtual serial port (COM1) is exposed as a TCP
   connection on `127.0.0.1:4555`. This is a one-time setup step in your
   VM software's configuration and is outside the scope of this script —
   see UTM/QEMU's documentation for "serial device" or "chardev" options
   if you need to configure this yourself.
4. The Janome **Customizer 2000** software installed inside that Windows
   98 VM.

If any of those aren't true yet, get those working first — this script
alone won't fix a VM or adapter that isn't already configured correctly.

## How to use it

1. Open the **Terminal** app on your Mac (in Applications → Utilities, or
   search for "Terminal" with Spotlight).
2. Navigate to wherever you saved this script, for example:
   ```sh
   cd ~/bin
   ```
3. Start it in the background with:
   ```sh
   nohup ./janome-serial-bridge.sh > /tmp/janome-serial-bridge.log 2>&1 & disown
   ```
   This tells it to keep running quietly in the background, even after you
   close the Terminal window.
4. Start (or make sure it's already running) your Windows 98 VM and open
   Customizer 2000. It should now be able to see and use the card
   reader/writer.

### Checking whether it's running

```sh
ps aux | grep janome-serial-bridge
```

If you see a line mentioning `janome-serial-bridge.sh` (other than the
`grep` command itself), it's running. If you only see the `grep` line,
it isn't.

It's safe to run the start command again even if you're not sure whether
it's already running — but see the note below about not running it
*twice at the same time*.

### Stopping it

Find its process ID and stop it:

```sh
ps aux | grep janome-serial-bridge
kill <the number in the second column>
```

## You must start this manually, every time

**This does not start itself automatically** — not when your Mac starts
up, and not when you open the VM. It is a plain script, not a background
service. Every time you restart your Mac (and possibly after restarting
the VM), you need to repeat the "How to use it" steps above *before*
opening Customizer 2000, or the software will find a dead, unresponsive
serial port with no obvious explanation why.

**Do not start it twice at the same time.** Two copies running at once
will both try to use the same network address and will conflict with
each other. If you're not sure it's already running, check first (see
above) rather than starting a second copy.

## Troubleshooting

**Customizer 2000 says it can't find the card reader/writer, or it seems
to "hang" when reading/writing a card:**
- This is almost always the bridge script simply not running — check with
  `ps aux | grep janome-serial-bridge` and start it if it isn't there.
  This is the first thing to check before assuming something is broken.

**The script doesn't seem to do anything, or macOS can't find the
device:**
- Make sure the USB-to-serial adapter is actually plugged in, and that
  the `DEVICE=` line in the script matches its real name (see "What USB
  hardware this expects" above — unplug/replug and re-check with
  `ls /dev/cu.*` if you're unsure).
- Make sure `socat` is installed (`brew install socat`).

**"Command not found" when trying to run the script:**
- Make sure the script is marked as runnable: `chmod +x janome-serial-bridge.sh`.

**None of this makes sense / it still doesn't work:**
- This script was written for one specific, unusual restoration project
  and isn't a polished, general-purpose tool. If your hardware or VM
  setup differs at all, it may need to be edited by someone comfortable
  with basic scripting to match your situation.

## Customizing for your own setup

All the settings you're likely to need to change are the three variables
at the top of `janome-serial-bridge.sh`:

```sh
DEVICE=/dev/cu.PL2303G-USBtoUART840   # your USB-to-serial adapter's device name
PORT=4555                              # the TCP port your VM's virtual serial port listens on
BAUD=9600                              # the serial connection speed
```
