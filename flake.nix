#
#  flake.nix *
#   ├─ ./hosts
#   │  └─ ./pi
#   │     └─ default.nix
#   ├─ ./modules
#   │  └─ default.nix
#   └─ ./pkgs
#      └─ <service>/default.nix
#
{
  description = "Pi 5 Media Server — Nix-managed services (binary-only)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-openclaw.url = "github:openclaw/nix-openclaw";
  };

  outputs = {
    self,
    nixpkgs,
    home-manager,
    nix-openclaw,
    ...
  }: let
    vars = {
      user = "pi";
      host = "pi";
      mediaRoot = "/opt/mediaserver";
    };

    supportedSystems = ["aarch64-linux" "x86_64-linux"];

    forAllSystems = nixpkgs.lib.genAttrs supportedSystems;

    mkPkgs = system:
      import nixpkgs {
        inherit system;
        overlays = [nix-openclaw.overlays.default];
      };

    mkMediaPkgs = system: let
      pkgs = mkPkgs system;
    in {
      caddy-duckdns = pkgs.callPackage ./pkgs/caddy-duckdns {};
      sonarr = pkgs.callPackage ./pkgs/sonarr {};
      radarr = pkgs.callPackage ./pkgs/radarr {};
      prowlarr = pkgs.callPackage ./pkgs/prowlarr {};
      bazarr = pkgs.callPackage ./pkgs/bazarr {};
      jellyfin = pkgs.callPackage ./pkgs/jellyfin {};
      seerr = pkgs.callPackage ./pkgs/seerr {};
      openclaw = pkgs.callPackage ./pkgs/openclaw {};
    };
  in {
    packages = forAllSystems (system: mkMediaPkgs system);

    devShells = forAllSystems (system: let
      pkgs = mkPkgs system;
    in {
      default = pkgs.mkShell {
        packages = with pkgs; [nil nixfmt-rfc-style];
      };
    });

    homeConfigurations."pi" = let
      system = "aarch64-linux";
      pkgs = mkPkgs system;
      mediaPkgs = mkMediaPkgs system;
    in
      home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        modules = [
          nix-openclaw.homeManagerModules.openclaw
          ./hosts/pi
        ];
        extraSpecialArgs = {
          inherit nix-openclaw;
          vars = vars // {pkgs = mediaPkgs;};
        };
      };
  };
}
