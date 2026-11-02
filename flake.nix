{
  description = "ystack - reproducible UI, Pi, fleet, and agent-skills setup as Home Manager modules";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-26.05-darwin";
    home-manager.url = "github:nix-community/home-manager/release-26.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, home-manager, ... }:
    {
      # Import `default` into a Home Manager configuration and set `ystack.*`.
      homeManagerModules = {
        default = ./modules;
      };

      # Pinned fleet tools built from publisher release checksums (x86_64-linux).
      packages.x86_64-linux = {
        inherit (import ./pkgs/fleet-tools.nix {
          pkgs = nixpkgs.legacyPackages.x86_64-linux;
        })
          herdr treehouse no-mistakes;
        home-manager = home-manager.packages.x86_64-linux.home-manager;
      };
      packages.aarch64-darwin.home-manager = home-manager.packages.aarch64-darwin.home-manager;
    };
}
