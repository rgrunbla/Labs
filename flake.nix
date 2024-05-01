{
  inputs = {
    nixpkgs.url = "nixpkgs/nixos-23.11";
    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, nixos-generators, ... } @ inputs:
    let
      system = "x86_64-linux";
      sourceInfo = inputs.self.sourceInfo;
      genNodeConf = { node }: {
        imports = [
          nixos-generators.nixosModules.all-formats
          {
            nix.settings = {
              experimental-features = [ "nix-command" "flakes" ];
              auto-optimise-store = true;
            };
            nixpkgs.config.allowUnfree = true;
          }
          node.configuration
          {
            networking.hostName = node.vmName;
          }
        ];

        nixpkgs.hostPlatform = system;

        formatConfigs =
          {
            # Quick test on NixOS
            vm = { lib, ... }: {
              virtualisation = {
                memorySize = 4096;
                diskSize = lib.mkForce 1000;
                cores = 4;
              };
            };

            qcow = { lib, modulesPath, config, pkgs, ... }: {
              system.build.qcow = lib.mkForce (import "${toString modulesPath}/../lib/make-disk-image.nix" {
                inherit lib config pkgs;
                name = node.vmName;
                diskSize = "auto";
                format = "qcow2";
                partitionTableType = "hybrid";
              });
            };

            # Ova images
            virtualbox = { config, pkgs, lib, ... }: lib.mkForce {
              virtualbox = {
                memorySize = 4096;
                vmName = node.vmName;
                params = {
                  cpus = 4;
                };
                params = {
                  nic1 = "bridged";
                  nictype1 = "82540EM";
                  nic-property1 = "network=wlo1";
                  nic2 = "bridged";
                  nictype2 = "82540EM";
                  nic-property2 = "network=wlo1";
                };
              };
              virtualisation.virtualbox.guest.enable = true;
            };

          };
      };
    in
    {
      nixosModules = {
        Petit-OS = genNodeConf { node = { vmName = "Petit-OS"; configuration = ./petit-os.nix; }; };
        Architecture-BGP = genNodeConf { node = { vmName = "Architecture-BGP"; configuration = ./tp-bgp/base.nix; }; };
      };

      nixosConfigurations = builtins.mapAttrs (name: module: nixpkgs.lib.nixosSystem { inherit system; modules = [ module ]; }) self.nixosModules;

      packages.${system} = with import nixpkgs { inherit system; };
        builtins.listToAttrs (
          builtins.concatLists (
            lib.mapAttrsToList
              (
                name: system: builtins.map
                  (
                    format: {
                      name = "${name}-${format}";
                      value = system.config.formats."${format}";
                    }
                  ) [ "virtualbox" "vm" "qcow" ]
              )
              self.nixosConfigurations
          )
        );
    };
}
