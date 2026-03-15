{lib, vars, ...}: let
  root = vars.mediaRoot;
  scriptDir = "/home/${vars.user}/.local/share/nix-maintenance";
  nixPath = "/nix/var/nix/profiles/default/bin:/home/${vars.user}/.nix-profile/bin:/home/${vars.user}/.local/state/home-manager/profile/bin:/usr/bin:/bin";
in {
  systemd.user.services.nix-flake-update = {
    Unit = { Description = "Nix flake update and home-manager switch"; };
    Service = {
      Type = "oneshot";
      Environment = ["PATH=${nixPath}" "MEDIASERVER_ROOT=${root}"];
      WorkingDirectory = root;
      ExecStart = "${scriptDir}/update.sh";
    };
  };
  systemd.user.timers.nix-flake-update = {
    Unit = { Description = "Daily nix flake update"; };
    Timer = {
      OnCalendar = "daily";
      Persistent = true;
      RandomizedDelaySec = "1h";
    };
    Install = { WantedBy = ["timers.target"]; };
  };

  systemd.user.services.nix-gc = {
    Unit = { Description = "Nix garbage collection and store optimisation"; };
    Service = {
      Type = "oneshot";
      Environment = "PATH=${nixPath}";
      ExecStart = "${scriptDir}/gc.sh";
    };
  };
  systemd.user.timers.nix-gc = {
    Unit = { Description = "Weekly Nix GC"; };
    Timer = {
      OnCalendar = "Sun *-*-* 04:00:00";
      Persistent = true;
      RandomizedDelaySec = "30m";
    };
    Install = { WantedBy = ["timers.target"]; };
  };

  home.activation.installNixMaintenanceScripts = lib.hm.dag.entryAfter ["writeBoundary"] ''
    mkdir -p "${scriptDir}"
    install -m755 -D ${./update.sh} "${scriptDir}/update.sh"
    install -m755 -D ${./gc.sh} "${scriptDir}/gc.sh"
  '';
}
