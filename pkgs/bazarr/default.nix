{pkgs}: let
  version = "1.5.5";
in
  pkgs.stdenv.mkDerivation {
    meta.mainProgram = "bazarr";
    pname = "bazarr";
    inherit version;

    src = pkgs.fetchurl {
      url = "https://github.com/morpheus65535/bazarr/releases/download/v${version}/bazarr.zip";
      hash = "sha256-VG3YVTnlgzpBVbudQRXwPEaVC4FiMOlHQLLPdDbRc2s=";
    };

    nativeBuildInputs = [pkgs.unzip pkgs.makeWrapper];
    buildInputs = [pkgs.python3];

    sourceRoot = ".";
    phases = ["unpackPhase" "installPhase"];

    installPhase = ''
      mkdir -p $out/lib/bazarr $out/bin
      cp -r . $out/lib/bazarr/
      makeWrapper ${pkgs.python3}/bin/python3 $out/bin/bazarr \
        --add-flags "$out/lib/bazarr/bazarr.py"
    '';
  }
