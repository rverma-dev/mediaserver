{pkgs}: let
  version = "10.11.6";

  source_sets = {
    linux_arm64 = {
      url = "https://repo.jellyfin.org/files/server/linux/latest-stable/arm64/jellyfin_${version}-arm64.tar.gz";
      hash = "sha256-it8VEwqgbVQynJw9eyFzgY4hJIkWaUp7ZXigbT5gu0c=";
    };
    linux_amd64 = {
      url = "https://repo.jellyfin.org/files/server/linux/latest-stable/amd64/jellyfin_${version}-amd64.tar.gz";
      hash = "sha256-Zh8+tYb0t9w6pgaMXy/SXW48s98Vy6ASwF860l9IrYs=";
    };
  };
in
  pkgs.stdenv.mkDerivation {
    meta.mainProgram = "jellyfin";
    pname = "jellyfin";
    inherit version;

    src = pkgs.fetchurl (
      source_sets."linux_${
        if pkgs.stdenv.isAarch64
        then "arm64"
        else "amd64"
      }"
    );

    sourceRoot = "jellyfin";
    phases = ["unpackPhase" "installPhase"];

    nativeBuildInputs = [pkgs.makeWrapper];
    buildInputs = [pkgs.icu pkgs.zlib pkgs.openssl pkgs.fontconfig pkgs.freetype];

    installPhase = ''
      mkdir -p $out/lib/jellyfin $out/bin
      cp -r . $out/lib/jellyfin/
      makeWrapper $out/lib/jellyfin/jellyfin $out/bin/jellyfin \
        --prefix LD_LIBRARY_PATH : "${pkgs.lib.makeLibraryPath [pkgs.icu pkgs.zlib pkgs.openssl pkgs.fontconfig pkgs.freetype]}"
    '';
  }
