{pkgs}: let
  version = "4.0.20.3014";

  source_sets = {
    linux_arm64 = {
      url = "https://github.com/Sonarr/Sonarr/releases/download/v${version}/Sonarr.main.${version}.linux-arm64.tar.gz";
      hash = "sha256-vZP38GuMuUDaCBQQbRKT3xK/kZmvBRTpW4k/DGA/x7k=";
    };
    linux_amd64 = {
      url = "https://github.com/Sonarr/Sonarr/releases/download/v${version}/Sonarr.main.${version}.linux-x64.tar.gz";
      hash = "sha256-H8SFRLWjQBsvw9+NBkLB5qc6KOQaNRFp7dnNj1R3DbU=";
    };
  };
in
  pkgs.stdenv.mkDerivation {
    meta.mainProgram = "Sonarr";
    pname = "sonarr";
    inherit version;

    src = pkgs.fetchurl (
      source_sets."linux_${
        if pkgs.stdenv.isAarch64
        then "arm64"
        else "amd64"
      }"
    );

    sourceRoot = "Sonarr";
    phases = ["unpackPhase" "installPhase"];

    nativeBuildInputs = [pkgs.makeWrapper];
    buildInputs = [pkgs.icu pkgs.zlib pkgs.openssl];

    installPhase = ''
      mkdir -p $out/lib/sonarr $out/bin
      cp -r . $out/lib/sonarr/
      makeWrapper $out/lib/sonarr/Sonarr $out/bin/sonarr \
        --prefix LD_LIBRARY_PATH : "${pkgs.lib.makeLibraryPath [pkgs.icu pkgs.zlib pkgs.openssl]}"
    '';
  }
