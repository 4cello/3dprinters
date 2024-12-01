# 3D Printer Configurations

This repository contains my klipper/moonraker configuration, as well as a docker compose setup.

## Docker Compose

TODO

## Secret files
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