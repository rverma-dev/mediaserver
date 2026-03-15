# NVMe exhaustion protection: disk space alert timer
# Alerts when root (NVMe) usage exceeds 85%.

{
  lib,
  pkgs,
  vars,
  ...
}: {
  home.activation.enableNvmeAlertTimer = lib.hm.dag.entryAfter ["writeBoundary"] ''
    systemctl --user enable nvme-disk-alert.timer 2>/dev/null || true
    systemctl --user start nvme-disk-alert.timer 2>/dev/null || true
  '';

  systemd.user.services.nvme-disk-alert = {
    Unit = {
      Description = "NVMe disk space check (alert at 85%)";
    };
    Service = {
      Type = "oneshot";
      ExecStart = "${pkgs.bash}/bin/bash ${vars.mediaRoot}/scripts/monitor-nvme.sh";
    };
    Install.WantedBy = ["default.target"];
  };

  systemd.user.timers.nvme-disk-alert = {
    Unit = {
      Description = "NVMe disk space alert (every 15 min)";
    };
    Timer = {
      OnCalendar = "*:0/15"; # Every 15 minutes
      Persistent = true;
    };
    Install.WantedBy = ["timers.target"];
  };
}
