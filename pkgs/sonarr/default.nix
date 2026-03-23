{pkgs}: let
  version = "4.0.17.2952";

  source_sets = {
    linux_arm64 = {
      url = "https://github.com/Sonarr/Sonarr/releases/download/v${version}/Sonarr.main.${version}.linux-arm64.tar.gz";
      hash = "sha256-fIztusYxtSg2ZKdxBXTxJFoNOJaMX++UGNU10qQ33UM=";
    };
    linux_amd64 = {
      url = "https://github.com/Sonarr/Sonarr/releases/download/v${version}/Sonarr.main.${version}.linux-x64.tar.gz";
      hash = "sha256-1RQjcgZ9cnl5QhynsdYGAc7s2XWK86fa+sxuu6gxd3o=";
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
