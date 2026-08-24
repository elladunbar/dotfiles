{
  description = "NixOS Config for river-birch";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    copyparty = {
      url = "github:9001/copyparty";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs = { nixpkgs, copyparty, home-manager, sops-nix, ... }:
  let
    system = "x86_64-linux";
  in {
    nixosConfigurations.river-birch = nixpkgs.lib.nixosSystem {
      inherit system;
      modules = [
        ./configuration.nix
        copyparty.nixosModules.default
        ({ ... }: {
            nixpkgs.overlays = [ copyparty.overlays.default ];
        })
        home-manager.nixosModules.home-manager
        {
          home-manager.backupFileExtension = "bak";
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.users.ella = import ./home.nix;
        }
        sops-nix.nixosModules.sops
      ];
    };
  };
}

