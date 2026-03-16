# Pre-bundled OpenClaw from npm registry.
# Built by .github/workflows/build-claw.yml; each run creates claw-v{version}.
{
  pkgs,
  lib,
}: let
  version = "2026.3.13";
  repo = "rverma-dev/mediaserver";
  tag = "claw-v${version}";
in
  pkgs.stdenv.mkDerivation {
    pname = "claw";
    inherit version;

    src = pkgs.fetchurl {
      url = "https://github.com/${repo}/releases/download/${tag}/claw-${version}.tar.gz";
      hash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
    };

    sourceRoot = "claw";
    phases = ["unpackPhase" "installPhase"];
    nativeBuildInputs = [pkgs.makeWrapper];

    installPhase = ''
      mkdir -p $out/lib/claw $out/bin
      cp -r . $out/lib/claw/
      makeWrapper ${pkgs.nodejs_22}/bin/node $out/bin/claw \
        --add-flags "$out/lib/claw/node_modules/openclaw/openclaw.mjs"
    '';

    meta = with lib; {
      description = "Claw — multi-channel AI gateway";
      homepage = "https://github.com/openclaw/openclaw";
      license = licenses.mit;
      mainProgram = "claw";
      platforms = platforms.linux;
    };
  }
