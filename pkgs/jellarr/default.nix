{ lib
, makeWrapper
, nodejs_24
, stdenvNoCC
, fetchurl
}:
let
  version = "0.1.0";
  src = fetchurl {
    url = "https://github.com/venkyr77/jellarr/releases/download/v${version}/jellarr-v${version}.cjs";
    sha256 = "1n4n87gqlfgcqh6h9vlgnqarvjqdlw1cv2yz586yw291ng8i1lgp";
  };
in
stdenvNoCC.mkDerivation {
  pname = "jellarr";
  inherit version src;

  dontUnpack = true;
  nativeBuildInputs = [ makeWrapper ];
  installPhase = ''
    runHook preInstall
    mkdir -p $out/bin $out/share
    cp $src $out/share/jellarr.cjs
    chmod +x $out/share/jellarr.cjs
    makeWrapper ${nodejs_24}/bin/node $out/bin/jellarr \
      --add-flags "$out/share/jellarr.cjs"
    runHook postInstall
  '';

  meta = with lib; {
    description = "Declarative Jellyfin configuration via AGPL-licensed CLI";
    homepage = "https://github.com/venkyr77/jellarr";
    license = licenses.agpl3Only;
    mainProgram = "jellarr";
    platforms = lib.platforms.linux;
  };
}
