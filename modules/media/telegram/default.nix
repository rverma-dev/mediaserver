{ pkgs, vars, ... }:
{
  systemd.user.services.telegram-arr-bot = {
    Unit = {
      Description = "Telegram movie requests via Radarr";
      After = [ "network-online.target" "radarr.service" ];
      Wants = [ "network-online.target" ];
      Requires = [ "radarr.service" ];
    };
    Service = {
      ExecStart = "${pkgs.python3}/bin/python ${./bot.py}";
      Restart = "on-failure";
      RestartSec = "15s";
      EnvironmentFile = "${vars.mediaRoot}/.env";
      Environment = [
        "RADARR_URL=http://127.0.0.1:7878"
      ];
    };
    Install.WantedBy = [ "default.target" ];
  };
}
