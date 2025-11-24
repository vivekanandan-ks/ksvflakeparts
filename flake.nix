{
  description = "A very basic flake";

  inputs = {
    # Core inputs
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    nixpkgs-unstable.url = "github:nixos/nixpkgs?ref=nixos-unstable";

    flake-parts.url = "github:hercules-ci/flake-parts";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # for vscode extensions
    nix4vscode = {
      url = "github:nix-community/nix4vscode";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # nvf - modern, reproducible, portable, declarative neovim framework
    nvf = {
      url = "github:NotAShelf/nvf";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # https://github.com/gmodena/nix-flatpak
    nix-flatpak.url = "github:gmodena/nix-flatpak/?ref=latest";

    kwin-effects-forceblur = {
      url = "github:taj-ny/kwin-effects-forceblur";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      flake-parts,
      nix4vscode,
      ...
    }@inputs:
    flake-parts.lib.mkFlake { inherit inputs; } (
      { withSystem, ... }:
      {

        imports = [ ];

        systems = [ "x86_64-linux" ];

        # 1. Configure pkgs for all systems (used by devShells, packages, etc.)
        perSystem =
          { config, system, ... }:
          {
            _module.args.pkgs = import inputs.nixpkgs {
              inherit system;
              config.allowUnfree = true;
              config.nvidia.acceptLicense = true;
            };
          };

        # 2. Use withSystem to "unwrap" the configured pkgs and system for the specific host
        flake.nixosConfigurations.nixos = withSystem "x86_64-linux" (
          { system, pkgs, ... }:
          let
            # Define unstable pkgs here so it shares the same system context
            pkgs-unstable = import inputs.nixpkgs-unstable {
              inherit system;
              config.allowUnfree = true;
              config.nvidia.acceptLicense = true;
            };
          in
          inputs.nixpkgs.lib.nixosSystem {
            inherit system;

            modules = [
              ./configuration.nix

              # 3. Pass the 'perSystem' configured pkgs into the NixOS system.
              # This ensures your 'allowUnfree' config applies to the system.
              {
                nixpkgs.pkgs = pkgs;
              }
            ];

            specialArgs = {
              inherit
                inputs
                pkgs-unstable
                nix4vscode
                system
                ;
            };
          }
        );
      }
    );
}
