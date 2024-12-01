# 3D Printer Configurations

This repository contains my klipper/moonraker configuration, as well as a docker compose setup.

## TODO
- [ ] Telegram-Bot PR: Support for `[include ...]`, to further reduce redundancy
- [ ] Clean up old printer configs
- [ ] Properly adapt the `v0` config
- [ ] Figure out a way to make base config accessible via Mainsail
    - Likely: Moonraker PR

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