# Camera-mock RTSP stream simulator.
# Source is passed from flake.nix (private repo: github:rverma-dev/v1-camera-mock).
{
  pkgs,
  lib,
  src,
}:
let
  pythonEnv = pkgs.python3.withPackages (ps: [ps.pygobject3 ps.pyyaml]);
  gstPkgs = with pkgs.gst_all_1; [
    gstreamer
    gst-plugins-base
    gst-plugins-good
    gst-rtsp-server
  ];
in
pkgs.writeShellApplication {
  name = "camera-mock";
  runtimeInputs = [pythonEnv pkgs.iproute2] ++ gstPkgs;
  text = ''
    export GI_TYPELIB_PATH="${pkgs.lib.makeSearchPath "lib/girepository-1.0" (map (x: x.out) gstPkgs)}"
    export GST_PLUGIN_PATH="${pkgs.lib.makeSearchPath "lib/gstreamer-1.0" (map (x: x.out) gstPkgs)}"
    exec ${pythonEnv}/bin/python3 ${src}/main.py "$@"
  '';
}
