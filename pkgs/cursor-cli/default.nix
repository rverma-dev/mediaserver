# Fetch pre-built Cursor Agent CLI from official downloads (arm64).
# Update: bump version + hash.  Prefetch via:
#   nix store prefetch-file --json \
#     "https://downloads.cursor.com/lab/<VERSION>/linux/arm64/agent-cli-package.tar.gz"
{
  lib,
  stdenvNoCC,
  fetchurl,
}: let
  version = "2026.03.11-6dfa30c";
  src = fetchurl {
    url = "https://downloads.cursor.com/lab/${version}/linux/arm64/agent-cli-package.tar.gz";
    hash = "sha256-EnDPfMcvRDNvtBzO3HIwaPJ7T7GlNQOdOWkrxrpWKoY=";
  };
in
  stdenvNoCC.mkDerivation {
    pname = "cursor-cli";
    inherit version src;
    sourceRoot = ".";

    dontBuild = true;

    installPhase = ''
      runHook preInstall
      mkdir -p $out/libexec/cursor-cli $out/bin
      cp -r dist-package/* $out/libexec/cursor-cli/
      chmod +x $out/libexec/cursor-cli/cursor-agent
      chmod +x $out/libexec/cursor-cli/node
      ln -s $out/libexec/cursor-cli/cursor-agent $out/bin/agent
      runHook postInstall
    '';

    meta = with lib; {
      description = "Cursor Agent CLI — headless AI coding assistant";
      homepage = "https://cursor.com";
      license = licenses.unfree;
      platforms = ["aarch64-linux"];
      mainProgram = "agent";
    };
  }
