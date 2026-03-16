# Daily activation + weekly GC.
{
  pkgs,
  vars,
  ...
}: let
  inherit (pkgs) lib;
  root = vars.mediaRoot;
  hmBin = "/home/${vars.user}/.local/state/home-manager/profile/bin";
  nixBin = lib.makeBinPath [pkgs.nix pkgs.git pkgs.coreutils pkgs.bash];
  nixPath = "${hmBin}:${nixBin}:/usr/bin:/bin";

  activateScript = pkgs.writeShellScript "nix-activate" ''
    set -euo pipefail
    cd "${root}"
    git pull --ff-only || true
    nix run home-manager -- switch --flake '.#pi' -b backup
  '';

  gcScript = pkgs.writeShellScript "nix-gc" ''
    set -euo pipefail
    nix-collect-garbage --delete-older-than 7d
    nix store optimise
  '';
in {
  systemd.user.services.nix-activate = {
    Unit.Description = "Pull latest lock and activate home-manager config";
    Service = {
      Type = "oneshot";
      Environment = ["PATH=${nixPath}" "MEDIASERVER_ROOT=${root}"];
      ExecStart = "${activateScript}";
    };
  };

  systemd.user.timers.nix-activate = {
    Unit.Description = "Daily home-manager activation";
    Timer = {
      OnCalendar = "daily";
      Persistent = true;
      RandomizedDelaySec = "1h";
    };
    Install.WantedBy = ["timers.target"];
  };

  systemd.user.services.nix-gc = {
    Unit.Description = "Nix garbage collection and store optimisation";
    Service = {
      Type = "oneshot";
      Environment = "PATH=${nixPath}";
      ExecStart = "${gcScript}";
    };
  };

  systemd.user.timers.nix-gc = {
    Unit.Description = "Weekly Nix GC";
    Timer = {
      OnCalendar = "Sun *-*-* 04:00:00";
      Persistent = true;
      RandomizedDelaySec = "30m";
    };
    Install.WantedBy = ["timers.target"];
  };
}
