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

    camera-mock.url = "github:rverma-dev/v1-camera-mock";
  };

  outputs = {
    self,
    nixpkgs,
    home-manager,
    camera-mock,
    ...
  }: let
    vars = {
      user = "pi";
      host = "pi";
      mediaRoot = "/home/pi/mediaserver";
      # HDD: downloads + media + immich originals (same FS for Arr hardlinks)
      hddMountPath = "/mnt/hdd";
      hddDownloadsPath = "/mnt/hdd/downloads";
      hddMediaPath = "/mnt/hdd/media";
      hddImmichLibrary = "/mnt/hdd/immich/library";
      cameraMock = {
        enable = true;
        environmentFile = "/home/pi/mediaserver/.env";
      };
    };

    supportedSystems = ["aarch64-linux" "x86_64-linux"];

    forAllSystems = nixpkgs.lib.genAttrs supportedSystems;

    mkPkgs = system:
      import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };

    mkMediaPkgs = system: let
      pkgs = mkPkgs system;
    in {
      caddy-duckdns = pkgs.callPackage ./pkgs/caddy-duckdns { inherit pkgs; };
      sonarr = pkgs.callPackage ./pkgs/sonarr {};
      radarr = pkgs.callPackage ./pkgs/radarr {};
      prowlarr = pkgs.callPackage ./pkgs/prowlarr {};
      bazarr = pkgs.callPackage ./pkgs/bazarr {};
      jellyfin = pkgs.callPackage ./pkgs/jellyfin {};
      seerr = pkgs.callPackage ./pkgs/seerr {};
      camera-mock = let
        p = mkPkgs system;
        src = camera-mock;
        pythonEnv = p.python3.withPackages (ps: [ ps.pygobject3 ps.pyyaml ]);
        gstPkgs = with p.gst_all_1; [
          gstreamer
          gst-plugins-base
          gst-plugins-good
          gst-rtsp-server
        ];
      in p.writeShellApplication {
        name = "camera-mock";
        runtimeInputs = [ pythonEnv p.iproute2 ] ++ gstPkgs;
        text = ''
          export GI_TYPELIB_PATH="${p.lib.makeSearchPath "lib/girepository-1.0" (map (x: x.out) gstPkgs)}"
          export GST_PLUGIN_PATH="${p.lib.makeSearchPath "lib/gstreamer-1.0" (map (x: x.out) gstPkgs)}"
          exec ${pythonEnv}/bin/python3 ${src}/main.py "$@"
        '';
      };
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
          ./hosts/pi
        ];
        extraSpecialArgs = {
          vars = vars // {pkgs = mediaPkgs;};
        };
      };
  };
}
