{
  stdenv,
  lib,
  fetchurl,
}:

let
  version = "2.11.0-beta.2";
  owner = "rverma-dev";
  repo = "mediaserver";
  tag = "caddy-v${version}";

  srcs = {
    "aarch64-linux" = {
      url = "https://github.com/${owner}/${repo}/releases/download/${tag}/caddy-linux-arm64";
      hash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
    };
    "x86_64-linux" = {
      url = "https://github.com/${owner}/${repo}/releases/download/${tag}/caddy-linux-amd64";
      hash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
    };
  };

  platform =
    srcs.${stdenv.hostPlatform.system}
      or (throw "caddy-duckdns: unsupported system ${stdenv.hostPlatform.system}");
in
stdenv.mkDerivation {
  pname = "caddy-duckdns";
  inherit version;

  src = fetchurl { inherit (platform) url hash; };

  dontUnpack = true;
  dontFixup = true;

  installPhase = ''
    runHook preInstall
    install -Dm755 $src $out/bin/caddy
    runHook postInstall
  '';

  meta = {
    description = "Caddy web server with DuckDNS DNS-01 plugin";
    homepage = "https://caddyserver.com";
    license = lib.licenses.asl20;
    platforms = builtins.attrNames srcs;
    mainProgram = "caddy";
  };
}
