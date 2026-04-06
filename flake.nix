{
  description = "My NixOS configuration";

  nixConfig = {
    extra-substituters = [ ];
    extra-trusted-public-keys = [ ];
  };

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs";
  };

  outputs =
    {
      self,
      nixpkgs,
      ...
    }@inputs:
    let
      inherit (self) outputs;
    in
    {
      nixosModules = import ./modules;
      homeManagerModules = import ./modules/home;

      overlays = (import ./overlays { inherit inputs outputs; }) // {
        packages = final: prev: import ./pkgs { pkgs = final; };
      };

      nixosConfigurations.test = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          self.nixosModules.printing

          (
            { ... }:
            {
              networking.hostName = "printer-test";
              system.stateVersion = "26.05";
              nix.settings.experimental-features = [
                "nix-command"
                "flakes"
              ];
              users.users.root = {
                initialPassword = "root";
                openssh.authorizedKeys.keys = [
                  (builtins.readFile "/home/jg/.ssh/id_jg.pub")
                ];
              };
              services.getty.autologinUser = "root";
              services.openssh.enable = true;
              i18n = {
                defaultLocale = "en_US.UTF-8";
                extraLocaleSettings = {
                  LC_TIME = "de_DE.UTF-8";
                };
              };
              console.keyMap = "de";

              virtualisation.vmVariant.virtualisation = {
                graphics = false;
                forwardPorts = [
                  {
                    from = "host";
                    host.port = 2222;
                    guest.port = 22;
                  }
                ];
                sharedDirectories = {
                  system-config = {
                    source = "/home/jg/nixos-config/3dprinting";
                    target = "/mnt/system-config";
                  };
                  printer-configs = {
                    source = "/home/jg/nixos-config/3dprinting/configs";
                    target = "/mnt/printer-configs";
                  };
                };
              };

              "3dprinters" = [
                {
                  name = "voronv24";
                  configPath = "/mnt/printer-configs/v24";
                }
                {
                  name = "voronv0";
                  configPath = "/mnt/printer-configs/v0";
                }
              ];
            }
          )
        ];
      };

      apps.x86_64-linux.run-test = {
        type = "app";
        program = "${self.nixosConfigurations.test.config.system.build.vm}/bin/run-printer-test-vm";
      };
    };
}
