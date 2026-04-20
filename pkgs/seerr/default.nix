# Fetch pre-built Seerr from mediaserver releases (arm64 only).
# Built by .github/workflows/build-seerr.yml; each run creates seerr-v3.0.1-N (N = run number).
# After build: ./scripts/update-seerr-hashes.sh 3.0.1-N to update version and hash.
{pkgs, lib}:
let
  version = "3.2.0-16";  # use 3.0.1-N after build (e.g. 3.0.1-11)
  repo = "rverma-dev/mediaserver";
  tag = "seerr-v${version}";
  baseUrl = "https://github.com/${repo}/releases/download/${tag}";

  arm64 = {
    url = "${baseUrl}/seerr-linux-arm64.tar.gz";
    hash = "sha256-gEsI4lQ5lLg1E92NKnY74lW9TeDlvQowHnLAXL1hyv8=";  # arm64
  };
in
  pkgs.stdenv.mkDerivation {
    pname = "seerr";
    inherit version;

    src = pkgs.fetchurl arm64;

    sourceRoot = "seerr";
    phases = ["unpackPhase" "installPhase"];

    nativeBuildInputs = [pkgs.makeWrapper];
    buildInputs = [pkgs.nodejs_22];

    installPhase = ''
      mkdir -p $out/share $out/bin
      cp -r . $out/share/
      makeWrapper ${pkgs.nodejs_22}/bin/node $out/bin/seerr \
        --add-flags "$out/share/dist/index.js" \
        --chdir "$out/share" \
        --set NODE_ENV production
    '';

    meta = {
      description = "Media request manager for Jellyfin, Plex, Emby";
      homepage = "https://github.com/seerr-team/seerr";
      license = lib.licenses.mit;
      mainProgram = "seerr";
      platforms = lib.platforms.linux;
    };
  }
