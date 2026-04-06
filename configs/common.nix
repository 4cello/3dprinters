{ lib, ... }:
let
  flattenRec =
    prefix: attrs:
    lib.foldlAttrs (
      acc: name: value:
      if lib.isAttrs value then
        acc // flattenRec (prefix ++ [ name ]) value
      else
        let
          section = lib.concatStringsSep " " prefix;
        in
        acc
        // {
          "${section}" = (acc."${section}" or { }) // {
            ${name} = value;
          };
        }
    ) { } attrs;

  flatten = attrs: flattenRec [ ] attrs;

  iniList = list: lib.concatStringsSep "\n    " list;
in
{

  services = {
    klipper.settings = flatten {
      virtual_sdcard = {
        path = "/opt/printer_data/gcodes";
        on_error_gcode = "CANCEL_PRINT";
      };

      pause_resume = { };

      display_status = { };

      exclude_object = { };

      gcode_arcs = { };

      force_move = {
        enable_force_move = true;
      };

      respond = { };

      gcode_macro = {
        LOAD_FILAMENT.gcode = ''
          M83                            ; set extruder to relative
          G1 E30 F300                    ; load
          G1 E15 F150                    ; prime nozzle with filament
          M82                            ; set extruder to absolute
        '';

        UNLOAD_FILAMENT.gcode = ''
          M83                            ; set extruder to relative
          G1 E10 F300                    ; extrude a little to soften tip
          G1 E-40 F1800                  ; retract some, but not too much or it will jam
          M82                            ; set extruder to absolute
        '';

        SET_ACTIVE_SPOOL.gcode = ''
          {% if params.ID %}
            {% set id = params.ID|int %}
            {action_call_remote_method(
               "spoolman_set_active_spool",
               spool_id=id
            )}
          {% else %}
            {action_respond_info("Parameter 'ID' is required")}
          {% endif %}
        '';

        CLEAR_ACTIVE_SPOOL.gcode = ''
          {action_call_remote_method(
            "spoolman_set_active_spool",
            spool_id=None
          )}
        '';

        LIGHT_ON.gcode = ''
          {action_call_remote_method("set_device_power", device="light", state="on")}
        '';

        LIGHT_OFF.gcode = ''
          {action_call_remote_method("set_device_power", device="light", state="off")}
        '';

        PRINTER_OFF.gcode = ''
          {action_call_remote_method("set_device_power", device="printer", state="off")}
        '';
      };

      idle_timeout = {
        timeout = 360;
        gcode = ''
          M84
          TURN_OFF_HEATERS
          UPDATE_DELAYED_GCODE ID=delayed_printer_off DURATION=60
        '';
      };

      delayed_gcode.delayed_printer_off = {
        initial_duration = 0;
        gcode = ''
          {% if printer.idle_timeout.state == "Idle" %}
            PRINTER_OFF
            LIGHT_OFF
          {% endif %}
        '';
      };
    };

    moonraker.settings = flatten {
      authorization = {
        trusted_clients = iniList [
          "10.0.0.0/8"
          "100.0.0.0/8"
          "127.0.0.0/8"
          "169.254.0.0/16"
          "172.16.0.0/12"
          "192.168.0.0/16"
          "FE80::/10"
          "::1/128"
        ];
        cors_domains = iniList [
          "*://mainsail.circacerulean.net"
          "*://*.circacerulean.net"
          "*.lan"
          "*.local"
          "*://localhost"
          "*://localhost:*"
        ];
      };

      server = {
        host = "0.0.0.0";
        port = 7125;
        klippy_uds_address = "/opt/printer_data/run/klipper.sock";
      };

      webcam.printercam.service = "mjpegstreamer-adaptive";

      timelapse.output_path = "/opt/printer_data/timelapse";

      # enables partial support of Octoprint API
      octoprint_compat = { };

      spoolman = {
        server = "https://spoolman.circacerulean.net";
        sync_rate = 5;
      };

      history = { };

      file_manager = {
        queue_gcode_uploads = true;
      };

      machine = {
        #provider = none
        #validate_service = False
      };

      job_queue = {
        load_on_startup = true;
      };

      update_manager = {
        enable_system_updates = false;

        # klipper = {
        #   channel = "dev";
        #   refresh_interval = 168;
        # };
        # moonraker = {
        #   channel = "dev";
        #   refresh_interval = 168;
        # };
      };

      power = {
        printer = {
          type = "homeassistant";
          protocol = "https";
          address = "homeassistant.circacerulean.net";
          port = 443;
          token = "{secrets.home_assistant.token}";
          on_when_job_queued = true;
        };

        light = {
          type = "homeassistant";
          protocol = "https";
          address = "homeassistant.circacerulean.net";
          port = 443;
          token = "{secrets.home_assistant.token}";
          domain = "light";
          on_when_job_queued = true;
          off_when_shutdown = true;
          off_when_shutdown_delay = 600;
        };
      };
    };
  };

  telegram.settings = {
    bot = {
      server = "moonraker:7125";
    };

    progress_notification = {
      percent = 5;
      height = 5;
      time = 20;
    };

    timelapse = {
      basedir = "/opt/timelapse";
      cleanup = true;
      height = 0.2;
      time = 5;
      target_fps = 30;
    };
  };
}
