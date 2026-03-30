{pkgs}: let
  version = "6.1.1.10360";

  source_sets = {
    linux_arm64 = {
      url = "https://github.com/Radarr/Radarr/releases/download/v${version}/Radarr.master.${version}.linux-core-arm64.tar.gz";
      hash = "sha256-C6MI4XtB0t+c1d07+VFmjfhmgMyWYJGyaGCHUiJFv6w=";
    };
    linux_amd64 = {
      url = "https://github.com/Radarr/Radarr/releases/download/v${version}/Radarr.master.${version}.linux-core-x64.tar.gz";
      hash = "sha256-ORX0+HUgbmUIVpmf40MIxkY2qI3m2vzK3i0XYyZNd90=";
    };
  };
in
  pkgs.stdenv.mkDerivation {
    meta.mainProgram = "Radarr";
    pname = "radarr";
    inherit version;

    src = pkgs.fetchurl (
      source_sets."linux_${
        if pkgs.stdenv.isAarch64
        then "arm64"
        else "amd64"
      }"
    );

    sourceRoot = "Radarr";
    phases = ["unpackPhase" "installPhase"];

    nativeBuildInputs = [pkgs.makeWrapper];
    buildInputs = [pkgs.icu pkgs.zlib pkgs.openssl];

    installPhase = ''
      mkdir -p $out/lib/radarr $out/bin
      cp -r . $out/lib/radarr/
      makeWrapper $out/lib/radarr/Radarr $out/bin/radarr \
        --prefix LD_LIBRARY_PATH : "${pkgs.lib.makeLibraryPath [pkgs.icu pkgs.zlib pkgs.openssl]}"
    '';
  }
