{
  lib,
  config,
  pkgs,
  ...
}:
let
  inherit (lib)
    mkOption
    types
    mkIf
    listToAttrs
    imap0
    ;
  cfg = config."3dprinters";

  moonrakerDefaultPort = 7125;
  ustreamerDefaultPort = 8080;

  mkContainer =
    index: p:
    let
      name = p.name;
      configPath = p.configPath;
      camera = p.cameraDevice;
      moonrakerPort = moonrakerDefaultPort + index;
      ustreamerPort = ustreamerDefaultPort + index;
    in
    {
      inherit name;
      value = {
        autoStart = true;
        forwardPorts = [
          {
            containerPort = moonrakerPort;
            hostPort = moonrakerPort;
          }
          {
            containerPort = ustreamerPort;
            hostPort = ustreamerPort;
          }
        ];

        allowedDevices = lib.optional (camera != null) {
          node = camera;
          modifier = "rw";
        };

        bindMounts = {
          "/config" = {
            hostPath = toString configPath;
            isReadOnly = false;
          };
          # "/dev/serial" = {hostPath = "/dev/serial";};
        }
        // (lib.optionalAttrs (camera != null) {
          "/dev/video0" = {
            hostPath = camera;
            isReadOnly = false;
          };
        });

        config = {
          environment.systemPackages = p.extraPackages;

          services = {
            klipper = {
              enable = true;
              settings = { };
            };
            moonraker = {
              enable = true;
              port = moonrakerPort;
              settings = {
                server = {
                  port = moonrakerPort;
                };
                authorization = {
                  trusted_clients = [
                    "192.168.1.0/24"
                    "127.0.0.1"
                  ];
                };
              };
            };
            ustreamer = lib.mkIf (camera != null) {
              enable = true;
              # device = camera;
              listenAddress = "0.0.0.0:${builtins.toString ustreamerPort}";
            };
          };
          networking.firewall.allowedTCPPorts = [
            moonrakerPort
            ustreamerPort
          ];
        };
      };
    };
in
{
  options."3dprinters" = mkOption {
    type = types.listOf (
      types.submodule {
        options = {
          name = mkOption {
            type = types.str;
            example = "voron2";
          };
          cameraDevice = mkOption {
            type = types.nullOr types.str;
            default = null;
          };
          configPath = mkOption {
            type = types.nullOr (types.path or types.str);
            example = "/srv/printers/voron2";
          };
          extraPackages = mkOption {
            type = types.listOf types.package;
            default = [ ];
            description = "Extra packages to install in the container.";
          };
        };
      }
    );
    default = [ ];
    description = "List of 3D printers to run as Klipper/Moonraker containers.";
  };

  config = mkIf (cfg != [ ]) {
    containers = listToAttrs (imap0 mkContainer cfg);
  };
}
