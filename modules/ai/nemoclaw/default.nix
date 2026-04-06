{ config, lib, pkgs, ... }:

{
  systemd.user.services.nemoclaw = {
    Unit = {
      Description = "NemoClaw Services";
      After = [ "network.target" ];
    };

    Service = {
      Type = "oneshot";
      ExecStart = "${pkgs.bash}/bin/bash -c 'export PATH=/home/pi/.nvm/versions/node/v22.22.2/bin:/home/pi/.local/bin:/run/current-system/sw/bin:/usr/local/bin:/usr/bin:/bin:$PATH && /home/pi/.local/bin/nemoclaw start'";
      ExecStop = "${pkgs.bash}/bin/bash -c 'export PATH=/home/pi/.nvm/versions/node/v22.22.2/bin:/home/pi/.local/bin:/run/current-system/sw/bin:/usr/local/bin:/usr/bin:/bin:$PATH && /home/pi/.local/bin/nemoclaw stop'";
      RemainAfterExit = true;
      # Prevent systemd from killing the background processes spawned by nemoclaw start
      KillMode = "none";
    };

    Install = {
      WantedBy = [ "default.target" ];
    };
  };
}
