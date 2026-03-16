{
  lib,
  pkgs,
  vars,
  ...
}: let
  # HDD paths: downloads + media on same FS for Arr hardlinks
  downloadsComplete = "${vars.hddDownloadsPath}/complete";
  downloadsIncomplete = "${vars.hddDownloadsPath}/incomplete";
  qbittorrentConf = pkgs.writeText "qBittorrent.conf" ''
    [Application]
    FileLogger\Age=1
    FileLogger\AgeType=1
    FileLogger\Backup=true
    FileLogger\DeleteOld=true
    FileLogger\Enabled=true
    FileLogger\MaxSizeBytes=66560
    FileLogger\Path=${vars.mediaRoot}/config/qbittorrent/qBittorrent/data/logs

    [BitTorrent]
    Session\DefaultSavePath=${downloadsComplete}
    Session\ExcludedFileNames=
    Session\Port=13930
    Session\QueueingSystemEnabled=false
    Session\SSL\Port=30544
    Session\TempPath=${downloadsIncomplete}
    Session\TempPathEnabled=true

    [Core]
    AutoDeleteAddedTorrentFile=Never

    [Meta]
    MigrationVersion=8

    [Preferences]
    MailNotification\req_auth=true
    WebUI\AuthSubnetWhitelist=192.168.68.0/22
    WebUI\AuthSubnetWhitelistEnabled=true
    WebUI\LocalHostAuth=false
    WebUI\Password_PBKDF2="@ByteArray(6suSzGBgEhmYf8LRGCiWkw==:FRvAWWJobHQhVA0dt87swHxPkx9ygSdVp60LHFG39N+z2BCXaYKM0a50hr3vxI5/1NC7Y+Yg/GEQcWrguGgB0A==)"

    [RSS]
    AutoDownloader\DownloadRepacks=true
    AutoDownloader\SmartEpisodeFilter=s(\\d+)e(\\d+), (\\d+)x(\\d+), "(\\d{4}[.\\-]\\d{1,2}[.\\-]\\d{1,2})", "(\\d{1,2}[.\\-]\\d{1,2}[.\\-]\\d{4})"
  '';
in {
  home.activation.seedQbittorrentConfig = lib.hm.dag.entryAfter ["writeBoundary"] ''
    config_file="${vars.mediaRoot}/config/qbittorrent/qBittorrent/config/qBittorrent.conf"
    if [[ ! -f "$config_file" ]]; then
      mkdir -p "$(dirname "$config_file")"
      cp ${qbittorrentConf} "$config_file"
      chmod 600 "$config_file"
      echo "Seeded qBittorrent.conf (downloads → ${vars.hddDownloadsPath})"
    fi
  '';

  home.packages = [pkgs.qbittorrent-nox];

  systemd.user.services.qbittorrent = {
    Unit = {
      Description = "qBittorrent-nox torrent client";
      After = ["network-online.target"];
    };
    Service = {
      ExecStart = "${pkgs.qbittorrent-nox}/bin/qbittorrent-nox --webui-port=8080 --profile=${vars.mediaRoot}/config/qbittorrent";
      Restart = "always";
      RestartSec = "5s";
      Environment = ["TZ=${vars.tz}"];
    };
    Install.WantedBy = ["default.target"];
  };
}
