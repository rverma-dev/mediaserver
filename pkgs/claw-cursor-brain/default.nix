# Pre-bundled openclaw-cursor-brain from npm registry.
# Built by .github/workflows/build-claw.yml; each run creates claw-cursor-brain-v{version}.
{
  pkgs,
  lib,
}: let
  version = "1.5.4";
  repo = "rverma-dev/mediaserver";
  tag = "claw-cursor-brain-v${version}";
in
  pkgs.stdenv.mkDerivation {
    pname = "claw-cursor-brain";
    inherit version;

    src = pkgs.fetchurl {
      url = "https://github.com/${repo}/releases/download/${tag}/claw-cursor-brain-${version}.tar.gz";
      hash = "sha256-iq8hSfWwlIhJmgHOXrSxNvGZlfJuC+gbHQV2TGB6PiU=";
    };

    sourceRoot = "claw-cursor-brain";
    phases = ["unpackPhase" "installPhase"];

    installPhase = ''
      mkdir -p $out/lib/claw-cursor-brain
      cp -r . $out/lib/claw-cursor-brain/
    '';

    meta = with lib; {
      description = "Claw Cursor Brain — AI rules engine for Cursor via MCP";
      homepage = "https://github.com/andeya/openclaw-cursor-brain";
      license = licenses.mit;
      platforms = platforms.linux;
    };
  }
