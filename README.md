# 3D Printer Configurations

This repository contains my klipper/moonraker configuration, as well as a docker compose setup.

## TODO
- [ ] Telegram-Bot PR: Support for `[include ...]`, to further reduce redundancy
- [ ] Clean up old printer configs
- [ ] Properly adapt the `v0` config
- [ ] Figure out a way to make base config accessible via Mainsail
    - Clean: Moonraker PR
    - Dirty: Don't mount into `common`, but into one of the already exposed folders...
- [ ] Fix `udev` rules to restart klipper and moonraker when USB device is detected
- [ ] Check docker images, maybe write my own

## Docker Compose

The file `common-services.yml` contains basic containers for each printer, currently:
- Klipper
- Moonraker (with timelapse plugin)
- Telegram
- µStreamer

Klipper and Moonraker get some general bind mounts, most notably the `common` folder to `/opt/printer_data/common`.

For each printer exists a file `${PRINTER_NAME}.yml`, which extends the services with their specific configuration files, devices and ports.

To interact with the services, either run `docker compose -f ${PRINTER_NAME} up/logs/...`, or set the environment variable `COMPOSE_FILE=${PRINTER_NAME}.yml`.

**Note to future me: Please don't use a `.env` file, it gets synced between RPIs...**

## Secret files not under git
### common/moonraker.secrets
Mounted in `/opt/printer_data/moonraker.secrets`.

Example:
```conf
[mqtt_credentials]
username: # ...
password: # ...

[home_assistant]
token: # ...
```

### ${PRINTER_NAME}/config/telegram.secrets
Mounted in `/opt/printer_data/config/secrets.conf`.

Example:
```conf
[secrets]
chat_id: # ...
bot_token: # ...
```

## udev Rules
I am using the following udev-rules on the RPI which controls 2 printers, to distinguish the boards, but especially the webcams (which are the same model).

```udev
# Webcams
SUBSYSTEM=="video4linux", ATTR{index}=="0", ATTRS{idProduct}=="9331", ATTRS{idVendor}=="05a3", ATTRS{bcdDevice}=="0105", SYMLINK+="videoPrinter0"
SUBSYSTEM=="video4linux", ATTR{index}=="0", ATTRS{idProduct}=="9331", ATTRS{idVendor}=="05a3", ATTRS{bcdDevice}=="0201", SYMLINK+="videoPrinter1"

# Anycubic Linear Plus: Connected as USB device
SUBSYSTEM=="tty", ATTRS{idProduct}=="ea60", ATTRS{idVendor}=="10c4", SYMLINK+="ttyDELTA", RUN+="/bin/sh -c 'cd /home/pi/printer-configs && docker compose -f anycubic-lp.yml restart klipper'"

# Voron V2.4: Connected as CAN-Bus bridge
SUBSYSTEM=="net", ATTRS{serial}=="4A004D000A51313133353932", NAME="can0", RUN+="/bin/sh -c 'cd /home/pi/printer-configs && docker compose -f voron-v24.yml restart klipper'"
```
see:  [udev rules for multiple CANbus interfaces](https://klipper.discourse.group/t/setting-up-udev-rules-for-multiple-canbus-interfaces/16211) (Klipper Forum)