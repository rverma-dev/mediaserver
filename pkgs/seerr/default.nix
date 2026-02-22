{pkgs}: let
  version = "3.0.1";

  source_sets = {
    linux_arm64 = {
      url = "https://github.com/rverma-dev/mediaserver/releases/download/seerr-v${version}/seerr-linux-arm64.tar.gz";
      hash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
    };
    linux_amd64 = {
      url = "https://github.com/rverma-dev/mediaserver/releases/download/seerr-v${version}/seerr-linux-amd64.tar.gz";
      hash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
    };
  };
in
  pkgs.stdenv.mkDerivation {
    meta.mainProgram = "seerr";
    pname = "seerr";
    inherit version;

    src = pkgs.fetchurl (
      source_sets."linux_${
        if pkgs.stdenv.isAarch64
        then "arm64"
        else "amd64"
      }"
    );

    sourceRoot = "seerr";
    phases = ["unpackPhase" "installPhase"];

    nativeBuildInputs = [pkgs.makeWrapper];

    installPhase = ''
      mkdir -p $out/share/seerr $out/bin
      cp -r . $out/share/seerr/
      makeWrapper ${pkgs.nodejs_22}/bin/node $out/bin/seerr \
        --add-flags "$out/share/seerr/dist/index.js" \
        --chdir "$out/share/seerr" \
        --set NODE_ENV production
    '';
  }
