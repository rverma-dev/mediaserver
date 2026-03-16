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
    jellyfin = pkgs.callPackage ./jellyfin {};
    seerr = pkgs.callPackage ./seerr {};
    cursor-cli = pkgs.callPackage ./cursor-cli {};
    claw = pkgs.callPackage ./claw {inherit pkgs;};
    claw-cursor-brain = pkgs.callPackage ./claw-cursor-brain {inherit pkgs;};
  };
  optional = pkgs.lib.optionalAttrs (camera-mock-src != null) {
    camera-mock = pkgs.callPackage ./camera-mock {src = camera-mock-src;};
  };
in
  base // optional
