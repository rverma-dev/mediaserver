{pkgs}: let
  version = "1.5.5";
  python = pkgs.python3.withPackages (ps: [
    ps.pillow
    ps.lxml
    ps.numpy
  ]);
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
    buildInputs = [python];

    sourceRoot = ".";
    phases = ["unpackPhase" "installPhase"];

    installPhase = ''
      mkdir -p $out/lib/bazarr $out/bin
      cp -r . $out/lib/bazarr/
      makeWrapper ${python}/bin/python3 $out/bin/bazarr \
        --add-flags "$out/lib/bazarr/bazarr.py"
    '';
  }
