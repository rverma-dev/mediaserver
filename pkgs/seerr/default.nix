# Fetch pre-built Seerr from mediaserver releases.
# Built by .github/workflows/build-seerr.yml; trigger via push to this file.
# After build: ./scripts/update-seerr-hashes.sh to populate hashes.
{pkgs, lib}:
let
  version = "3.0.1";
  repo = "rverma-dev/mediaserver";
  tag = "seerr-v${version}";
  baseUrl = "https://github.com/${repo}/releases/download/${tag}";

  source_sets = {
    linux_arm64 = {
      url = "${baseUrl}/seerr-linux-arm64.tar.gz";
      hash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";  # arm64
    };
    linux_amd64 = {
      url = "${baseUrl}/seerr-linux-amd64.tar.gz";
      hash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";  # amd64
    };
  };
in
  pkgs.stdenv.mkDerivation {
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
