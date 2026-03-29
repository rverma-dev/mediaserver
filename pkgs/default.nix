# Aggregate all custom packages.
# Called from flake.nix:  import ./pkgs { inherit pkgs; camera-mock-src = ...; }
{
  pkgs,
  camera-mock-src ? null,
}: let
  base = {
    sonarr = pkgs.callPackage ./sonarr {};
    radarr = pkgs.callPackage ./radarr {};
    prowlarr = pkgs.callPackage ./prowlarr {};
    bazarr = pkgs.callPackage ./bazarr {};
    seerr = pkgs.callPackage ./seerr {};
    cursor-cli = pkgs.callPackage ./cursor-cli {};
  };
  optional = pkgs.lib.optionalAttrs (camera-mock-src != null) {
    camera-mock = pkgs.callPackage ./camera-mock {src = camera-mock-src;};
  };
in
  base // optional
