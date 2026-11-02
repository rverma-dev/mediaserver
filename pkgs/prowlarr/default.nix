{pkgs}: let
  version = "2.7.0.5723";

  source_sets = {
    linux_arm64 = {
      url = "https://github.com/Prowlarr/Prowlarr/releases/download/v${version}/Prowlarr.master.${version}.linux-core-arm64.tar.gz";
      hash = "sha256-vS3MHULz6jeiRyJLtCk+AOvTHnbxKr/KOJxCYPfgpx4=";
    };
    linux_amd64 = {
      url = "https://github.com/Prowlarr/Prowlarr/releases/download/v${version}/Prowlarr.master.${version}.linux-core-x64.tar.gz";
      hash = "sha256-1ly5+0Qqij3tBV1wJ9uaCPUZrLeQjHr+chdap8M3eDw=";
    };
  };
in
  pkgs.stdenv.mkDerivation {
    meta.mainProgram = "Prowlarr";
    pname = "prowlarr";
    inherit version;

    src = pkgs.fetchurl (
      source_sets."linux_${
        if pkgs.stdenv.isAarch64
        then "arm64"
        else "amd64"
      }"
    );

    sourceRoot = "Prowlarr";
    phases = ["unpackPhase" "installPhase"];

    nativeBuildInputs = [pkgs.makeWrapper];
    buildInputs = [pkgs.icu pkgs.zlib pkgs.openssl];

    installPhase = ''
      mkdir -p $out/lib/prowlarr $out/bin
      cp -r . $out/lib/prowlarr/
      makeWrapper $out/lib/prowlarr/Prowlarr $out/bin/prowlarr \
        --prefix LD_LIBRARY_PATH : "${pkgs.lib.makeLibraryPath [pkgs.icu pkgs.zlib pkgs.openssl]}"
    '';
  }
